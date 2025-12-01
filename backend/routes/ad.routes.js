module.exports = app => {
    const ads = require("../controllers/ad.controller.js");
    const { verifyToken } = require("../middleware/authJwt.js");

    var router = require("express").Router();

    // Create a new Ad
    router.post("/", [verifyToken], ads.create);

    // Retrieve all Ads
    router.get("/", ads.findAll);

    app.use('/api/ads', router);
};
