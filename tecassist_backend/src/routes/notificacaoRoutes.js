const express = require("express");

const router = express.Router();

const notificacaoController = require("../controllers/notificacaoController");
const authMiddleware = require("../middlewares/authMiddleware");

router.use(authMiddleware);

router.get("/servico/:servicoId", notificacaoController.listarPorServico);
router.post("/servico/:servicoId/whatsapp", notificacaoController.prepararWhatsApp);
router.patch("/:id/status", notificacaoController.marcarComoEnviada);

module.exports = router;
