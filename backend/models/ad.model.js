module.exports = (sequelize, Sequelize) => {
    const Ad = sequelize.define("ad", {
        title: {
            type: Sequelize.STRING
        },
        description: {
            type: Sequelize.TEXT
        },
        contact_info: {
            type: Sequelize.STRING
        },
        image_url: {
            type: Sequelize.TEXT('long') // Using long text for base64 strings
        },
        type: {
            type: Sequelize.ENUM('image', 'video'),
            defaultValue: 'image'
        },
        expires_at: {
            type: Sequelize.DATE
        },
        user_id: {
            type: Sequelize.INTEGER,
            allowNull: false
        }
    });

    return Ad;
};
