const jwt = require("jsonwebtoken");
const config = process.env;
const db = require("../models");
const User = db.users;

verifyToken = (req, res, next) => {
    let token = req.headers["x-access-token"];

    if (!token) {
        return res.status(403).send({
            message: "No token provided!"
        });
    }

    jwt.verify(token, process.env.JWT_SECRET, (err, decoded) => {
        if (err) {
            return res.status(401).send({
                message: "Unauthorized!"
            });
        }
        req.userId = decoded.id;
        req.userRole = decoded.role;
        next();
    });
};

isLandlord = (req, res, next) => {
    if (req.userRole === 'landlord' || req.userRole === 'admin') {
        next();
        return;
    }
    res.status(403).send({
        message: "Require Landlord Role!"
    });
};

isAdmin = (req, res, next) => {
    if (req.userRole === 'admin') {
        next();
        return;
    }
    res.status(403).send({
        message: "Require Admin Role!"
    });
};

const authJwt = {
    verifyToken: verifyToken,
    isLandlord: isLandlord,
    isAdmin: isAdmin
};
module.exports = authJwt;
