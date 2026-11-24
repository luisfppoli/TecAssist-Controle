const configuracaoService = require("../services/configuracaoService");

async function buscar(req, res) {
  try {
    const configuracao = await configuracaoService.buscar();
    return res.status(200).json(configuracao);
  } catch (error) {
    return res.status(error.statusCode || 500).json({
      error: error.message || "Não foi possível carregar as configurações.",
    });
  }
}

async function salvar(req, res) {
  try {
    const configuracao = await configuracaoService.salvar(req.body || {});
    return res.status(200).json(configuracao);
  } catch (error) {
    return res.status(error.statusCode || 500).json({
      error: error.message || "Não foi possível salvar as configurações.",
    });
  }
}

module.exports = { buscar, salvar };
