const { verifyToken } = require("../middleware/authJwt");
const controller = require("../controllers/message.controller");

module.exports = function (app) {
    app.use(function (req, res, next) {
        res.header(
            "Access-Control-Allow-Headers",
            "x-access-token, Origin, Content-Type, Accept"
        );
        next();
    });

    app.post(
        "/api/messages",
        [verifyToken],
        controller.create
    );

    app.get(
        "/api/messages",
        [verifyToken],
        controller.findAll
    );
};
