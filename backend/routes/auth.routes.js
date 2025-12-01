module.exports = app => {
    const auth = require("../controllers/auth.controller.js");

    var router = require("express").Router();

    // Create a new User
    router.post("/register", auth.register);

    // Login
    router.post("/login", auth.login);

    // Google Login
    router.post("/google", auth.googleLogin);

    app.use('/api/auth', router);
};
