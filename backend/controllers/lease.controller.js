const db = require("../models");
const Lease = db.leases;
const User = db.users;
const Unit = db.units;
const bcrypt = require("bcryptjs");
const Op = db.Sequelize.Op;

exports.create = async (req, res) => {
    try {
        let tenantId = req.body.tenant_id;

        // If tenant_id is not provided, check email
        if (!tenantId && req.body.email) {
            let user = await User.findOne({ where: { email: req.body.email.toLowerCase() } });
            if (!user) {
                // Create new user
                user = await User.create({
                    name: req.body.name,
                    email: req.body.email.toLowerCase(),
                    password_hash: bcrypt.hashSync("123456", 8), // Default password
                    role: 'tenant',
                    phone: req.body.phone
                });
            }
            tenantId = user.id;
        }

        if (!tenantId) {
            return res.status(400).send({ message: "Tenant ID or Email is required." });
        }

        const lease = {
            unit_id: req.body.unit_id,
            tenant_id: tenantId,
            start_date: req.body.start_date,
            end_date: req.body.end_date,
            rent_amount: req.body.rent_amount,
            terms: req.body.terms,
            status: 'pending'
        };

        const data = await Lease.create(lease);

        // Emit socket event to tenant
        const io = req.app.get('socketio');
        io.to(`user_${tenantId}`).emit('lease_assigned', {
            message: "You have been assigned to a new unit. Please sign the lease agreement."
        });

        res.send(data);
    } catch (err) {
        res.status(500).send({ message: err.message || "Error creating lease." });
    }
};

exports.findAllByTenant = (req, res) => {
    const tenantId = req.params.userId;

    Lease.findAll({
        where: { tenant_id: tenantId },
        include: ["unit"]
    })
        .then(data => {
            res.send(data);
        })
        .catch(err => {
            res.status(500).send({
                message: err.message || "Some error occurred while retrieving leases."
            });
        });
};

exports.sign = async (req, res) => {
    const id = req.params.id;

    try {
        const lease = await Lease.findByPk(id);
        if (!lease) {
            return res.status(404).send({ message: "Lease not found." });
        }

        if (lease.status !== 'pending') {
            return res.status(400).send({ message: "Lease is not pending." });
        }

        // Update Lease status
        lease.status = 'active';
        await lease.save();

        // Update Unit status and tenant
        await Unit.update(
            { tenant_id: lease.tenant_id, status: 'occupied' },
            { where: { id: lease.unit_id } }
        );

        // Find Landlord to notify
        const unit = await Unit.findByPk(lease.unit_id);
        const property = await db.properties.findByPk(unit.property_id);

        const io = req.app.get('socketio');
        io.to(`user_${property.landlord_id}`).emit('lease_signed', {
            message: `Lease signed for Unit ${unit.unit_number}.`
        });

        res.send({ message: "Lease signed successfully." });
    } catch (err) {
        res.status(500).send({ message: err.message || "Error signing lease." });
    }
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

        // Find all leases for these units
        const leases = await Lease.findAll({
            where: { unit_id: { [Op.in]: unitIds } },
            include: ["unit", "tenant"]
        });

        res.send(leases);
    } catch (err) {
        res.status(500).send({
            message: err.message || "Some error occurred while retrieving leases."
        });
    }
};

exports.terminate = async (req, res) => {
    const id = req.params.id;

    try {
        const lease = await Lease.findByPk(id);
        if (!lease) {
            return res.status(404).send({ message: "Lease not found." });
        }

        lease.status = 'terminated';
        await lease.save();

        // Update Unit status to vacant
        await Unit.update(
            { status: 'vacant', tenant_id: null },
            { where: { id: lease.unit_id } }
        );

        res.send({ message: "Lease terminated successfully." });
    } catch (err) {
        res.status(500).send({ message: err.message || "Error terminating lease." });
    }
};
