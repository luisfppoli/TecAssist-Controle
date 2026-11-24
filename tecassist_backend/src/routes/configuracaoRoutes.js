const express = require("express");
const router = express.Router();

const configuracaoController = require("../controllers/configuracaoController");
const authMiddleware = require("../middlewares/authMiddleware");
const roleMiddleware = require("../middlewares/roleMiddleware");

router.use(authMiddleware);
router.get("/", configuracaoController.buscar);
router.put("/", roleMiddleware("ADMIN"), configuracaoController.salvar);

module.exports = router;
