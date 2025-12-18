require('dotenv').config();
const db = require("./models");
const Unit = db.units;
const User = db.users;

async function debugUnit() {
    try {
        const units = await Unit.findAll({
            include: [{
                model: User,
                as: "tenant",
                required: false
            }]
        });

        console.log("Total Units Found:", units.length);
        units.forEach(u => {
            console.log(`ID: ${u.id}, Unit: ${u.unit_number}, Status: ${u.status}, TenantID: ${u.tenant_id}, PropID: ${u.property_id}, Tenant: ${u.tenant ? u.tenant.name : 'NULL'}`);
        });

    } catch (error) {
        console.error("Error:", error);
    }
}

debugUnit();
