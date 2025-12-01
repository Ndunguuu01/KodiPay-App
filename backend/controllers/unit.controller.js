const db = require("../models");
const Unit = db.units;
const Property = db.properties;

exports.create = (req, res) => {
    // Validate request
    if (!req.body.unit_number || !req.body.rent_amount || !req.body.property_id) {
        return res.status(400).send({
            message: "Content can not be empty!"
        });
    }

    // Create a Unit
    const unit = {
        unit_number: req.body.unit_number,
        rent_amount: req.body.rent_amount,
        status: req.body.status || "vacant",
        property_id: req.body.property_id,
        floor_number: req.body.floor_number,
        room_number: req.body.room_number
    };

    // Save Unit in the database
    Unit.create(unit)
        .then(data => {
            res.send(data);
        })
        .catch(err => {
            res.status(500).send({
                message:
                    err.message || "Some error occurred while creating the Unit."
            });
        });
};

exports.findAllByProperty = (req, res) => {
    const propertyId = req.params.propertyId;

    Unit.findAll({
        where: { property_id: propertyId },
        include: [{
            model: db.users,
            as: "tenant",
            attributes: ["id", "name", "email"]
        }]
    })
        .then(data => {
            res.send(data);
        })
        .catch(err => {
            res.status(500).send({
                message:
                    err.message || "Some error occurred while retrieving units."
            });
        });
};

exports.assignTenant = (req, res) => {
    const id = req.params.id;
    const tenantId = req.body.tenant_id;

    if (!tenantId) {
        return res.status(400).send({
            message: "Tenant ID is required!"
        });
    }

    Unit.update(
        { tenant_id: tenantId, status: 'occupied' },
        { where: { id: id } }
    )
        .then(num => {
            if (num == 1) {
                res.send({
                    message: "Tenant assigned successfully."
                });
            } else {
                res.send({
                    message: `Cannot update Unit with id=${id}. Maybe Unit was not found or req.body is empty!`
                });
            }
        })
        .catch(err => {
            res.status(500).send({
                message: "Error updating Unit with id=" + id
            });
        });
};

exports.update = (req, res) => {
    const id = req.params.id;

    Unit.update(req.body, {
        where: { id: id }
    })
        .then(num => {
            if (num == 1) {
                res.send({
                    message: "Unit was updated successfully."
                });
            } else {
                res.send({
                    message: `Cannot update Unit with id=${id}. Maybe Unit was not found or req.body is empty!`
                });
            }
        })
        .catch(err => {
            res.status(500).send({
                message: "Error updating Unit with id=" + id
            });
        });
};

exports.delete = (req, res) => {
    const id = req.params.id;

    Unit.destroy({
        where: { id: id }
    })
        .then(num => {
            if (num == 1) {
                res.send({
                    message: "Unit was deleted successfully!"
                });
            } else {
                res.send({
                    message: `Cannot delete Unit with id=${id}. Maybe Unit was not found!`
                });
            }
        })
        .catch(err => {
            res.status(500).send({
                message: "Could not delete Unit with id=" + id
            });
        });
};
