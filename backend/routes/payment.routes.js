const { verifyToken, isLandlord } = require("../middleware/authJwt");
const { paymentLimiter } = require('../middleware/rateLimiter');
const { validate, schemas } = require('../middleware/validate');
const controller = require("../controllers/payment.controller");

module.exports = function (app) {
    // ── Stripe Webhook — MUST use raw body (mounted in server.js before json()) ──
    app.post(
        "/api/webhooks/stripe",
        controller.stripeWebhook  // No auth — Stripe signs the payload
    );

    // ── M-Pesa Callback — public but IP-checked inside controller ──────────────
    app.post(
        "/api/payments/callback",
        controller.callback
    );

    // ── Authenticated Payment Endpoints ────────────────────────────────────────
    app.post(
        "/api/payments/create-payment-intent",
        [verifyToken, paymentLimiter, validate(schemas.createPaymentIntentSchema)],
        controller.createPaymentIntent
    );

    app.post(
        "/api/payments",
        [verifyToken, paymentLimiter, validate(schemas.createMpesaPaymentSchema)],
        controller.create
    );

    app.get(
        "/api/payments",
        [verifyToken],
        controller.findAll  // Scoped by role inside controller
    );
};
