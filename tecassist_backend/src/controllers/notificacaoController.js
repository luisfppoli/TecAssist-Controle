const notificacaoService = require("../services/notificacaoService");

async function prepararWhatsApp(req, res) {
    try {
        const resultado = await notificacaoService.prepararWhatsApp(
            req.params.servicoId,
            req.body.mensagem
        );

        return res.status(201).json(resultado);
    } catch (error) {
        return res.status(error.statusCode || 500).json({
            error: error.message || "Não foi possível preparar a mensagem.",
        });
    }
}

async function listarPorServico(req, res) {
    try {
        const notificacoes = await notificacaoService.listarPorServico(
            req.params.servicoId
        );

        return res.status(200).json(notificacoes);
    } catch (error) {
        return res.status(error.statusCode || 500).json({
            error: error.message || "Não foi possível carregar as notificações.",
        });
    }
}

async function marcarComoEnviada(req, res) {
    try {
        const notificacao = await notificacaoService.marcarComoEnviada(
            req.params.id
        );

        return res.status(200).json({
            message: "Notificação marcada como enviada.",
            notificacao,
        });
    } catch (error) {
        return res.status(error.statusCode || 500).json({
            error: error.message || "Não foi possível atualizar a notificação.",
        });
    }
}

module.exports = {
    prepararWhatsApp,
    listarPorServico,
    marcarComoEnviada,
};
