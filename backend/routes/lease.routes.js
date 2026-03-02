const { authJwt } = require("../middleware");
const { validate, schemas } = require('../middleware/validate');
const controller = require("../controllers/lease.controller");

module.exports = function (app) {
    // Create lease — landlord only
    app.post(
        "/api/leases",
        [authJwt.verifyToken, authJwt.isLandlord, validate(schemas.createLeaseSchema)],
        controller.create
    );

    // Get tenant's leases — self or landlord
    app.get(
        "/api/leases/tenant/:userId",
        [authJwt.verifyToken],
        controller.findAllByTenant  // ownership enforced inside controller
    );

    // Sign a lease — verified tenant
    app.post(
        "/api/leases/:id/sign",
        [authJwt.verifyToken],
        controller.sign // ownership enforced inside controller
    );

    // Landlord views all leases for their properties
    app.get(
        "/api/leases/landlord/:userId",
        [authJwt.verifyToken, authJwt.isLandlord],
        controller.findAllByLandlord
    );

    // Terminate lease — landlord only
    app.post(
        "/api/leases/:id/terminate",
        [authJwt.verifyToken, authJwt.isLandlord],
        controller.terminate
    );
};
