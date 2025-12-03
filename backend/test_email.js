require('dotenv').config();
const EmailService = require('./services/email.service');

async function testEmail() {
    console.log("Testing Email Service...");
    console.log("SMTP Host:", process.env.SMTP_HOST);
    console.log("SMTP User:", process.env.SMTP_USER);

    const htmlContent = EmailService.getRentReminderTemplate(
        "Brian",
        "15,000",
        "2025-12-05",
        "Sunset Apartments, Unit 101"
    );

    const result = await EmailService.sendEmail(
        "bndungu061@gmail.com", // Send to user provided email
        "Test Rent Reminder",
        htmlContent
    );

    if (result.success) {
        console.log("✅ Email sent successfully! Message ID:", result.messageId);
    } else {
        console.error("❌ Failed to send email:", result.error);
    }
}

testEmail();
