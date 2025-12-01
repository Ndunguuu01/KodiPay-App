const db = require("../models");
const Payment = db.payments;
const Unit = db.units;
const Op = db.Sequelize.Op;

const MpesaService = require('../services/mpesa.service');

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
        // Initiate M-Pesa STK Push
        const mpesaResponse = await MpesaService.stkPush(phone, amount, accountRef, transactionDesc);

        // Save initial payment record as 'pending'
        const payment = {
            tenant_id: req.body.tenant_id,
            unit_id: req.body.unit_id,
            amount: amount,
            payment_method: 'mpesa',
            status: 'pending',
            transaction_code: mpesaResponse.CheckoutRequestID // Use CheckoutRequestID as temp ref
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
