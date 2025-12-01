const db = require("../models");
const Maintenance = db.maintenance;
const User = db.users;
const Unit = db.units;
const Op = db.Sequelize.Op;

// Create a new Maintenance Request
exports.create = (req, res) => {
    if (!req.body.unit_id || !req.body.tenant_id || !req.body.issue_type || !req.body.description) {
        res.status(400).send({
            message: "Content can not be empty!"
        });
        return;
    }

    const maintenance = {
        unit_id: req.body.unit_id,
        tenant_id: req.body.tenant_id,
        issue_type: req.body.issue_type,
        description: req.body.description,
        priority: req.body.priority || 'medium',
        status: 'pending'
    };

    Maintenance.create(maintenance)
        .then(data => {
            res.send(data);
        })
        .catch(err => {
            res.status(500).send({
                message: err.message || "Some error occurred while creating the Maintenance Request."
            });
        });
};

// Retrieve all Maintenance Requests (for Landlord) or for specific Tenant
exports.findAll = (req, res) => {
    const tenant_id = req.query.tenant_id;
    const unit_id = req.query.unit_id;

    let condition = {};
    if (tenant_id) condition.tenant_id = tenant_id;
    if (unit_id) condition.unit_id = unit_id;

    Maintenance.findAll({
        where: condition,
        include: [
            { model: User, as: 'tenant', attributes: ['name', 'phone'] },
            { model: Unit, as: 'unit', attributes: ['unit_number'] }
        ],
        order: [['createdAt', 'DESC']]
    })
        .then(data => {
            res.send(data);
        })
        .catch(err => {
            res.status(500).send({
                message: err.message || "Some error occurred while retrieving maintenance requests."
            });
        });
};

exports.findAllByLandlord = async (req, res) => {
    const landlordId = req.params.userId;

    try {
        // Find all properties owned by landlord
        const properties = await db.properties.findAll({
            where: { landlord_id: landlordId },
            attributes: ['id']
        });

        const propertyIds = properties.map(p => p.id);

        if (propertyIds.length === 0) {
            return res.send([]);
        }

        // Find all units in these properties
        const units = await Unit.findAll({
            where: { property_id: { [Op.in]: propertyIds } },
            attributes: ['id']
        });

        const unitIds = units.map(u => u.id);

        if (unitIds.length === 0) {
            return res.send([]);
        }

        // Find all maintenance requests for these units
        const requests = await Maintenance.findAll({
            where: { unit_id: { [Op.in]: unitIds } },
            include: [
                { model: User, as: 'tenant', attributes: ['name', 'phone'] },
                { model: Unit, as: 'unit', attributes: ['unit_number'] }
            ],
            order: [['createdAt', 'DESC']]
        });

        res.send(requests);
    } catch (err) {
        res.status(500).send({
            message: err.message || "Some error occurred while retrieving maintenance requests."
        });
    }
};

// Update Maintenance Status (for Landlord)
exports.update = (req, res) => {
    const id = req.params.id;

    Maintenance.update(req.body, {
        where: { id: id }
    })
        .then(num => {
            if (num == 1) {
                // Emit socket event
                Maintenance.findByPk(id).then(data => {
                    const io = req.app.get('socketio');
                    io.to(`user_${data.tenant_id}`).emit('maintenance_update', data);
                });

                res.send({
                    message: "Maintenance Request was updated successfully."
                });
            } else {
                res.send({
                    message: `Cannot update Maintenance Request with id=${id}. Maybe Request was not found or req.body is empty!`
                });
            }
        })
        .catch(err => {
            res.status(500).send({
                message: "Error updating Maintenance Request with id=" + id
            });
        });
};
