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
        image_url: req.file ? req.file.path : req.body.image_url, // Use uploaded file or fallback
        type: req.body.type || 'image',
        expires_at: expiresAt,
        user_id: req.body.user_id
    };

    // Save Ad in the database
    Ad.create(ad)
        .then(data => {
            // Emit socket event
            const io = req.app.get('socketio');
            io.emit('new_ad', data);

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

// Delete an Ad with the specified id in the request
// Delete an Ad with the specified id in the request
exports.delete = (req, res) => {
    const id = req.params.id;
    const userId = req.userId; // Get user ID from token

    Ad.destroy({
        where: {
            id: id,
            user_id: userId // Ensure the ad belongs to the user
        }
    })
        .then(num => {
            if (num == 1) {
                res.send({
                    message: "Ad was deleted successfully!"
                });
            } else {
                res.send({
                    message: `Cannot delete Ad with id=${id}. Maybe Ad was not found or you are not the owner!`
                });
            }
        })
        .catch(err => {
            res.status(500).send({
                message: "Could not delete Ad with id=" + id
            });
        });
};
