module.exports = app => {
    const notifications = require("../controllers/notification.controller.js");
    const { authJwt } = require("../middleware");

    var router = require("express").Router();

    // Send rent reminder
    // Protected by JWT, maybe admin/landlord only? For now, allowing authenticated users.
    router.post("/remind-rent", [authJwt.verifyToken], notifications.sendRentReminder);

    app.use('/api/notifications', router);
};
