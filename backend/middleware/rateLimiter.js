const rateLimit = require('express-rate-limit');

// Auth routes: strict — prevents brute-force on login/register
const authLimiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 10,
    standardHeaders: true,
    legacyHeaders: false,
    message: {
        message: 'Too many authentication attempts. Please try again in 15 minutes.'
    },
    skipSuccessfulRequests: false
});

// Payment routes: moderate — prevents payment spam
const paymentLimiter = rateLimit({
    windowMs: 60 * 1000, // 1 minute
    max: 10,
    standardHeaders: true,
    legacyHeaders: false,
    message: {
        message: 'Too many payment requests. Please slow down.'
    }
});

// General API: permissive — baseline protection
const generalLimiter = rateLimit({
    windowMs: 60 * 1000, // 1 minute
    max: 120,
    standardHeaders: true,
    legacyHeaders: false,
    message: {
        message: 'Too many requests. Please try again later.'
    }
});

module.exports = { authLimiter, paymentLimiter, generalLimiter };
