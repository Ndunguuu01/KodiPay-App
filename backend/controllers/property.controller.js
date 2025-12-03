const db = require("../models");
const Property = db.properties;
const Unit = db.units;
const Op = db.Sequelize.Op;

// Create and Save a new Property
exports.create = (req, res) => {
    // Validate request
    if (!req.body.name || !req.body.landlord_id) {
        res.status(400).send({
            message: "Content can not be empty!"
        });
        return;
    }

    const property = {
        name: req.body.name,
        location: req.body.location,
        floors_count: req.body.floors_count,
        landlord_id: req.body.landlord_id,
        image_url: req.file ? req.file.path : null // Save Cloudinary URL
    };

    Property.create(property)
        .then(async data => {
            // Auto-generate units if parameters are provided
            const roomsPerFloor = req.body.rooms_per_floor;
            const defaultRent = req.body.default_rent;

            if (roomsPerFloor && defaultRent) {
                const units = [];
                for (let i = 0; i < property.floors_count; i++) {
                    const floorNum = i + 1;
                    for (let j = 1; j <= roomsPerFloor; j++) {
                        // Generate letter: A, B, C...
                        // Note: This simple logic works for up to 26 rooms per floor.
                        // For more, we'd need AA, AB logic, but for now A-Z is sufficient.
                        const roomLetter = String.fromCharCode(65 + (j - 1));

                        units.push({
                            unit_number: `${floorNum}${roomLetter}`,
                            rent_amount: defaultRent,
                            status: 'vacant',
                            property_id: data.id,
                            floor_number: floorNum,
                            room_number: roomLetter
                        });
                    }
                }
                await Unit.bulkCreate(units);
            }

            res.send(data);
        })
        .catch(err => {
            res.status(500).send({
                message:
                    err.message || "Some error occurred while creating the Property."
            });
        });
};

// Retrieve all Properties (or for a specific landlord)
exports.findAll = (req, res) => {
    const landlord_id = req.query.landlord_id;
    var condition = landlord_id ? { landlord_id: { [Op.eq]: landlord_id } } : null;

    Property.findAll({ where: condition, include: ["units"] }) // Assuming association set later
        .then(data => {
            res.send(data);
        })
        .catch(err => {
            res.status(500).send({
                message:
                    err.message || "Some error occurred while retrieving properties."
            });
        });
};

// Find a single Property with an id
exports.findOne = (req, res) => {
    const id = req.params.id;

    Property.findByPk(id)
        .then(data => {
            if (data) {
                res.send(data);
            } else {
                res.status(404).send({
                    message: `Cannot find Property with id=${id}.`
                });
            }
        })
        .catch(err => {
            res.status(500).send({
                message: "Error retrieving Property with id=" + id
            });
        });
};
