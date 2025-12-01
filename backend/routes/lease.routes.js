const { authJwt } = require("../middleware");
const controller = require("../controllers/lease.controller");

module.exports = function (app) {
    app.use(function (req, res, next) {
        res.header(
            "Access-Control-Allow-Headers",
            "x-access-token, Origin, Content-Type, Accept"
        );
        next();
    });

    app.post(
        "/api/leases",
        [authJwt.verifyToken], // Landlord should be authenticated
        controller.create
    );

    app.get(
        "/api/leases/tenant/:userId",
        [authJwt.verifyToken],
        controller.findAllByTenant
    );

    app.post(
        "/api/leases/:id/sign",
        [authJwt.verifyToken],
        controller.sign
    );

    app.get(
        "/api/leases/landlord/:userId",
        [authJwt.verifyToken],
        controller.findAllByLandlord
    );

    app.post(
        "/api/leases/:id/terminate",
        [authJwt.verifyToken],
        controller.terminate
    );
};
