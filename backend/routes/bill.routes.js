const { authJwt } = require("../middleware");
const controller = require("../controllers/bill.controller");

module.exports = function (app) {
    app.use(function (req, res, next) {
        res.header(
            "Access-Control-Allow-Headers",
            "x-access-token, Origin, Content-Type, Accept"
        );
        next();
    });

    app.post(
        "/api/bills",
        [authJwt.verifyToken, authJwt.isLandlord],
        controller.create
    );

    app.get(
        "/api/bills/tenant/:userId",
        [authJwt.verifyToken],
        controller.findAllByTenant
    );

    app.get(
        "/api/bills/unit/:unitId",
        [authJwt.verifyToken],
        controller.findAllByUnit
    );

    app.put(
        "/api/bills/:id/pay",
        [authJwt.verifyToken],
        controller.markAsPaid
    );
};
