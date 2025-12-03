const { verifyToken, isLandlord } = require("../middleware/authJwt");
const controller = require("../controllers/property.controller");

const upload = require("../services/upload.service");

module.exports = function (app) {
    app.use(function (req, res, next) {
        res.header(
            "Access-Control-Allow-Headers",
            "x-access-token, Origin, Content-Type, Accept"
        );
        next();
    });

    app.post(
        "/api/properties",
        [verifyToken, isLandlord, upload.single('image')],
        controller.create
    );

    app.get(
        "/api/properties",
        [verifyToken],
        controller.findAll
    );

    app.get(
        "/api/properties/:id",
        [verifyToken],
        controller.findOne
    );
};
