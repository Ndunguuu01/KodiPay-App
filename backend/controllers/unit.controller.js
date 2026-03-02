const db = require("../models");
const Unit = db.units;
const Property = db.properties;
const Lease = db.leases;
const logger = require('../middleware/logger');

// Whitelisted fields for unit creation
const ALLOWED_CREATE_FIELDS = ['unit_number', 'rent_amount', 'property_id', 'floor_number', 'room_number', 'status'];
// Whitelisted fields for unit update — tenant_id is NEVER accepted directly via API
const ALLOWED_UPDATE_FIELDS = ['unit_number', 'rent_amount', 'floor_number', 'room_number', 'status'];

exports.create = async (req, res, next) => {
    try {
        if (!req.body.unit_number || !req.body.rent_amount || !req.body.property_id) {
            return res.status(400).json({ message: 'unit_number, rent_amount, and property_id are required.' });
        }

        // Verify landlord owns this property
        const property = await Property.findOne({
            where: { id: req.body.property_id, landlord_id: req.userId }
        });
        if (!property) {
            return res.status(403).json({ message: 'Access denied: property not found or not owned by you.' });
        }

        // Only pick allowed fields — prevent mass assignment
        const unitData = {};
        ALLOWED_CREATE_FIELDS.forEach(field => {
            if (req.body[field] !== undefined) unitData[field] = req.body[field];
        });
        unitData.status = unitData.status || 'vacant';

        const unit = await Unit.create(unitData);
        res.status(201).json(unit);
    } catch (err) {
        next(err);
    }
};

exports.findAllByProperty = async (req, res, next) => {
    try {
        const propertyId = req.params.propertyId;

        const units = await Unit.findAll({
            where: { property_id: propertyId },
            order: [['unit_number', 'ASC']]
        });

        res.json(units);
    } catch (err) {
        next(err);
    }
};

// ─────────────────────────────────────────────────────────────────────────────
// ASSIGN TENANT — FIX: checks unit not already occupied
// ─────────────────────────────────────────────────────────────────────────────
exports.assignTenant = async (req, res, next) => {
    try {
        const id = req.params.id;
        const tenantId = req.body.tenant_id;

        if (!tenantId) {
            return res.status(400).json({ message: 'Tenant ID is required.' });
        }

        const unit = await Unit.findByPk(id);
        if (!unit) {
            return res.status(404).json({ message: 'Unit not found.' });
        }

        // FIX: Prevent assigning to already-occupied unit
        if (unit.status === 'occupied' || unit.tenant_id) {
            return res.status(409).json({
                message: `Unit ${unit.unit_number} is already occupied. Terminate the existing lease before reassigning.`
            });
        }

        await Unit.update(
            { tenant_id: tenantId, status: 'occupied' },
            { where: { id } }
        );

        const startDate = new Date();
        const nextDueDate = new Date();
        nextDueDate.setMonth(nextDueDate.getMonth() + 1);
        nextDueDate.setDate(5);

        await Lease.create({
            unit_id: id,
            tenant_id: tenantId,
            rent_amount: unit.rent_amount,
            status: 'active',
            start_date: startDate,
            next_due_date: nextDueDate
        });

        logger.info(`Tenant ${tenantId} assigned to unit ${id} by landlord ${req.userId}`);
        res.json({ message: 'Tenant assigned and lease created successfully.' });
    } catch (err) {
        next(err);
    }
};

// ─────────────────────────────────────────────────────────────────────────────
// UPDATE UNIT — FIX: whitelisted fields only, no mass assignment
// ─────────────────────────────────────────────────────────────────────────────
exports.update = async (req, res, next) => {
    try {
        const id = req.params.id;

        // Only pick whitelisted fields — tenant_id and property_id cannot be changed via update
        const updateData = {};
        ALLOWED_UPDATE_FIELDS.forEach(field => {
            if (req.body[field] !== undefined) updateData[field] = req.body[field];
        });

        if (Object.keys(updateData).length === 0) {
            return res.status(400).json({ message: 'No valid fields provided for update.' });
        }

        const [num] = await Unit.update(updateData, { where: { id } });

        if (num === 1) {
            res.json({ message: 'Unit updated successfully.' });
        } else {
            res.status(404).json({ message: `Unit with id=${id} not found.` });
        }
    } catch (err) {
        next(err);
    }
};

exports.delete = async (req, res, next) => {
    try {
        const id = req.params.id;

        // Prevent deletion if unit has active leases
        const activeLease = await Lease.findOne({
            where: { unit_id: id, status: 'active' }
        });
        if (activeLease) {
            return res.status(409).json({
                message: 'Cannot delete unit with an active lease. Terminate the lease first.'
            });
        }

        const num = await Unit.destroy({ where: { id } });
        if (num === 1) {
            res.json({ message: 'Unit deleted successfully.' });
        } else {
            res.status(404).json({ message: `Unit with id=${id} not found.` });
        }
    } catch (err) {
        next(err);
    }
};
