const { verifyToken, isLandlord } = require("../middleware/authJwt");
const controller = require("../controllers/user.controller");

module.exports = function (app) {
    app.use(function (req, res, next) {
        res.header(
            "Access-Control-Allow-Headers",
            "x-access-token, Origin, Content-Type, Accept"
        );
        next();
    });

    app.get(
        "/api/users/tenants",
        [verifyToken, isLandlord],
        controller.findAllTenants
    );

    app.get(
        "/api/users/:id",
        [verifyToken],
        controller.findOne
    );

    app.put(
        "/api/users/profile",
        [verifyToken],
        controller.updateProfile
    );

    app.put(
        "/api/users/password",
        [verifyToken],
        controller.changePassword
    );
};
