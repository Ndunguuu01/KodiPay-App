const db = require("./models");

async function checkTable() {
    console.log("Checking Table Info...");
    try {
        const [results, metadata] = await db.sequelize.query("PRAGMA table_info(leases);");
        console.log("Table Info:", JSON.stringify(results, null, 2));
    } catch (error) {
        console.error("❌ Failed to check table:", error);
    }
}

checkTable();
