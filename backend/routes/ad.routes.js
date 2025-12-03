module.exports = app => {
    const ads = require("../controllers/ad.controller.js");
    const { verifyToken } = require("../middleware/authJwt.js");

    const upload = require("../services/upload.service");

    var router = require("express").Router();

    // Create a new Ad
    router.post("/", [verifyToken, upload.single('image')], ads.create);

    // Retrieve all Ads
    router.get("/", ads.findAll);

    // Delete an Ad
    router.delete("/:id", [verifyToken], ads.delete);

    app.use('/api/ads', router);
};
