module.exports = (sequelize, Sequelize) => {
    const Payment = sequelize.define("payments", {
        id: {
            type: Sequelize.INTEGER,
            primaryKey: true,
            autoIncrement: true
        },
        tenant_id: {
            type: Sequelize.INTEGER,
            allowNull: false
        },
        unit_id: {
            type: Sequelize.INTEGER,
            allowNull: false
        },
        amount: {
            type: Sequelize.DECIMAL(10, 2),
            allowNull: false
        },
        payment_method: {
            type: Sequelize.ENUM('mpesa', 'bank'),
            defaultValue: 'mpesa'
        },
        status: {
            type: Sequelize.ENUM('pending', 'completed', 'failed'),
            defaultValue: 'pending'
        },
        transaction_code: {
            type: Sequelize.STRING,
            unique: true
        },
        date: {
            type: Sequelize.DATE,
            defaultValue: Sequelize.NOW
        }
    });

    return Payment;
};
