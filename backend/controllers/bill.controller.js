const db = require("../models");
const Bill = db.bills;
const logger = require('../middleware/logger');

exports.create = async (req, res, next) => {
    try {
        const { unit_id, tenant_id, type, amount, due_date, description } = req.body; // Joi validated

        if (!tenant_id) {
            return res.status(400).json({ message: 'tenant_id is required.' });
        }

        const bill = await Bill.create({
            unit_id,
            tenant_id,
            type,
            amount,
            due_date,
            description: description || '',
            status: 'unpaid'
        });

        // Notify tenant
        const io = req.app.get('socketio');
        io.to(`user_${tenant_id}`).emit('new_bill', bill);

        res.status(201).json(bill);
    } catch (err) {
        next(err);
    }
};

exports.findAllByTenant = async (req, res, next) => {
    try {
        const tenantId = parseInt(req.params.userId, 10);

        // Tenants may only access their own bills
        if (req.userRole === 'tenant' && req.userId !== tenantId) {
            return res.status(403).json({ message: 'Access denied.' });
        }

        const page = Math.max(1, parseInt(req.query.page) || 1);
        const limit = Math.min(100, parseInt(req.query.limit) || 20);
        const offset = (page - 1) * limit;

        const { count, rows } = await Bill.findAndCountAll({
            where: { tenant_id: tenantId },
            include: ['unit'],
            order: [['due_date', 'DESC']],
            limit,
            offset
        });

        res.json({ total: count, page, limit, data: rows });
    } catch (err) {
        next(err);
    }
};

exports.findAllByUnit = async (req, res, next) => {
    try {
        const unitId = req.params.unitId;

        const bills = await Bill.findAll({
            where: { unit_id: unitId },
            order: [['due_date', 'DESC']]
        });

        res.json(bills);
    } catch (err) {
        next(err);
    }
};

// ─────────────────────────────────────────────────────────────────────────────
// MARK AS PAID — FIX: landlord-only (enforced here AND in the route)
// ─────────────────────────────────────────────────────────────────────────────
exports.markAsPaid = async (req, res, next) => {
    try {
        const id = req.params.id;

        // Double-check role (belt + braces — route also has isLandlord)
        if (req.userRole === 'tenant') {
            return res.status(403).json({ message: 'Access denied: only landlords can manually mark bills as paid.' });
        }

        const [num] = await Bill.update({ status: 'paid' }, { where: { id } });

        if (num === 1) {
            logger.info(`Bill ${id} manually marked as paid by landlord ${req.userId}`);
            res.json({ message: 'Bill marked as paid.' });
        } else {
            res.status(404).json({ message: `Bill with id=${id} not found.` });
        }
    } catch (err) {
        next(err);
    }
};
