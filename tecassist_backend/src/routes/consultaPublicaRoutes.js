const express = require("express");
const controller = require("../controllers/consultaPublicaController");

const router = express.Router();

router.post("/", controller.consultarStatus);

module.exports = router;
