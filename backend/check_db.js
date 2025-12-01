const db = require("./models");

async function checkData() {
    try {
        await db.sequelize.authenticate();
        console.log("Connection has been established successfully.");

        const userCount = await db.users.count();
        const propertyCount = await db.properties.count();
        const unitCount = await db.units.count();
        const tenantCount = await db.users.count({ where: { role: 'tenant' } });
        const leaseCount = await db.leases.count();

        console.log(`Users: ${userCount}`);
        console.log(`Properties: ${propertyCount}`);
        console.log(`Units: ${unitCount}`);
        console.log(`Tenants: ${tenantCount}`);
        console.log(`Leases: ${leaseCount}`);

    } catch (error) {
        console.error("Unable to connect to the database:", error);
    } finally {
        await db.sequelize.close();
    }
}

checkData();
