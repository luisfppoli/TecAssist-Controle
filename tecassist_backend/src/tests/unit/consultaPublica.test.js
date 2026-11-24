jest.mock("../../repositories/servicoRepository", () => ({
    findByCodigoConsulta: jest.fn(),
}));

const servicoRepository = require("../../repositories/servicoRepository");
const servicoService = require("../../services/servicoService");

describe("Consulta pública de status", () => {
    beforeEach(() => {
        jest.clearAllMocks();
    });

    test("normaliza o código antes de consultar o repositório", async () => {
        const codigo = `TA-${"A".repeat(32)}`;
        const registro = {
            equipamento: "Televisão",
            marca: "Marca de teste",
            modelo: "Modelo de teste",
            status: "EM_ANALISE",
            createdAt: new Date("2026-11-16T10:00:00.000Z"),
        };
        servicoRepository.findByCodigoConsulta.mockResolvedValue(registro);

        const resultado = await servicoService.consultarStatusPublico(
            codigo.toLowerCase()
        );

        expect(servicoRepository.findByCodigoConsulta).toHaveBeenCalledWith(codigo);
        expect(resultado).toEqual(registro);
    });

    test("rejeita formato inválido sem consultar o banco", async () => {
        const resultado = await servicoService.consultarStatusPublico("TA2026.0001");

        expect(resultado).toBeNull();
        expect(servicoRepository.findByCodigoConsulta).not.toHaveBeenCalled();
    });

    test("retorna null quando o código aleatório não existe", async () => {
        servicoRepository.findByCodigoConsulta.mockResolvedValue(null);

        const resultado = await servicoService.consultarStatusPublico(
            `TA-${"B".repeat(32)}`
        );

        expect(resultado).toBeNull();
    });
});
