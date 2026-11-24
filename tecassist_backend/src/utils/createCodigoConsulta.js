const { randomBytes } = require("node:crypto");

function gerarCodigoConsulta() {
    const token = randomBytes(16).toString("hex").toUpperCase();
    return `TA-${token}`;
}

module.exports = gerarCodigoConsulta;
