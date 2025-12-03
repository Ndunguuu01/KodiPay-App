const cron = require('node-cron');
const db = require("../models");
const Lease = db.leases;
const User = db.users;
const Unit = db.units;
const Property = db.properties;
const EmailService = require('./email.service');
const Op = db.Sequelize.Op;

class CronService {
    init() {
        console.log("Initializing Cron Service...");

        // Schedule task to run every day at 9:00 AM
        cron.schedule('0 9 * * *', async () => {
            console.log("Running Daily Rent Reminder Job...");
            await this.sendRentReminders();
        });
    }

    async sendRentReminders() {
        try {
            // Calculate date 5 days from now
            const today = new Date();
            const targetDate = new Date(today);
            targetDate.setDate(today.getDate() + 5);

            // Format to YYYY-MM-DD for database comparison (assuming stored as DATE or similar)
            // Note: Adjust date comparison logic based on your specific DB date format
            const targetDateString = targetDate.toISOString().split('T')[0];

            console.log(`Checking for leases due on: ${targetDateString}`);

            // Find leases due on targetDate
            const leases = await Lease.findAll({
                where: {
                    status: 'active',
                    // Simple comparison - in production might need range check for full day
                    next_due_date: {
                        [Op.eq]: targetDateString
                    }
                },
                include: [
                    {
                        model: User,
                        as: 'tenant',
                        attributes: ['id', 'email', 'name']
                    },
                    {
                        model: Unit,
                        as: 'unit',
                        include: [{
                            model: Property,
                            as: 'property',
                            attributes: ['name']
                        }]
                    }
                ]
            });

            console.log(`Found ${leases.length} leases due for reminder.`);

            for (const lease of leases) {
                const tenant = lease.tenant;
                if (tenant && tenant.email) {
                    const propertyName = lease.unit.property.name;
                    const subject = `Upcoming Rent Reminder: ${propertyName}`;
                    const htmlContent = EmailService.getRentReminderTemplate(
                        tenant.name || tenant.username,
                        lease.rent_amount,
                        lease.next_due_date, // Or format nicely
                        propertyName
                    );

                    await EmailService.sendEmail(tenant.email, subject, htmlContent);
                    console.log(`Reminder sent to ${tenant.email} for Lease ID ${lease.id}`);
                }
            }

        } catch (error) {
            console.error("Error in Cron Job:", error);
        }
    }
}

module.exports = new CronService();
