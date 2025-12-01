const db = require("../models");
const User = db.users;
const Op = db.Sequelize.Op;
const jwt = require("jsonwebtoken");
const bcrypt = require("bcryptjs");

exports.register = (req, res) => {
    // Validate request
    if (!req.body.name || !req.body.email || !req.body.password) {
        res.status(400).send({
            message: "Content can not be empty!"
        });
        return;
    }

    // Create a User
    const user = {
        name: req.body.name,
        email: req.body.email,
        password_hash: bcrypt.hashSync(req.body.password, 8),
        role: req.body.role ? req.body.role : 'tenant',
        phone: req.body.phone
    };

    // Save User in the database
    User.create(user)
        .then(data => {
            res.send(data);
        })
        .catch(err => {
            console.log("Register Error:", err); // Log full error
            res.status(500).send({
                message:
                    err.message || "Some error occurred while creating the User."
            });
        });
};

exports.login = (req, res) => {
    User.findOne({
        where: {
            email: req.body.email.toLowerCase()
        }
    })
        .then(user => {
            if (!user) {
                return res.status(404).send({ message: "User Not found." });
            }

            var passwordIsValid = bcrypt.compareSync(
                req.body.password,
                user.password_hash
            );

            if (!passwordIsValid) {
                return res.status(401).send({
                    accessToken: null,
                    message: "Invalid Password!"
                });
            }

            var token = jwt.sign({ id: user.id, role: user.role }, process.env.JWT_SECRET, {
                expiresIn: 86400 // 24 hours
            });

            res.status(200).send({
                id: user.id,
                name: user.name,
                email: user.email,
                role: user.role,
                accessToken: token
            });
        });
};

const { OAuth2Client } = require('google-auth-library');
const client = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);

exports.googleLogin = async (req, res) => {
    const { idToken } = req.body;

    try {
        const ticket = await client.verifyIdToken({
            idToken: idToken,
            audience: process.env.GOOGLE_CLIENT_ID,
        });
        const payload = ticket.getPayload();
        const { email, name, picture } = payload;

        let user = await User.findOne({ where: { email: email.toLowerCase() } });

        if (!user) {
            // Create new user if not exists
            user = await User.create({
                name: name,
                email: email.toLowerCase(),
                password_hash: bcrypt.hashSync(Math.random().toString(36).slice(-8), 8), // Random password
                role: 'tenant', // Default role
                phone: '' // Phone might not be available
            });
        }

        var token = jwt.sign({ id: user.id, role: user.role }, process.env.JWT_SECRET, {
            expiresIn: 86400 // 24 hours
        });

        res.status(200).send({
            id: user.id,
            name: user.name,
            email: user.email,
            role: user.role,
            accessToken: token
        });

    } catch (error) {
        res.status(401).send({ message: "Invalid Google Token" });
    }
};
