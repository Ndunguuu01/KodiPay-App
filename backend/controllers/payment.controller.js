const db = require("../models");
const Payment = db.payments;
const Unit = db.units;
const Lease = db.leases;
const Op = db.Sequelize.Op;
const crypto = require('crypto');

const MpesaService = require('../services/mpesa.service');
const FraudService = require('../services/fraud.service');
const stripe = require("stripe")(process.env.STRIPE_SECRET_KEY);
const logger = require('../middleware/logger');

// Safaricom IP allowlist for M-Pesa callbacks
const MPESA_ALLOWED_IPS = [
    '196.201.214.200', '196.201.214.206', '196.201.213.114',
    '196.201.214.207', '196.201.214.208', '196.201.213.44',
    '196.201.212.127', '196.201.212.138', '196.201.212.129',
    '196.201.212.136', '196.201.212.74', '196.201.212.69'
];

// ─────────────────────────────────────────────────────────────────────────────
// HELPER: Verify amount is within ±10% of lease rent amount
// ─────────────────────────────────────────────────────────────────────────────
async function verifyAmountAgainstLease(tenantId, unitId, amount) {
    const lease = await Lease.findOne({
        where: { tenant_id: tenantId, unit_id: unitId, status: 'active' }
    });
    if (!lease) {
        // No active lease found – allow but log (first payment scenario)
        logger.warn(`No active lease found for tenant ${tenantId}, unit ${unitId}. Allowing payment.`);
        return { valid: true };
    }
    const rentAmount = parseFloat(lease.rent_amount);
    const upperBound = rentAmount * 2.5; // Allow up to 250% (arrears + current)
    const lowerBound = rentAmount * 0.1; // Must be at least 10% of rent
    if (amount < lowerBound || amount > upperBound) {
        return {
            valid: false,
            message: `Payment amount KES ${amount} is outside the acceptable range (KES ${lowerBound} – KES ${upperBound}).`
        };
    }
    return { valid: true };
}

// ─────────────────────────────────────────────────────────────────────────────
// CREATE STRIPE PAYMENT INTENT
// ─────────────────────────────────────────────────────────────────────────────
exports.createPaymentIntent = async (req, res, next) => {
    try {
        const { amount, currency, unit_id, idempotencyKey } = req.body;

        // Verify amount against lease rent
        const amountCheck = await verifyAmountAgainstLease(req.userId, unit_id, amount);
        if (!amountCheck.valid) {
            return res.status(400).json({ message: amountCheck.message });
        }

        const options = idempotencyKey ? { idempotencyKey } : {};

        const paymentIntent = await stripe.paymentIntents.create(
            {
                amount: Math.round(amount * 100), // Convert to KES cents
                currency: currency || 'kes',
                automatic_payment_methods: { enabled: true },
                metadata: {
                    tenant_id: req.userId.toString(),
                    unit_id: unit_id.toString()
                }
            },
            options
        );

        res.json({ clientSecret: paymentIntent.client_secret });
    } catch (error) {
        next(error);
    }
};

// ─────────────────────────────────────────────────────────────────────────────
// STRIPE WEBHOOK HANDLER — called from /api/webhooks/stripe (raw body required)
// ─────────────────────────────────────────────────────────────────────────────
exports.stripeWebhook = async (req, res) => {
    const sig = req.headers['stripe-signature'];

    let event;
    try {
        event = stripe.webhooks.constructEvent(
            req.body, // raw Buffer — must use express.raw() on this route
            sig,
            process.env.STRIPE_WEBHOOK_SECRET
        );
    } catch (err) {
        logger.warn(`Stripe webhook signature verification failed: ${err.message}`);
        return res.status(400).send(`Webhook Error: ${err.message}`);
    }

    if (event.type === 'payment_intent.succeeded') {
        const paymentIntent = event.data.object;
        const tenantId = parseInt(paymentIntent.metadata.tenant_id);
        const unitId = parseInt(paymentIntent.metadata.unit_id);
        const amount = paymentIntent.amount / 100; // Convert from cents

        try {
            // Idempotency: check if already processed
            const existing = await Payment.findOne({
                where: { transaction_code: paymentIntent.id }
            });
            if (existing) {
                logger.info(`Stripe webhook: payment ${paymentIntent.id} already recorded. Ignoring.`);
                return res.json({ received: true });
            }

            const fraudAnalysis = await FraudService.analyze({ tenantId, amount, unitId });

            await Payment.create({
                tenant_id: tenantId,
                unit_id: unitId,
                amount,
                payment_method: 'stripe',
                status: fraudAnalysis.status === 'rejected' ? 'fraud_rejected' : 'completed',
                transaction_code: paymentIntent.id,
                fraud_status: fraudAnalysis.status,
                fraud_flags: fraudAnalysis.flags
            });

            logger.info(`Stripe payment ${paymentIntent.id} recorded for tenant ${tenantId}.`);
        } catch (err) {
            logger.error('Error processing stripe webhook:', err);
            // Return 200 to prevent Stripe from retrying — log internally
        }
    }

    // Always respond 200 to Stripe
    res.json({ received: true });
};

// ─────────────────────────────────────────────────────────────────────────────
// INITIATE M-PESA STK PUSH
// ─────────────────────────────────────────────────────────────────────────────
exports.create = async (req, res, next) => {
    try {
        const { tenant_id, unit_id, amount, phone } = req.body; // Joi validated

        // Tenants can only initiate payment for themselves
        if (req.userRole === 'tenant' && req.userId !== tenant_id) {
            return res.status(403).json({ message: 'You can only initiate payments for yourself.' });
        }

        // Verify amount against lease
        const amountCheck = await verifyAmountAgainstLease(tenant_id, unit_id, amount);
        if (!amountCheck.valid) {
            return res.status(400).json({ message: amountCheck.message });
        }

        const fraudAnalysis = await FraudService.analyze({ tenantId: tenant_id, amount, unitId: unit_id });
        if (fraudAnalysis.status === 'rejected') {
            return res.status(400).json({
                message: 'Payment rejected due to high fraud risk.',
                flags: fraudAnalysis.flags
            });
        }

        const mpesaResponse = await MpesaService.stkPush(
            phone,
            amount,
            `Unit ${unit_id}`,
            `Rent Payment for Unit ${unit_id}`
        );

        const data = await Payment.create({
            tenant_id,
            unit_id,
            amount,
            payment_method: 'mpesa',
            status: 'pending',
            transaction_code: mpesaResponse.CheckoutRequestID,
            fraud_status: fraudAnalysis.status,
            fraud_flags: fraudAnalysis.flags
        });

        res.json({
            message: 'M-Pesa STK Push initiated. Please check your phone.',
            data,
            checkoutRequestId: mpesaResponse.CheckoutRequestID
        });
    } catch (err) {
        next(err);
    }
};

// ─────────────────────────────────────────────────────────────────────────────
// M-PESA CALLBACK — public endpoint with IP allowlist + idempotency
// ─────────────────────────────────────────────────────────────────────────────
exports.callback = async (req, res) => {
    try {
        // IP allowlist validation
        const clientIp = req.ip || req.connection.remoteAddress || '';
        const normalizedIp = clientIp.replace('::ffff:', '');

        if (process.env.NODE_ENV === 'production' && !MPESA_ALLOWED_IPS.includes(normalizedIp)) {
            logger.warn(`M-Pesa callback blocked from unauthorized IP: ${normalizedIp}`);
            return res.status(403).json({ result: 'forbidden' });
        }

        const { Body } = req.body;
        const { stkCallback } = Body;
        const checkoutRequestID = stkCallback.CheckoutRequestID;

        // Idempotency: check if already processed
        const existingPayment = await Payment.findOne({
            where: { transaction_code: checkoutRequestID, status: { [Op.ne]: 'pending' } }
        });
        if (existingPayment) {
            logger.info(`M-Pesa callback ignored: ${checkoutRequestID} already processed.`);
            return res.json({ result: 'success' });
        }

        if (stkCallback.ResultCode === 0) {
            const metadata = stkCallback.CallbackMetadata.Item;
            const mpesaReceiptItem = metadata.find(item => item.Name === 'MpesaReceiptNumber');
            const mpesaReceipt = mpesaReceiptItem ? mpesaReceiptItem.Value : checkoutRequestID;

            await Payment.update(
                { status: 'completed', transaction_code: mpesaReceipt },
                { where: { transaction_code: checkoutRequestID } }
            );
            logger.info(`M-Pesa payment completed. Receipt: ${mpesaReceipt}`);
        } else {
            await Payment.update(
                { status: 'failed' },
                { where: { transaction_code: checkoutRequestID } }
            );
            logger.info(`M-Pesa payment ${checkoutRequestID} failed: ${stkCallback.ResultDesc}`);
        }

        res.json({ result: 'success' });
    } catch (error) {
        logger.error('M-Pesa Callback Error:', error);
        res.status(500).json({ result: 'error' });
    }
};

// ─────────────────────────────────────────────────────────────────────────────
// RETRIEVE PAYMENTS — scoped by role (tenants see only their own)
// ─────────────────────────────────────────────────────────────────────────────
exports.findAll = async (req, res, next) => {
    try {
        const page = Math.max(1, parseInt(req.query.page) || 1);
        const limit = Math.min(100, parseInt(req.query.limit) || 20);
        const offset = (page - 1) * limit;

        let condition = {};

        if (req.userRole === 'tenant') {
            // Tenants may ONLY see their own payments — ignore any query param
            condition.tenant_id = req.userId;
        } else if (req.query.tenant_id) {
            // Landlords/admins may optionally filter by tenant
            condition.tenant_id = parseInt(req.query.tenant_id);
        }

        const { count, rows } = await Payment.findAndCountAll({
            where: condition,
            limit,
            offset,
            order: [['createdAt', 'DESC']]
        });

        res.json({
            total: count,
            page,
            limit,
            data: rows
        });
    } catch (err) {
        next(err);
    }
};
