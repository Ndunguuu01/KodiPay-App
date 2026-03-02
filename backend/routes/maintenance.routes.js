const { verifyToken, isLandlord } = require("../middleware/authJwt");
const { validate, schemas } = require('../middleware/validate');
const controller = require("../controllers/maintenance.controller");

module.exports = function (app) {
    // Create maintenance request — any authenticated tenant (ownership enforced in controller)
    app.post(
        "/api/maintenance",
        [verifyToken, validate(schemas.createMaintenanceSchema)],
        controller.create
    );

    // Get all maintenance — landlord sees all (filtered), tenant sees own
    app.get(
        "/api/maintenance",
        [verifyToken],
        controller.findAll // role-scoping inside controller
    );

    // Landlord-specific full list by userId
    app.get(
        "/api/maintenance/landlord/:userId",
        [verifyToken, isLandlord],
        controller.findAllByLandlord
    );

    // Update maintenance status — landlord only + field whitelist in controller
    app.put(
        "/api/maintenance/:id",
        [verifyToken, isLandlord, validate(schemas.updateMaintenanceSchema)],
        controller.update
    );
};
