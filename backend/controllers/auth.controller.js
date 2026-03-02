const db = require("../models");
const User = db.users;
const jwt = require("jsonwebtoken");
const bcrypt = require("bcryptjs");
const crypto = require("crypto");
const { OAuth2Client } = require('google-auth-library');
const EmailService = require('../services/email.service');
const logger = require('../middleware/logger');

// ─────────────────────────────────────────────────────────────────────────────
// REGISTER
// ─────────────────────────────────────────────────────────────────────────────
exports.register = async (req, res, next) => {
    try {
        const { name, email, password, role, phone } = req.body; // already Joi-validated

        const user = await User.create({
            name,
            email: email.toLowerCase(),
            password_hash: bcrypt.hashSync(password, 12), // cost factor 12
            role: role || 'tenant',
            phone: phone || ''
        });

        // Never return password_hash in response
        res.status(201).json({
            id: user.id,
            name: user.name,
            email: user.email,
            role: user.role
        });
    } catch (err) {
        next(err); // centralized errorHandler handles SequelizeUniqueConstraintError → 409
    }
};

// ─────────────────────────────────────────────────────────────────────────────
// LOGIN  — fixed user-enumeration: same message for both wrong email & password
// ─────────────────────────────────────────────────────────────────────────────
exports.login = async (req, res, next) => {
    try {
        const { email, password } = req.body;

        const user = await User.findOne({ where: { email: email.toLowerCase() } });

        // Constant-time comparison even when user doesn't exist (prevent timing attacks)
        const dummyHash = '$2a$12$invalidhashusedtomaintainconstanttimebehaviouronlogin1234';
        const hashToCompare = user ? user.password_hash : dummyHash;
        const passwordIsValid = bcrypt.compareSync(password, hashToCompare);

        if (!user || !passwordIsValid) {
            // Same message for both cases — prevents user enumeration
            return res.status(401).json({ message: 'Invalid credentials.' });
        }

        const token = jwt.sign(
            { id: user.id, role: user.role },
            process.env.JWT_SECRET,
            { expiresIn: '24h' }
        );

        // Warn if tenant must reset password (invited account)
        const mustReset = user.must_reset_password || false;

        res.status(200).json({
            id: user.id,
            name: user.name,
            email: user.email,
            role: user.role,
            mustResetPassword: mustReset,
            accessToken: token
        });
    } catch (err) {
        next(err);
    }
};

// ─────────────────────────────────────────────────────────────────────────────
// GOOGLE SSO LOGIN
// ─────────────────────────────────────────────────────────────────────────────
const googleClient = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);

exports.googleLogin = async (req, res, next) => {
    try {
        const { idToken } = req.body;

        const ticket = await googleClient.verifyIdToken({
            idToken,
            audience: process.env.GOOGLE_CLIENT_ID
        });
        const { email, name } = ticket.getPayload();

        let user = await User.findOne({ where: { email: email.toLowerCase() } });

        if (!user) {
            user = await User.create({
                name,
                email: email.toLowerCase(),
                password_hash: bcrypt.hashSync(crypto.randomBytes(32).toString('hex'), 12),
                role: 'tenant',
                phone: ''
            });
        }

        const token = jwt.sign(
            { id: user.id, role: user.role },
            process.env.JWT_SECRET,
            { expiresIn: '24h' }
        );

        res.status(200).json({
            id: user.id,
            name: user.name,
            email: user.email,
            role: user.role,
            accessToken: token
        });
    } catch (err) {
        logger.error('Google login error:', err);
        return res.status(401).json({ message: 'Invalid Google token.' });
    }
};

// ─────────────────────────────────────────────────────────────────────────────
// FORGOT PASSWORD — generates a secure reset token and emails it
// ─────────────────────────────────────────────────────────────────────────────
exports.forgotPassword = async (req, res, next) => {
    try {
        const { email } = req.body;

        const user = await User.findOne({ where: { email: email.toLowerCase() } });

        // Always return 200 regardless of whether email exists — prevents enumeration
        if (!user) {
            return res.status(200).json({
                message: 'If that email is registered, a password reset link has been sent.'
            });
        }

        // Generate cryptographically secure token
        const rawToken = crypto.randomBytes(32).toString('hex');
        const hashedToken = crypto.createHash('sha256').update(rawToken).digest('hex');
        const expires = new Date(Date.now() + 60 * 60 * 1000); // 1 hour

        await user.update({
            password_reset_token: hashedToken,
            password_reset_expires: expires
        });

        // Build reset URL (frontend deep-link or web URL)
        const resetUrl = `${process.env.FRONTEND_URL || 'kodipay://reset-password'}?token=${rawToken}`;

        const htmlContent = EmailService.getPasswordResetTemplate
            ? EmailService.getPasswordResetTemplate(user.name, resetUrl, 60)
            : `<p>Hello ${user.name},</p>
               <p>You requested a password reset. Click the link below (valid for 60 minutes):</p>
               <p><a href="${resetUrl}">${resetUrl}</a></p>
               <p>If you did not request this, ignore this email — your account remains secure.</p>`;

        await EmailService.sendEmail(
            user.email,
            'KodiPay — Password Reset Request',
            htmlContent
        );

        logger.info(`Password reset token issued for user ${user.id}`);

        return res.status(200).json({
            message: 'If that email is registered, a password reset link has been sent.'
        });
    } catch (err) {
        next(err);
    }
};

// ─────────────────────────────────────────────────────────────────────────────
// RESET PASSWORD — validates token, sets new password, clears token
// ─────────────────────────────────────────────────────────────────────────────
exports.resetPassword = async (req, res, next) => {
    try {
        const { token, newPassword } = req.body;

        // Hash the incoming raw token to compare against stored hash
        const hashedToken = crypto.createHash('sha256').update(token).digest('hex');

        const user = await User.findOne({
            where: {
                password_reset_token: hashedToken,
                password_reset_expires: { [db.Sequelize.Op.gt]: new Date() }
            }
        });

        if (!user) {
            return res.status(400).json({ message: 'Reset token is invalid or has expired.' });
        }

        await user.update({
            password_hash: bcrypt.hashSync(newPassword, 12),
            password_reset_token: null,
            password_reset_expires: null,
            must_reset_password: false
        });

        logger.info(`Password successfully reset for user ${user.id}`);

        res.status(200).json({ message: 'Password reset successfully. Please log in.' });
    } catch (err) {
        next(err);
    }
};
