const db = require("./models");

async function addColumn() {
    console.log("Adding column manually...");
    try {
        await db.sequelize.query("ALTER TABLE leases ADD COLUMN next_due_date DATE;");
        console.log("✅ Column added successfully.");
    } catch (error) {
        if (error.message.includes("duplicate column name")) {
            console.log("⚠️ Column already exists.");
        } else {
            console.error("❌ Failed to add column:", error);
        }
    }
}

addColumn();
