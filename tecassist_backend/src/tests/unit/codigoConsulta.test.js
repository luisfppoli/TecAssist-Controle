const gerarCodigoConsulta = require("../../utils/createCodigoConsulta");

describe("Código de consulta pública", () => {
    test("gera código com prefixo TA e 32 caracteres hexadecimais", () => {
        const codigo = gerarCodigoConsulta();

        expect(codigo).toMatch(/^TA-[A-F0-9]{32}$/);
    });

    test("gera códigos diferentes para serviços distintos", () => {
        const codigos = new Set(
            Array.from({ length: 100 }, () => gerarCodigoConsulta())
        );

        expect(codigos.size).toBe(100);
    });
});
