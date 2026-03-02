const { verifyToken } = require("../middleware/authJwt");
const { generalLimiter } = require('../middleware/rateLimiter');
const controller = require("../controllers/ai.controller");

module.exports = function (app) {
    // AI chat proxy — authenticated + rate limited
    app.post(
        "/api/ai/chat",
        [verifyToken, generalLimiter],
        controller.chat
    );
};
