module.exports = (sequelize, Sequelize) => {
    const Message = sequelize.define("messages", {
        id: {
            type: Sequelize.INTEGER,
            primaryKey: true,
            autoIncrement: true
        },
        sender_id: {
            type: Sequelize.INTEGER,
            allowNull: false
        },
        receiver_id: {
            type: Sequelize.INTEGER,
            allowNull: true // Null if group message
        },
        group_id: {
            type: Sequelize.INTEGER,
            allowNull: true // Null if direct message
        },
        content: {
            type: Sequelize.TEXT('long'), // Support base64 images
            allowNull: false
        },
        type: {
            type: Sequelize.STRING,
            defaultValue: 'text' // 'text' or 'image'
        },
        is_read: {
            type: Sequelize.BOOLEAN,
            defaultValue: false
        }
    });

    return Message;
};
