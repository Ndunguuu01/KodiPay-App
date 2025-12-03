const db = require("./models");

async function syncDb() {
    console.log("Syncing Database...");
    try {
        await db.sequelize.sync({ alter: true });
        console.log("✅ Database synced successfully.");
    } catch (error) {
        console.error("❌ Database sync failed:", error);
    }
}

syncDb();
