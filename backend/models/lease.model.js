module.exports = (sequelize, Sequelize) => {
    const Lease = sequelize.define("leases", {
        id: {
            type: Sequelize.INTEGER,
            primaryKey: true,
            autoIncrement: true
        },
        unit_id: {
            type: Sequelize.INTEGER,
            allowNull: false
        },
        tenant_id: {
            type: Sequelize.INTEGER,
            allowNull: false
        },
        start_date: {
            type: Sequelize.DATEONLY
        },
        end_date: {
            type: Sequelize.DATEONLY
        },
        rent_amount: {
            type: Sequelize.DECIMAL(10, 2),
            allowNull: false
        },
        status: {
            type: Sequelize.ENUM('pending', 'active', 'terminated', 'rejected'),
            defaultValue: 'pending'
        },
        terms: {
            type: Sequelize.TEXT
        }
    });

    return Lease;
};
