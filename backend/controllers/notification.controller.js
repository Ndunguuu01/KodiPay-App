const EmailService = require('../services/email.service');
const db = require("../models");
const User = db.users;
const Lease = db.leases;

exports.sendRentReminder = async (req, res) => {
    try {
        const { tenantId } = req.body;

        if (!tenantId) {
            return res.status(400).send({ message: "Tenant ID is required." });
        }

        const user = await User.findByPk(tenantId);
        if (!user) {
            return res.status(404).send({ message: "Tenant not found." });
        }

        if (!user.email) {
            return res.status(400).send({ message: "Tenant does not have an email address." });
        }

        // Find active lease to get rent amount
        const lease = await Lease.findOne({
            where: { tenant_id: tenantId, status: 'active' },
            include: ["unit"]
        });

        if (!lease) {
            return res.status(404).send({ message: "No active lease found for this tenant." });
        }

        // Generate Email Content
        const propertyName = `Unit ${lease.unit.unit_number}`; // Or fetch property name if available
        const subject = `Rent Reminder: ${propertyName}`;
        const dueDate = new Date().toLocaleDateString(); // Placeholder, ideally from lease
        const htmlContent = EmailService.getRentReminderTemplate(
            user.name,
            lease.rent_amount,
            dueDate,
            propertyName
        );

        // Send Email
        const result = await EmailService.sendEmail(user.email, subject, htmlContent);

        if (result.success) {
            res.send({ message: "Rent reminder email sent successfully.", messageId: result.messageId });
        } else {
            res.status(500).send({ message: "Failed to send email.", error: result.error });
        }

    } catch (err) {
        console.error("Notification Error:", err);
        res.status(500).send({ message: err.message || "Error sending reminder." });
    }
};
