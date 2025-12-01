module.exports = (sequelize, Sequelize) => {
    const User = sequelize.define("users", {
        id: {
            type: Sequelize.INTEGER,
            primaryKey: true,
            autoIncrement: true
        },
        name: {
            type: Sequelize.STRING,
            allowNull: false
        },
        email: {
            type: Sequelize.STRING,
            allowNull: false,
            unique: true
        },
        password_hash: {
            type: Sequelize.STRING,
            allowNull: false
        },
        role: {
            type: Sequelize.ENUM('landlord', 'tenant', 'admin'),
            defaultValue: 'tenant'
        },
        phone: {
            type: Sequelize.STRING
        },
        profile_pic: {
            type: Sequelize.TEXT('long')
        }
    });

    return User;
};
