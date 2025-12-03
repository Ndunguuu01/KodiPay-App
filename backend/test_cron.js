require('dotenv').config();
const CronService = require('./services/cron.service');
const db = require("./models");

async function testCron() {
    console.log("Testing Cron Service Logic...");

    // Note: This will only send emails if there are actual leases due in 5 days in the DB.
    // For verification purposes, we might want to mock the date or just check if it runs without error.

    try {
        await CronService.sendRentReminders();
        console.log("✅ Cron logic executed successfully.");
    } catch (error) {
        console.error("❌ Cron logic failed:", error);
    }
}

testCron();
