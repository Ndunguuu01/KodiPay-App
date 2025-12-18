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
    console.log(`Fetching units for property: ${propertyId}`);

    Unit.findAll({
        where: { property_id: propertyId },
        // include: [{
        //     model: db.users,
        //     as: "tenant",
        //     attributes: ["id", "name", "email"],
        //     required: false
        // }]
    })
        .then(data => {
            console.log(`Found ${data.length} units for property ${propertyId}`);
            res.send(data);
        })
        .catch(err => {
            console.error("Error fetching units:", err);
            res.status(500).send({
                message:
                    err.message || "Some error occurred while retrieving units."
            });
        });
};

const Lease = db.leases;

exports.assignTenant = async (req, res) => {
    const id = req.params.id;
    const tenantId = req.body.tenant_id;

    if (!tenantId) {
        return res.status(400).send({
            message: "Tenant ID is required!"
        });
    }

    try {
        // 1. Get Unit to check rent amount
        const unit = await Unit.findByPk(id);
        if (!unit) {
            return res.status(404).send({ message: "Unit not found." });
        }

        // 2. Update Unit
        await Unit.update(
            { tenant_id: tenantId, status: 'occupied' },
            { where: { id: id } }
        );

        // 3. Create Lease
        const startDate = new Date();
        const nextDueDate = new Date();
        nextDueDate.setMonth(nextDueDate.getMonth() + 1);
        nextDueDate.setDate(5); // Default to 5th

        await Lease.create({
            unit_id: id,
            tenant_id: tenantId,
            rent_amount: unit.rent_amount,
            status: 'active',
            start_date: startDate,
            next_due_date: nextDueDate
        });

        res.send({
            message: "Tenant assigned and lease created successfully."
        });

    } catch (err) {
        res.status(500).send({
            message: err.message || "Error assigning tenant."
        });
    }
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
