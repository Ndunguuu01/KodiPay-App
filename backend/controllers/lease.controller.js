const db = require("../models");
const Lease = db.leases;
const User = db.users;
const Unit = db.units;
const bcrypt = require("bcryptjs");
const crypto = require("crypto");
const Op = db.Sequelize.Op;
const EmailService = require('../services/email.service');
const logger = require('../middleware/logger');

// ─────────────────────────────────────────────────────────────────────────────
// CREATE LEASE — landlord creates a lease for an existing or new tenant
// CRITICAL FIX: removed hardcoded password '123456'
// ─────────────────────────────────────────────────────────────────────────────
exports.create = async (req, res, next) => {
    try {
        let tenantId = req.body.tenant_id;

        // If tenant_id is not provided, look up or create tenant by email
        if (!tenantId && req.body.email) {
            let user = await User.findOne({
                where: { email: req.body.email.toLowerCase() }
            });

            if (!user) {
                // FIX: Never set a known password. Generate a secure reset token
                // and email the tenant an invitation link to set their own password.
                const rawToken = crypto.randomBytes(32).toString('hex');
                const hashedToken = crypto.createHash('sha256').update(rawToken).digest('hex');
                const expires = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000); // 7 days

                // Use random hash as placeholder — tenant MUST use the invite link
                const placeholderHash = bcrypt.hashSync(crypto.randomBytes(32).toString('hex'), 12);

                user = await User.create({
                    name: req.body.name || req.body.email,
                    email: req.body.email.toLowerCase(),
                    password_hash: placeholderHash,
                    role: 'tenant',
                    phone: req.body.phone || '',
                    must_reset_password: true,
                    password_reset_token: hashedToken,
                    password_reset_expires: expires
                });

                // Send invitation email with set-password link
                const inviteUrl = `${process.env.FRONTEND_URL || 'kodipay://reset-password'}?token=${rawToken}&invite=true`;
                const htmlContent = `
                    <h2>Welcome to KodiPay!</h2>
                    <p>Hello ${user.name},</p>
                    <p>Your landlord has created an account for you on KodiPay — a platform to manage your rent and tenancy.</p>
                    <p>Click the button below to set your password and access your account. This link is valid for <strong>7 days</strong>.</p>
                    <p><a href="${inviteUrl}" style="background:#4F46E5;color:#fff;padding:12px 24px;border-radius:6px;text-decoration:none;display:inline-block;">Set My Password</a></p>
                    <p>If you have any questions, contact your landlord or reply to this email.</p>
                    <p><em>The KodiPay Team</em></p>
                `;

                try {
                    await EmailService.sendEmail(
                        user.email,
                        'You\'ve been invited to KodiPay — Set Your Password',
                        htmlContent
                    );
                    logger.info(`Tenant invite email sent to ${user.email}`);
                } catch (emailErr) {
                    // Don't fail the request if email fails — log and continue
                    logger.error(`Failed to send invite email to ${user.email}:`, emailErr);
                }
            }
            tenantId = user.id;
        }

        if (!tenantId) {
            return res.status(400).json({ message: 'Tenant ID or email is required.' });
        }

        const lease = await Lease.create({
            unit_id: req.body.unit_id,
            tenant_id: tenantId,
            start_date: req.body.start_date,
            end_date: req.body.end_date,
            rent_amount: req.body.rent_amount,
            terms: req.body.terms,
            status: 'pending'
        });

        // Notify tenant via socket
        const io = req.app.get('socketio');
        io.to(`user_${tenantId}`).emit('lease_assigned', {
            message: 'You have been assigned to a new unit. Please sign the lease agreement.'
        });

        res.status(201).json(lease);
    } catch (err) {
        next(err);
    }
};

// ─────────────────────────────────────────────────────────────────────────────
// GET LEASE BY TENANT — enforces tenant can only see their own
// ─────────────────────────────────────────────────────────────────────────────
exports.findAllByTenant = async (req, res, next) => {
    try {
        const tenantId = parseInt(req.params.userId, 10);

        // Tenants can only access their own leases
        if (req.userRole === 'tenant' && req.userId !== tenantId) {
            return res.status(403).json({ message: 'Access denied.' });
        }

        const leases = await Lease.findAll({
            where: { tenant_id: tenantId },
            include: ['unit'],
            order: [['createdAt', 'DESC']]
        });

        res.json(leases);
    } catch (err) {
        next(err);
    }
};

// ─────────────────────────────────────────────────────────────────────────────
// SIGN LEASE — tenant signs their own lease only
// ─────────────────────────────────────────────────────────────────────────────
exports.sign = async (req, res, next) => {
    try {
        const id = req.params.id;
        const lease = await Lease.findByPk(id);

        if (!lease) {
            return res.status(404).json({ message: 'Lease not found.' });
        }

        // Tenants can only sign their own leases
        if (req.userRole === 'tenant' && lease.tenant_id !== req.userId) {
            return res.status(403).json({ message: 'Access denied.' });
        }

        if (lease.status !== 'pending') {
            return res.status(400).json({ message: 'Lease is not pending.' });
        }

        lease.status = 'active';
        await lease.save();

        await Unit.update(
            { tenant_id: lease.tenant_id, status: 'occupied' },
            { where: { id: lease.unit_id } }
        );

        // Notify landlord
        const unit = await Unit.findByPk(lease.unit_id);
        const property = await db.properties.findByPk(unit.property_id);
        const io = req.app.get('socketio');
        io.to(`user_${property.landlord_id}`).emit('lease_signed', {
            message: `Lease signed for Unit ${unit.unit_number}.`
        });

        res.json({ message: 'Lease signed successfully.' });
    } catch (err) {
        next(err);
    }
};

// ─────────────────────────────────────────────────────────────────────────────
// GET LEASES BY LANDLORD
// ─────────────────────────────────────────────────────────────────────────────
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

        const leases = await Lease.findAll({
            where: { unit_id: { [Op.in]: unitIds } },
            include: ['unit', 'tenant'],
            order: [['createdAt', 'DESC']]
        });

        res.json(leases);
    } catch (err) {
        next(err);
    }
};

// ─────────────────────────────────────────────────────────────────────────────
// TERMINATE LEASE — landlord/admin only
// ─────────────────────────────────────────────────────────────────────────────
exports.terminate = async (req, res, next) => {
    try {
        const id = req.params.id;
        const lease = await Lease.findByPk(id);

        if (!lease) {
            return res.status(404).json({ message: 'Lease not found.' });
        }

        lease.status = 'terminated';
        await lease.save();

        await Unit.update(
            { status: 'vacant', tenant_id: null },
            { where: { id: lease.unit_id } }
        );

        res.json({ message: 'Lease terminated successfully.' });
    } catch (err) {
        next(err);
    }
};
