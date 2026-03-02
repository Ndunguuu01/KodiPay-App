const db = require("../models");
const Maintenance = db.maintenance;
const User = db.users;
const Unit = db.units;
const Op = db.Sequelize.Op;
const logger = require('../middleware/logger');

// Whitelisted fields for maintenance status update (landlord)
const ALLOWED_UPDATE_FIELDS = ['status', 'notes'];

exports.create = async (req, res, next) => {
    try {
        const { unit_id, tenant_id, issue_type, description, priority } = req.body; // Joi validated

        // Tenants can only submit requests for their own unit
        if (req.userRole === 'tenant') {
            const unit = await Unit.findOne({
                where: { id: unit_id, tenant_id: req.userId }
            });
            if (!unit) {
                return res.status(403).json({
                    message: 'Access denied: you are not assigned to this unit.'
                });
            }
        }

        const maintenance = await Maintenance.create({
            unit_id,
            tenant_id,
            issue_type,
            description,
            priority: priority || 'medium',
            status: 'pending'
        });

        res.status(201).json(maintenance);
    } catch (err) {
        next(err);
    }
};

exports.findAll = async (req, res, next) => {
    try {
        const page = Math.max(1, parseInt(req.query.page) || 1);
        const limit = Math.min(100, parseInt(req.query.limit) || 20);
        const offset = (page - 1) * limit;

        let condition = {};
        if (req.userRole === 'tenant') {
            condition.tenant_id = req.userId; // Tenants only see their own
        } else {
            if (req.query.tenant_id) condition.tenant_id = parseInt(req.query.tenant_id);
            if (req.query.unit_id) condition.unit_id = parseInt(req.query.unit_id);
        }

        const { count, rows } = await Maintenance.findAndCountAll({
            where: condition,
            include: [
                { model: User, as: 'tenant', attributes: ['name', 'phone'] },
                { model: Unit, as: 'unit', attributes: ['unit_number'] }
            ],
            order: [['createdAt', 'DESC']],
            limit,
            offset
        });

        res.json({ total: count, page, limit, data: rows });
    } catch (err) {
        next(err);
    }
};

exports.findAllByLandlord = async (req, res, next) => {
    try {
        const landlordId = parseInt(req.params.userId, 10);

        const properties = await db.properties.findAll({
            where: { landlord_id: landlordId },
            attributes: ['id']
        });
        const propertyIds = properties.map(p => p.id);
        if (propertyIds.length === 0) return res.json([]);

        const units = await Unit.findAll({
            where: { property_id: { [Op.in]: propertyIds } },
            attributes: ['id']
        });
        const unitIds = units.map(u => u.id);
        if (unitIds.length === 0) return res.json([]);

        const requests = await Maintenance.findAll({
            where: { unit_id: { [Op.in]: unitIds } },
            include: [
                { model: User, as: 'tenant', attributes: ['name', 'phone'] },
                { model: Unit, as: 'unit', attributes: ['unit_number'] }
            ],
            order: [['createdAt', 'DESC']]
        });

        res.json(requests);
    } catch (err) {
        next(err);
    }
};

// ─────────────────────────────────────────────────────────────────────────────
// UPDATE — FIX: only whitelisted fields allowed (no mass assignment)
// ─────────────────────────────────────────────────────────────────────────────
exports.update = async (req, res, next) => {
    try {
        const id = req.params.id;

        // Whitelist: landlords can only update status and notes
        const updateData = {};
        ALLOWED_UPDATE_FIELDS.forEach(field => {
            if (req.body[field] !== undefined) updateData[field] = req.body[field];
        });

        if (Object.keys(updateData).length === 0) {
            return res.status(400).json({ message: 'No valid fields to update. Only status and notes are allowed.' });
        }

        const [num] = await Maintenance.update(updateData, { where: { id } });

        if (num === 1) {
            const data = await Maintenance.findByPk(id);
            const io = req.app.get('socketio');
            io.to(`user_${data.tenant_id}`).emit('maintenance_update', data);
            res.json({ message: 'Maintenance request updated.' });
        } else {
            res.status(404).json({ message: `Maintenance request with id=${id} not found.` });
        }
    } catch (err) {
        next(err);
    }
};
