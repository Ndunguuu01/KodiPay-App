module.exports = (sequelize, Sequelize) => {
    const Bill = sequelize.define("bills", {
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
        type: {
            type: Sequelize.ENUM('wifi', 'water', 'electricity', 'rent', 'other'),
            allowNull: false
        },
        amount: {
            type: Sequelize.DECIMAL(10, 2),
            allowNull: false
        },
        due_date: {
            type: Sequelize.DATEONLY,
            allowNull: false
        },
        status: {
            type: Sequelize.ENUM('unpaid', 'paid'),
            defaultValue: 'unpaid'
        },
        description: {
            type: Sequelize.STRING
        }
    });

    return Bill;
};
