const db = require("../models");
const Payment = db.payments;
const Unit = db.units;
const Op = db.Sequelize.Op;

const MpesaService = require('../services/mpesa.service');
const FraudService = require('../services/fraud.service');
const stripe = require("stripe")(process.env.STRIPE_SECRET_KEY);

// Create Stripe Payment Intent
exports.createPaymentIntent = async (req, res) => {
    try {
        const { amount, currency } = req.body;

        const paymentIntent = await stripe.paymentIntents.create({
            amount: Math.round(amount * 100), // Convert to cents
            currency: currency || 'usd',
            automatic_payment_methods: {
                enabled: true,
            },
        });

        res.send({
            clientSecret: paymentIntent.client_secret,
        });
    } catch (error) {
        console.error("Stripe Error:", error);
        res.status(500).send({ error: error.message });
    }
};

// Confirm Stripe Payment and Save to DB
exports.confirmStripePayment = async (req, res) => {
    try {
        const { paymentIntentId, amount, tenant_id, unit_id } = req.body;

        // Verify payment intent status with Stripe (Optional but recommended)
        const paymentIntent = await stripe.paymentIntents.retrieve(paymentIntentId);

        if (paymentIntent.status === 'succeeded') {
            // Fraud Check
            const fraudAnalysis = await FraudService.analyze({
                tenantId: tenant_id,
                amount: amount,
                unitId: unit_id
            });

            if (fraudAnalysis.status === 'rejected') {
                // In a real scenario, we might refund the payment here
                return res.status(400).send({ message: "Payment rejected due to high fraud risk.", flags: fraudAnalysis.flags });
            }

            // Create Payment Record
            const payment = {
                tenant_id: tenant_id,
                unit_id: unit_id,
                amount: amount,
                payment_method: 'stripe',
                status: 'completed',
                transaction_code: paymentIntentId,
                fraud_status: fraudAnalysis.status,
                fraud_flags: fraudAnalysis.flags
            };

            const data = await Payment.create(payment);
            res.send({ message: "Payment recorded successfully", data: data });
        } else {
            res.status(400).send({ message: "Payment not successful" });
        }
    } catch (error) {
        console.error("Stripe Confirmation Error:", error);
        res.status(500).send({ error: error.message });
    }
};

// Create a new Payment (Initiate M-Pesa STK Push)
exports.create = async (req, res) => {
    // Validate request
    if (!req.body.tenant_id || !req.body.unit_id || !req.body.amount || !req.body.phone) {
        res.status(400).send({
            message: "Content can not be empty! Phone number is required for M-Pesa."
        });
        return;
    }

    const amount = req.body.amount;
    const phone = req.body.phone;
    const accountRef = `Unit ${req.body.unit_id}`;
    const transactionDesc = `Rent Payment for Unit ${req.body.unit_id}`;

    try {
        // Fraud Check
        const fraudAnalysis = await FraudService.analyze({
            tenantId: req.body.tenant_id,
            amount: amount,
            unitId: req.body.unit_id
        });

        if (fraudAnalysis.status === 'rejected') {
            return res.status(400).send({ message: "Payment rejected due to high fraud risk.", flags: fraudAnalysis.flags });
        }

        // Initiate M-Pesa STK Push
        const mpesaResponse = await MpesaService.stkPush(phone, amount, accountRef, transactionDesc);

        // Save initial payment record as 'pending'
        const payment = {
            tenant_id: req.body.tenant_id,
            unit_id: req.body.unit_id,
            amount: amount,
            payment_method: 'mpesa',
            status: 'pending',
            transaction_code: mpesaResponse.CheckoutRequestID, // Use CheckoutRequestID as temp ref
            fraud_status: fraudAnalysis.status,
            fraud_flags: fraudAnalysis.flags
        };

        const data = await Payment.create(payment);
        res.send({
            message: "M-Pesa STK Push initiated. Please check your phone.",
            data: data,
            mpesaResponse: mpesaResponse
        });

    } catch (err) {
        console.error("Payment Creation Error:", err);
        res.status(500).send({
            message: err.message || "Some error occurred while initiating payment."
        });
    }
};

// Handle M-Pesa Callback
exports.callback = async (req, res) => {
    try {
        console.log("M-Pesa Callback Received:", JSON.stringify(req.body, null, 2));
        const { Body } = req.body;
        const { stkCallback } = Body;

        if (stkCallback.ResultCode === 0) {
            // Success
            const checkoutRequestID = stkCallback.CheckoutRequestID;
            const metadata = stkCallback.CallbackMetadata.Item;

            // Extract M-Pesa Receipt Number
            const mpesaReceipt = metadata.find(item => item.Name === 'MpesaReceiptNumber').Value;

            // Update Payment Record
            await Payment.update(
                {
                    status: 'completed',
                    transaction_code: mpesaReceipt
                },
                { where: { transaction_code: checkoutRequestID } }
            );

            console.log(`Payment ${checkoutRequestID} completed successfully. Receipt: ${mpesaReceipt}`);
        } else {
            // Failed or Cancelled
            const checkoutRequestID = stkCallback.CheckoutRequestID;
            await Payment.update(
                { status: 'failed' },
                { where: { transaction_code: checkoutRequestID } }
            );
            console.log(`Payment ${checkoutRequestID} failed. Reason: ${stkCallback.ResultDesc}`);
        }

        res.json({ result: "success" });
    } catch (error) {
        console.error("M-Pesa Callback Error:", error);
        res.status(500).json({ result: "error" });
    }
};

// Retrieve all Payments (for Admin/Landlord) or for specific Tenant
exports.findAll = (req, res) => {
    const tenant_id = req.query.tenant_id;
    var condition = tenant_id ? { tenant_id: { [Op.eq]: tenant_id } } : null;

    Payment.findAll({ where: condition })
        .then(data => {
            res.send(data);
        })
        .catch(err => {
            res.status(500).send({
                message:
                    err.message || "Some error occurred while retrieving payments."
            });
        });
};
