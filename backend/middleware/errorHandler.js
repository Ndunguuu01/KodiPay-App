const logger = require('./logger');

/**
 * Centralized error handler middleware.
 * Must be mounted LAST via app.use(errorHandler).
 * Never exposes stack traces or internal details in production.
 */
const errorHandler = (err, req, res, next) => {
    // Log full error internally
    logger.error(err);

    // Joi validation errors
    if (err.isJoi || err.name === 'ValidationError') {
        return res.status(400).json({
            message: err.details ? err.details[0].message : err.message
        });
    }

    // JWT errors
    if (err.name === 'JsonWebTokenError') {
        return res.status(401).json({ message: 'Invalid token.' });
    }
    if (err.name === 'TokenExpiredError') {
        return res.status(401).json({ message: 'Session expired. Please log in again.' });
    }

    // Sequelize unique constraint (duplicate key)
    if (err.name === 'SequelizeUniqueConstraintError') {
        const field = err.errors[0]?.path || 'field';
        return res.status(409).json({ message: `An account with this ${field} already exists.` });
    }

    // Sequelize validation error
    if (err.name === 'SequelizeValidationError') {
        return res.status(400).json({ message: err.errors[0]?.message || 'Validation error.' });
    }

    // Default: Internal server error — never expose internals
    const statusCode = err.statusCode || 500;
    const message = process.env.NODE_ENV === 'production'
        ? 'An internal server error occurred.'
        : err.message || 'An internal server error occurred.';

    res.status(statusCode).json({ message });
};

/**
 * Wrap async route handlers to forward errors to errorHandler.
 * Usage: router.get('/path', asyncHandler(controller.method))
 */
const asyncHandler = (fn) => (req, res, next) => {
    Promise.resolve(fn(req, res, next)).catch(next);
};

module.exports = { errorHandler, asyncHandler };
