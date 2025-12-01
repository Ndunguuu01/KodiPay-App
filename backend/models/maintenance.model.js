module.exports = (sequelize, Sequelize) => {
    const Maintenance = sequelize.define("maintenance", {
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
        issue_type: {
            type: Sequelize.ENUM('plumbing', 'electrical', 'appliance', 'structural', 'other'),
            allowNull: false
        },
        description: {
            type: Sequelize.TEXT,
            allowNull: false
        },
        status: {
            type: Sequelize.ENUM('pending', 'in_progress', 'resolved'),
            defaultValue: 'pending'
        },
        priority: {
            type: Sequelize.ENUM('low', 'medium', 'high', 'emergency'),
            defaultValue: 'medium'
        }
    });

    return Maintenance;
};
