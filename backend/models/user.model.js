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
            unique: true,
            validate: { isEmail: true }
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
            type: Sequelize.STRING,
            allowNull: true
        },
        profile_pic: {
            type: Sequelize.TEXT('long'),
            allowNull: true
        },
        // Password reset fields
        password_reset_token: {
            type: Sequelize.STRING,
            allowNull: true,
            defaultValue: null
        },
        password_reset_expires: {
            type: Sequelize.DATE,
            allowNull: true,
            defaultValue: null
        },
        // Flags invited accounts that must change password on first login
        must_reset_password: {
            type: Sequelize.BOOLEAN,
            defaultValue: false
        }
    });

    return User;
};
