module.exports = (sequelize, Sequelize) => {
    const Unit = sequelize.define("units", {
        id: {
            type: Sequelize.INTEGER,
            primaryKey: true,
            autoIncrement: true
        },
        property_id: {
            type: Sequelize.INTEGER,
            allowNull: false
        },
        unit_number: {
            type: Sequelize.STRING,
            allowNull: false
        },
        floor_number: {
            type: Sequelize.INTEGER,
            allowNull: false
        },
        room_number: {
            type: Sequelize.STRING,
            allowNull: false
        },
        tenant_id: {
            type: Sequelize.INTEGER,
            allowNull: true // Can be vacant
        },
        rent_amount: {
            type: Sequelize.DECIMAL(10, 2),
            allowNull: false
        },
        status: {
            type: Sequelize.STRING,
            defaultValue: "vacant"
        }
    });

    return Unit;
};
