const { verifyToken, isLandlord } = require("../middleware/authJwt");
const controller = require("../controllers/payment.controller");

module.exports = function (app) {
    app.use(function (req, res, next) {
        res.header(
            "Access-Control-Allow-Headers",
            "x-access-token, Origin, Content-Type, Accept"
        );
        next();
    });

    app.post(
        "/api/payments",
        [verifyToken], // Tenant can initiate payment
        controller.create
    );

    app.get(
        "/api/payments",
        [verifyToken], // Landlord/Admin or Tenant viewing own
        controller.findAll
    );
    app.post(
        "/api/payments/callback",
        controller.callback // Public endpoint for M-Pesa
    );

    app.post(
        "/api/payments/create-payment-intent",
        [verifyToken],
        controller.createPaymentIntent
    );

    app.post(
        "/api/payments/confirm-stripe",
        [verifyToken],
        controller.confirmStripePayment
    );
};
