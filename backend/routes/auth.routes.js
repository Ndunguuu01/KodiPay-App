const { authLimiter } = require('../middleware/rateLimiter');
const { validate, schemas } = require('../middleware/validate');

module.exports = app => {
    const auth = require("../controllers/auth.controller.js");
    const router = require("express").Router();

    // Register — with validation + rate limiting
    router.post("/register",
        authLimiter,
        validate(schemas.registerSchema),
        auth.register
    );

    // Login — with validation + strict rate limiting
    router.post("/login",
        authLimiter,
        validate(schemas.loginSchema),
        auth.login
    );

    // Google SSO
    router.post("/google", authLimiter, auth.googleLogin);

    // Forgot password — always returns 200 to prevent email enumeration
    router.post("/forgot-password",
        authLimiter,
        validate(schemas.forgotPasswordSchema),
        auth.forgotPassword
    );

    // Reset password — token + new password
    router.post("/reset-password",
        authLimiter,
        validate(schemas.resetPasswordSchema),
        auth.resetPassword
    );

    app.use('/api/auth', router);
};
