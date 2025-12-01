const db = require("../models");
const Bill = db.bills;
const Unit = db.units;
const User = db.users;

exports.create = (req, res) => {
    // Validate request
    if (!req.body.unit_id || !req.body.amount || !req.body.type) {
        res.status(400).send({
            message: "Content can not be empty!"
        });
        return;
    }

    const bill = {
        unit_id: req.body.unit_id,
        tenant_id: req.body.tenant_id,
        type: req.body.type,
        amount: req.body.amount,
        due_date: req.body.due_date,
        description: req.body.description,
        status: 'unpaid'
    };

    Bill.create(bill)
        .then(data => {
            // Emit socket event
            const io = req.app.get('socketio');
            io.to(`user_${bill.tenant_id}`).emit('new_bill', data);

            res.send(data);
        })
        .catch(err => {
            res.status(500).send({
                message: err.message || "Some error occurred while creating the Bill."
            });
        });
};

exports.findAllByTenant = (req, res) => {
    const tenantId = req.params.userId;

    Bill.findAll({
        where: { tenant_id: tenantId },
        include: ["unit"],
        order: [['due_date', 'DESC']]
    })
        .then(data => {
            res.send(data);
        })
        .catch(err => {
            res.status(500).send({
                message: err.message || "Some error occurred while retrieving bills."
            });
        });
};

exports.findAllByUnit = (req, res) => {
    const unitId = req.params.unitId;

    Bill.findAll({
        where: { unit_id: unitId },
        order: [['due_date', 'DESC']]
    })
        .then(data => {
            res.send(data);
        })
        .catch(err => {
            res.status(500).send({
                message: err.message || "Some error occurred while retrieving bills."
            });
        });
};

exports.markAsPaid = (req, res) => {
    const id = req.params.id;

    Bill.update({ status: 'paid' }, {
        where: { id: id }
    })
        .then(num => {
            if (num == 1) {
                res.send({
                    message: "Bill was updated successfully."
                });
            } else {
                res.send({
                    message: `Cannot update Bill with id=${id}. Maybe Bill was not found or req.body is empty!`
                });
            }
        })
        .catch(err => {
            res.status(500).send({
                message: "Error updating Bill with id=" + id
            });
        });
};
