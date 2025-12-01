module.exports = (sequelize, Sequelize) => {
    const Property = sequelize.define("properties", {
        id: {
            type: Sequelize.INTEGER,
            primaryKey: true,
            autoIncrement: true
        },
        landlord_id: {
            type: Sequelize.INTEGER,
            allowNull: false
        },
        name: {
            type: Sequelize.STRING,
            allowNull: false
        },
        location: {
            type: Sequelize.STRING
        },
        floors_count: {
            type: Sequelize.INTEGER,
            defaultValue: 1
        }
    });

    return Property;
};
