const express = require("express");
const cors = require("cors");
const dotenv = require("dotenv");
const http = require('http');
const { Server } = require("socket.io");

dotenv.config();

const app = express();

var corsOptions = {
    origin: "*" // Allow all origins for production
};

app.use(cors(corsOptions));

// parse requests of content-type - application/json
app.use(express.json({ limit: '50mb' }));

// parse requests of content-type - application/x-www-form-urlencoded
app.use(express.urlencoded({ extended: true, limit: '50mb' }));

const db = require("./models");
db.sequelize.sync(); // Normal sync
// In development, you might want to drop and re-sync:
// db.sequelize.sync({ alter: true }).then(() => {
//     console.log("Synced db with alter: true.");
// });

// simple route
app.get("/", (req, res) => {
    res.json({ message: "Welcome to KodiPay Backend Application." });
});

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

// Initialize Cron Service
const CronService = require('./services/cron.service');
CronService.init();

const server = http.createServer(app);
const io = new Server(server, {
    cors: {
        origin: "*",
        methods: ["GET", "POST"]
    }
});

// Make io accessible to our router
app.set('socketio', io);

io.on('connection', (socket) => {
    console.log('A user connected: ' + socket.id);

    socket.on('join_room', (room) => {
        socket.join(room);
        console.log(`User ${socket.id} joined room: ${room}`);
    });

    socket.on('typing', (data) => {
        // data: { room: '...', user: 'Name' }
        socket.to(data.room).emit('typing', data);
    });

    socket.on('stop_typing', (data) => {
        socket.to(data.room).emit('stop_typing', data);
    });

    socket.on('disconnect', () => {
        console.log('User disconnected');
    });
});

// set port, listen for requests
const PORT = process.env.PORT || 8080;
server.listen(PORT, () => {
    console.log(`Server is running on port ${PORT}.`);
});
