const Joi = require('joi');

// ── Auth Schemas ──────────────────────────────────────────────────────────────

const registerSchema = Joi.object({
    name: Joi.string().min(2).max(100).required(),
    email: Joi.string().email().max(255).required(),
    password: Joi.string()
        .min(8)
        .max(128)
        .pattern(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/)
        .required()
        .messages({
            'string.pattern.base': 'Password must contain at least one uppercase letter, one lowercase letter, and one number.'
        }),
    role: Joi.string().valid('landlord', 'tenant').default('tenant'),
    phone: Joi.string().max(20).optional().allow('')
});

const loginSchema = Joi.object({
    email: Joi.string().email().required(),
    password: Joi.string().required()
});

const forgotPasswordSchema = Joi.object({
    email: Joi.string().email().required()
});

const resetPasswordSchema = Joi.object({
    token: Joi.string().required(),
    newPassword: Joi.string()
        .min(8)
        .max(128)
        .pattern(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/)
        .required()
        .messages({
            'string.pattern.base': 'Password must contain at least one uppercase letter, one lowercase letter, and one number.'
        })
});

// ── Payment Schemas ───────────────────────────────────────────────────────────

const createPaymentIntentSchema = Joi.object({
    amount: Joi.number().positive().min(1).max(10000000).required(),
    currency: Joi.string().length(3).default('kes'),
    unit_id: Joi.number().integer().positive().required(),
    idempotencyKey: Joi.string().max(255).optional()
});

const createMpesaPaymentSchema = Joi.object({
    tenant_id: Joi.number().integer().positive().required(),
    unit_id: Joi.number().integer().positive().required(),
    amount: Joi.number().positive().min(1).max(10000000).required(),
    phone: Joi.string()
        .pattern(/^(?:254|\+254|0)(7|1)\d{8}$/)
        .required()
        .messages({ 'string.pattern.base': 'Phone must be a valid Kenyan number (e.g. 0712345678).' })
});

const confirmStripeSchema = Joi.object({
    paymentIntentId: Joi.string().required(),
    amount: Joi.number().positive().required(),
    tenant_id: Joi.number().integer().positive().required(),
    unit_id: Joi.number().integer().positive().required()
});

// ── Lease Schemas ─────────────────────────────────────────────────────────────

const createLeaseSchema = Joi.object({
    unit_id: Joi.number().integer().positive().required(),
    tenant_id: Joi.number().integer().positive().optional(),
    email: Joi.string().email().optional(),
    name: Joi.string().max(100).optional(),
    phone: Joi.string().max(20).optional().allow(''),
    start_date: Joi.date().iso().required(),
    end_date: Joi.date().iso().greater(Joi.ref('start_date')).optional(),
    rent_amount: Joi.number().positive().required(),
    terms: Joi.string().max(5000).optional()
}).or('tenant_id', 'email'); // must have at least one

// ── Maintenance Schemas ───────────────────────────────────────────────────────

const createMaintenanceSchema = Joi.object({
    unit_id: Joi.number().integer().positive().required(),
    tenant_id: Joi.number().integer().positive().required(),
    issue_type: Joi.string().max(100).required(),
    description: Joi.string().min(10).max(2000).required(),
    priority: Joi.string().valid('low', 'medium', 'high', 'urgent').default('medium')
});

const updateMaintenanceSchema = Joi.object({
    status: Joi.string().valid('pending', 'in_progress', 'resolved', 'cancelled').required(),
    notes: Joi.string().max(1000).optional().allow('')
});

// ── Bill Schemas ──────────────────────────────────────────────────────────────

const createBillSchema = Joi.object({
    unit_id: Joi.number().integer().positive().required(),
    tenant_id: Joi.number().integer().positive().required(),
    type: Joi.string().valid('rent', 'water', 'electricity', 'garbage', 'service_charge', 'other').required(),
    amount: Joi.number().positive().required(),
    due_date: Joi.date().iso().required(),
    description: Joi.string().max(500).optional().allow('')
});

// ── Validation middleware factory ─────────────────────────────────────────────

/**
 * Returns Express middleware that validates req.body against a Joi schema.
 * Throws a formatted 400 on failure.
 */
const validate = (schema) => (req, res, next) => {
    const { error, value } = schema.validate(req.body, { abortEarly: false, stripUnknown: true });
    if (error) {
        return res.status(400).json({
            message: error.details.map(d => d.message).join('; ')
        });
    }
    req.body = value; // replace body with sanitized value
    next();
};

module.exports = {
    validate,
    schemas: {
        registerSchema,
        loginSchema,
        forgotPasswordSchema,
        resetPasswordSchema,
        createPaymentIntentSchema,
        createMpesaPaymentSchema,
        confirmStripeSchema,
        createLeaseSchema,
        createMaintenanceSchema,
        updateMaintenanceSchema,
        createBillSchema
    }
};
