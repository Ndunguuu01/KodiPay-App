const db = require("../models");
const Ad = db.ads;
const Op = db.Sequelize.Op;

// Create and Save a new Ad
exports.create = (req, res) => {
    // Validate request
    if (!req.body.user_id) {
        res.status(400).send({
            message: "User ID is required!"
        });
        return;
    }

    // Calculate expiration date (1 week from now)
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + 7);

    // Create an Ad
    const ad = {
        title: req.body.title,
        description: req.body.description,
        contact_info: req.body.contact_info,
        image_url: req.body.image_url,
        type: req.body.type || 'image',
        expires_at: expiresAt,
        user_id: req.body.user_id
    };

    // Save Ad in the database
    Ad.create(ad)
        .then(data => {
            res.send(data);
        })
        .catch(err => {
            res.status(500).send({
                message:
                    err.message || "Some error occurred while creating the Ad."
            });
        });
};

// Retrieve all Ads from the database.
exports.findAll = (req, res) => {
    // Filter out expired ads
    Ad.findAll({
        where: {
            expires_at: {
                [Op.gt]: new Date()
            }
        },
        order: [['createdAt', 'DESC']]
    })
        .then(data => {
            res.send(data);
        })
        .catch(err => {
            res.status(500).send({
                message:
                    err.message || "Some error occurred while retrieving ads."
            });
        });
};
