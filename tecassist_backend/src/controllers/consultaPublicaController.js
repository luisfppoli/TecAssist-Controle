const servicoService = require("../services/servicoService");

async function consultarStatus(req, res) {
    try {
        res.set("Cache-Control", "no-store");

        const servico = await servicoService.consultarStatusPublico(
            req.body?.codigoConsulta
        );

        if (!servico) {
            return res.status(404).json({
                error: "Não encontramos um serviço com esse código. Confira e tente novamente.",
            });
        }

        return res.status(200).json({ servico });
    } catch (error) {
        return res.status(500).json({
            error: "Não foi possível consultar o serviço no momento.",
        });
    }
}

module.exports = { consultarStatus };
