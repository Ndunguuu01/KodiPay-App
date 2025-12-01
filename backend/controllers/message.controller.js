const db = require("../models");
const Message = db.messages;
const Op = db.Sequelize.Op;

// Send a message
exports.create = (req, res) => {
    if (!req.body.content || !req.body.sender_id) {
        res.status(400).send({
            message: "Content can not be empty!"
        });
        return;
    }

    const message = {
        sender_id: req.body.sender_id,
        receiver_id: req.body.receiver_id,
        group_id: req.body.group_id,
        content: req.body.content,
        type: req.body.type || 'text'
    };

    Message.create(message)
        .then(data => {
            // Emit socket event
            const io = req.app.get('socketio');
            if (message.group_id) {
                io.to(`group_${message.group_id}`).emit('new_message', data);
            } else {
                io.to(`user_${message.receiver_id}`).emit('new_message', data);
                io.to(`user_${message.sender_id}`).emit('new_message', data); // Also emit to sender for multi-device sync
            }
            res.send(data);
        })
        .catch(err => {
            res.status(500).send({
                message:
                    err.message || "Some error occurred while sending the message."
            });
        });
};

// Get messages (Direct or Group)
exports.findAll = (req, res) => {
    const { user_id, other_user_id, group_id } = req.query;

    let condition = {};

    if (group_id) {
        condition = { group_id: group_id };
    } else if (user_id && other_user_id) {
        condition = {
            [Op.or]: [
                { sender_id: user_id, receiver_id: other_user_id },
                { sender_id: other_user_id, receiver_id: user_id }
            ]
        };
    } else if (user_id) {
        condition = {
            [Op.or]: [
                { sender_id: user_id },
                { receiver_id: user_id }
            ]
        };
    } else {
        // Fallback or error
    }

    Message.findAll({
        where: condition,
        order: [['createdAt', 'ASC']],
        include: [
            {
                model: db.users,
                as: 'sender',
                attributes: ['name']
            }
        ]
    })
        .then(data => {
            res.send(data);
        })
        .catch(err => {
            res.status(500).send({
                message:
                    err.message || "Some error occurred while retrieving messages."
            });
        });
};
