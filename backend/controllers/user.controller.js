const db = require("../models");
const User = db.users;
const Op = db.Sequelize.Op;

exports.findAllTenants = (req, res) => {
    const query = req.query.query; // Search by name, email, or phone

    let condition = { role: 'tenant' };

    if (query) {
        condition = {
            role: 'tenant',
            [Op.or]: [
                { name: { [Op.like]: `%${query}%` } },
                { email: { [Op.like]: `%${query}%` } },
                { phone: { [Op.like]: `%${query}%` } }
            ]
        };
    }

    User.findAll({ where: condition })
        .then(data => {
            // Don't return passwords
            const users = data.map(user => {
                const { password, ...userWithoutPassword } = user.dataValues;
                return userWithoutPassword;
            });
            res.send(users);
        })
        .catch(err => {
            res.status(500).send({
                message:
                    err.message || "Some error occurred while retrieving tenants."
            });
        });
};

exports.findOne = (req, res) => {
    const id = req.params.id;

    User.findByPk(id)
        .then(data => {
            if (data) {
                const { password, ...userWithoutPassword } = data.dataValues;
                res.send(userWithoutPassword);
            } else {
                res.status(404).send({
                    message: `Cannot find User with id=${id}.`
                });
            }
        })
        .catch(err => {
            res.status(500).send({
                message: "Error retrieving User with id=" + id
            });
        });
};

exports.updateProfile = (req, res) => {
    const id = req.userId; // From verifyToken middleware
    const { name, phone, profile_pic } = req.body;

    User.update(
        { name, phone, profile_pic },
        { where: { id: id } }
    )
        .then(num => {
            if (num == 1) {
                res.send({
                    message: "Profile was updated successfully."
                });
            } else {
                res.send({
                    message: `Cannot update Profile with id=${id}. Maybe User was not found or req.body is empty!`
                });
            }
        })
        .catch(err => {
            res.status(500).send({
                message: "Error updating Profile with id=" + id
            });
        });
};

const bcrypt = require("bcryptjs");

exports.changePassword = (req, res) => {
    const id = req.userId;
    const { currentPassword, newPassword } = req.body;

    User.findByPk(id)
        .then(user => {
            if (!user) {
                return res.status(404).send({ message: "User Not found." });
            }

            var passwordIsValid = bcrypt.compareSync(
                currentPassword,
                user.password
            );

            if (!passwordIsValid) {
                return res.status(401).send({
                    accessToken: null,
                    message: "Invalid Current Password!"
                });
            }

            const passwordHash = bcrypt.hashSync(newPassword, 8);

            User.update(
                { password: passwordHash },
                { where: { id: id } }
            )
                .then(num => {
                    if (num == 1) {
                        res.send({
                            message: "Password was updated successfully."
                        });
                    } else {
                        res.send({
                            message: "Cannot update Password."
                        });
                    }
                })
                .catch(err => {
                    res.status(500).send({
                        message: "Error updating Password."
                    });
                });
        })
        .catch(err => {
            res.status(500).send({
                message: "Error retrieving User."
            });
        });
};
