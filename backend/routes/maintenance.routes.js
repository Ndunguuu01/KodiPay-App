const { verifyToken, isLandlord } = require("../middleware/authJwt");
const controller = require("../controllers/maintenance.controller");

module.exports = function (app) {
    app.use(function (req, res, next) {
        res.header(
            "Access-Control-Allow-Headers",
            "x-access-token, Origin, Content-Type, Accept"
        );
        next();
    });

    app.post(
        "/api/maintenance",
        [verifyToken], // Tenant creates request
        controller.create
    );

    app.get(
        "/api/maintenance",
        [verifyToken], // Landlord views all, Tenant views own
        controller.findAll
    );

    app.get(
        "/api/maintenance/landlord/:userId",
        [verifyToken, isLandlord],
        controller.findAllByLandlord
    );

    app.put(
        "/api/maintenance/:id",
        [verifyToken, isLandlord], // Only Landlord can update status
        controller.update
    );
};
