

const dbConfig = require("../config/db.config.js");

const Sequelize = require("sequelize");

let sequelize;
if (process.env.DATABASE_URL) {
    sequelize = new Sequelize(process.env.DATABASE_URL, {
        dialect: 'postgres',
        protocol: 'postgres',
        dialectOptions: {
            ssl: {
                require: true,
                rejectUnauthorized: false
            }
        }
    });
} else {
    sequelize = new Sequelize(dbConfig.DB, dbConfig.USER, dbConfig.PASSWORD, {
        host: dbConfig.HOST,
        dialect: dbConfig.dialect,
        storage: dbConfig.storage,
        pool: {
            max: dbConfig.pool.max,
            min: dbConfig.pool.min,
            acquire: dbConfig.pool.acquire,
            idle: dbConfig.pool.idle
        },
        dialectOptions: dbConfig.dialectOptions
    });
}

const db = {};

db.Sequelize = Sequelize;
db.sequelize = sequelize;

db.users = require("./user.model.js")(sequelize, Sequelize);
db.properties = require("./property.model.js")(sequelize, Sequelize);
db.units = require("./unit.model.js")(sequelize, Sequelize);
db.payments = require("./payment.model.js")(sequelize, Sequelize);
db.messages = require("./message.model.js")(sequelize, Sequelize);

// Associations
db.users.hasMany(db.properties, { foreignKey: "landlord_id", as: "properties" });
db.properties.belongsTo(db.users, { foreignKey: "landlord_id", as: "landlord" });

db.properties.hasMany(db.units, { foreignKey: "property_id", as: "units" });
db.units.belongsTo(db.properties, { foreignKey: "property_id", as: "property" });

db.users.hasMany(db.units, { foreignKey: "tenant_id", as: "rented_units" });
db.units.belongsTo(db.users, { foreignKey: "tenant_id", as: "tenant" });

db.units.hasMany(db.payments, { foreignKey: "unit_id", as: "payments" });
db.payments.belongsTo(db.units, { foreignKey: "unit_id", as: "unit" });

db.users.hasMany(db.payments, { foreignKey: "tenant_id", as: "made_payments" });
db.payments.belongsTo(db.users, { foreignKey: "tenant_id", as: "payer" });

db.leases = require("./lease.model.js")(sequelize, Sequelize);

// Lease Associations
db.units.hasMany(db.leases, { foreignKey: "unit_id", as: "leases" });
db.leases.belongsTo(db.units, { foreignKey: "unit_id", as: "unit" });

db.users.hasMany(db.leases, { foreignKey: "tenant_id", as: "leases" });
db.leases.belongsTo(db.users, { foreignKey: "tenant_id", as: "tenant" });

db.bills = require("./bill.model.js")(sequelize, Sequelize);
db.maintenance = require("./maintenance.model.js")(sequelize, Sequelize);

// Bill Associations
db.units.hasMany(db.bills, { foreignKey: "unit_id", as: "bills" });
db.bills.belongsTo(db.units, { foreignKey: "unit_id", as: "unit" });

db.users.hasMany(db.bills, { foreignKey: "tenant_id", as: "bills" });
db.bills.belongsTo(db.users, { foreignKey: "tenant_id", as: "tenant" });

// Maintenance Associations
db.units.hasMany(db.maintenance, { as: "maintenance", foreignKey: "unit_id" });
db.maintenance.belongsTo(db.units, { foreignKey: "unit_id", as: "unit" });

db.users.hasMany(db.maintenance, { as: "maintenance", foreignKey: "tenant_id" });
db.maintenance.belongsTo(db.users, { foreignKey: "tenant_id", as: "tenant" });

// Message Associations
db.users.hasMany(db.messages, { foreignKey: "sender_id", as: "sent_messages" });
db.messages.belongsTo(db.users, { foreignKey: "sender_id", as: "sender" });
db.users.hasMany(db.messages, { foreignKey: "receiver_id", as: "received_messages" });
db.messages.belongsTo(db.users, { foreignKey: "receiver_id", as: "receiver" });

db.ads = require("./ad.model.js")(sequelize, Sequelize);

module.exports = db;
