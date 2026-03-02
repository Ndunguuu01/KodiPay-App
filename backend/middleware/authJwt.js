const jwt = require("jsonwebtoken");
const db = require("../models");
const User = db.users;

/**
 * Verifies Bearer JWT from x-access-token header.
 * On success: sets req.userId and req.userRole.
 */
const verifyToken = (req, res, next) => {
    const token = req.headers["x-access-token"];

    if (!token) {
        return res.status(403).json({ message: "No token provided." });
    }

    jwt.verify(token, process.env.JWT_SECRET, (err, decoded) => {
        if (err) {
            if (err.name === "TokenExpiredError") {
                return res.status(401).json({ message: "Session expired. Please log in again." });
            }
            return res.status(401).json({ message: "Unauthorized." });
        }
        req.userId = decoded.id;
        req.userRole = decoded.role;
        next();
    });
};

/**
 * Restricts access to users with the 'landlord' or 'admin' role.
 */
const isLandlord = (req, res, next) => {
    if (req.userRole === "landlord" || req.userRole === "admin") {
        return next();
    }
    return res.status(403).json({ message: "Access denied: Landlord role required." });
};

/**
 * Restricts access to users with the 'admin' role only.
 */
const isAdmin = (req, res, next) => {
    if (req.userRole === "admin") {
        return next();
    }
    return res.status(403).json({ message: "Access denied: Admin role required." });
};

/**
 * Enforces that the authenticated user can only access their own resource.
 * paramField: the request param name containing the target user ID (default: 'userId')
 * Landlords and admins are exempt — they can see any user's data.
 *
 * Usage: [verifyToken, isSelf('userId')]
 */
const isSelf = (paramField = "userId") => (req, res, next) => {
    // Landlords and admins may view any user's data
    if (req.userRole === "landlord" || req.userRole === "admin") {
        return next();
    }
    const targetId = parseInt(req.params[paramField], 10);
    if (req.userId === targetId) {
        return next();
    }
    return res.status(403).json({ message: "Access denied: You can only access your own data." });
};

/**
 * Verifies that a tenant can only access their own data OR a landlord can access any.
 * Alias for isSelf — use where both landlord and tenant access is needed.
 */
const isLandlordOrSelf = (paramField = "userId") => (req, res, next) => {
    if (req.userRole === "landlord" || req.userRole === "admin") {
        return next();
    }
    const targetId = parseInt(req.params[paramField], 10);
    if (req.userId === targetId) {
        return next();
    }
    return res.status(403).json({ message: "Access denied." });
};

const authJwt = {
    verifyToken,
    isLandlord,
    isAdmin,
    isSelf,
    isLandlordOrSelf,
};

module.exports = authJwt;
