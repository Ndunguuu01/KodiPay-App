require('dotenv').config();
const notificationService = require('./services/notification.service');

const testSMS = async () => {
    const to = process.argv[2]; // Get phone number from command line argument
    if (!to) {
        console.log("Please provide a phone number as an argument. Usage: node test_twilio.js <phone_number>");
        return;
    }

    console.log(`Sending test SMS to ${to}...`);
    const result = await notificationService.sendSMS(to, "This is a test message from KodiPay.");

    if (result.success) {
        console.log("SMS sent successfully! SID:", result.sid);
    } else {
        console.error("Failed to send SMS:", result.error);
    }
};

testSMS();
