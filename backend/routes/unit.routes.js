const { verifyToken, isLandlord } = require("../middleware/authJwt");
const controller = require("../controllers/unit.controller");

module.exports = function (app) {
    app.use(function (req, res, next) {
        res.header(
            "Access-Control-Allow-Headers",
            "x-access-token, Origin, Content-Type, Accept"
        );
        next();
    });

    app.post(
        "/api/units",
        [verifyToken, isLandlord],
        controller.create
    );

    app.get(
        "/api/properties/:propertyId/units",
        [verifyToken],
        controller.findAllByProperty
    );

    app.post(
        "/api/units/:id/assign",
        [verifyToken, isLandlord],
        controller.assignTenant
    );

    app.put(
        "/api/units/:id",
        [verifyToken, isLandlord],
        controller.update
    );

    app.delete(
        "/api/units/:id",
        [verifyToken, isLandlord],
        controller.delete
    );
};
