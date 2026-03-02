const { authJwt } = require("../middleware");
const { validate, schemas } = require('../middleware/validate');
const controller = require("../controllers/bill.controller");

module.exports = function (app) {
    // Create bill — landlord only + validation
    app.post(
        "/api/bills",
        [authJwt.verifyToken, authJwt.isLandlord, validate(schemas.createBillSchema)],
        controller.create
    );

    // Get bills by tenant — self or landlord (ownership enforced in controller)
    app.get(
        "/api/bills/tenant/:userId",
        [authJwt.verifyToken],
        controller.findAllByTenant
    );

    // Get bills by unit — landlord only
    app.get(
        "/api/bills/unit/:unitId",
        [authJwt.verifyToken, authJwt.isLandlord],
        controller.findAllByUnit
    );

    // Mark bill as paid — LANDLORD ONLY (double-guarded: route + controller)
    app.put(
        "/api/bills/:id/pay",
        [authJwt.verifyToken, authJwt.isLandlord],
        controller.markAsPaid
    );
};
