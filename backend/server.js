const express = require("express");
const cors = require("cors");
const dotenv = require("dotenv");
const http = require('http');
const { Server } = require("socket.io");
const helmet = require("helmet");

dotenv.config();

// ── Validate required environment variables at startup ────────────────────────
const REQUIRED_ENV = ['JWT_SECRET', 'STRIPE_SECRET_KEY', 'MPESA_CONSUMER_KEY'];
REQUIRED_ENV.forEach(key => {
    if (!process.env[key]) {
        console.error(`FATAL: Missing required environment variable: ${key}`);
        process.exit(1);
    }
});
if (process.env.JWT_SECRET && process.env.JWT_SECRET.length < 32) {
    console.error('FATAL: JWT_SECRET is too short. Use at least 32 characters.');
    process.exit(1);
}

const app = express();
const logger = require('./middleware/logger');
const { errorHandler } = require('./middleware/errorHandler');
const { generalLimiter } = require('./middleware/rateLimiter');

// ── Security Headers (OWASP) ─────────────────────────────────────────────────
app.use(helmet({
    contentSecurityPolicy: false, // Disable for API — enable on web app
    crossOriginEmbedderPolicy: false
}));

// ── CORS — explicit allowlist, no wildcard in production ─────────────────────
const allowedOrigins = process.env.ALLOWED_ORIGINS
    ? process.env.ALLOWED_ORIGINS.split(',').map(o => o.trim())
    : ['http://localhost:3000', 'http://localhost:8080'];

const corsOptions = {
    origin: (origin, callback) => {
        // Allow requests with no origin (mobile apps, curl, Postman)
        if (!origin || allowedOrigins.includes(origin)) {
            return callback(null, true);
        }
        callback(new Error(`CORS policy: origin ${origin} is not allowed.`));
    },
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'x-access-token', 'Authorization'],
    credentials: true
};
app.use(cors(corsOptions));
app.options('*', cors(corsOptions));

// ── Body Parsers — lower limit for security ───────────────────────────────────
// NOTE: Stripe webhooks need raw body — mounted before json() via raw route
app.use('/api/webhooks/stripe', express.raw({ type: 'application/json' }));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// ── Request Logger ─────────────────────────────────────────────────────────────
app.use(logger.requestMiddleware);

// ── Global rate limiter ────────────────────────────────────────────────────────
app.use('/api/', generalLimiter);

// ── Database ────────────────────────────────────────────────────────────────────
const db = require("./models");
// NEVER use { alter: true } or { force: true } in production
db.sequelize.sync({ force: false }).then(() => {
    logger.info("Database synced.");
}).catch(err => {
    logger.error("Database sync failed:", err);
    process.exit(1);
});

// ── Health check ─────────────────────────────────────────────────────────────
app.get("/", (req, res) => {
    res.json({ message: "KodiPay Backend — OK", timestamp: new Date().toISOString() });
});

// ── Routes ────────────────────────────────────────────────────────────────────
require("./routes/auth.routes")(app);
require("./routes/property.routes")(app);
require("./routes/payment.routes")(app);
require("./routes/message.routes")(app);
require("./routes/unit.routes")(app);
require("./routes/user.routes")(app);
require("./routes/lease.routes")(app);
require("./routes/bill.routes")(app);
require("./routes/maintenance.routes")(app);
require("./routes/dashboard.routes")(app);
require("./routes/ad.routes")(app);
require("./routes/notification.routes")(app);
require("./routes/ai.routes")(app);

// ── Centralized Error Handler (must be LAST) ──────────────────────────────────
app.use(errorHandler);

// ── Cron Service ──────────────────────────────────────────────────────────────
const CronService = require('./services/cron.service');
CronService.init();

// ── Socket.io — authenticated connections ────────────────────────────────────
const server = http.createServer(app);
const io = new Server(server, {
    cors: {
        origin: allowedOrigins,
        methods: ["GET", "POST"]
    }
});

// Socket authentication middleware
const jwt = require('jsonwebtoken');
io.use((socket, next) => {
    const token = socket.handshake.auth?.token;
    if (!token) {
        return next(new Error('Socket authentication required.'));
    }
    jwt.verify(token, process.env.JWT_SECRET, (err, decoded) => {
        if (err) return next(new Error('Invalid socket token.'));
        socket.userId = decoded.id;
        socket.userRole = decoded.role;
        next();
    });
});

app.set('socketio', io);

io.on('connection', (socket) => {
    logger.info(`Socket connected: user ${socket.userId}`);

    // Auto-join personal room for targeted notifications
    socket.join(`user_${socket.userId}`);

    socket.on('join_room', (room) => {
        // Validate room format to prevent room-hopping (e.g. only numeric IDs or "user_X" rooms)
        if (typeof room === 'string' && /^[a-zA-Z0-9_-]{1,64}$/.test(room)) {
            socket.join(room);
        }
    });

    socket.on('typing', (data) => {
        socket.to(data.room).emit('typing', data);
    });

    socket.on('stop_typing', (data) => {
        socket.to(data.room).emit('stop_typing', data);
    });

    socket.on('disconnect', () => {
        logger.info(`Socket disconnected: user ${socket.userId}`);
    });
});

// ── Start Server ─────────────────────────────────────────────────────────────
const PORT = process.env.PORT || 8080;
server.listen(PORT, () => {
    logger.info(`KodiPay backend running on port ${PORT} [${process.env.NODE_ENV || 'development'}]`);
});
