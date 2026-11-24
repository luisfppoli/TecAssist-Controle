const servicoService = require("../../services/servicoService");
const servicoRepository = require("../../repositories/servicoRepository");
const prisma = require("../../config/prisma");

jest.mock("../../repositories/servicoRepository");
jest.mock("../../config/prisma", () => ({
    cliente: { findUnique: jest.fn() },
    usuario: { findUnique: jest.fn() },
    servico: { update: jest.fn() },
    $transaction: jest.fn(),
}));

function configurarTransacao({
    servicoEncontrado = { id: 1, status: "ABERTO" },
    estoqueEncontrado = { id: 1, quantidade: 10 },
    quantidadeAtualizada = 1,
} = {}) {
    const tx = {
        servico: {
            findUnique: jest.fn().mockResolvedValue(servicoEncontrado),
        },
        estoque: {
            findUnique: jest.fn().mockResolvedValue(estoqueEncontrado),
            updateMany: jest.fn().mockResolvedValue({ count: quantidadeAtualizada }),
        },
        servicoPeca: {
            create: jest.fn().mockResolvedValue({ id: 1 }),
        },
        movimentacaoEstoque: {
            create: jest.fn().mockResolvedValue({ id: 1, tipo: "SAIDA" }),
        },
    };

    prisma.$transaction.mockImplementation((callback) => callback(tx));
    return tx;
}

describe("ServicoService", () => {
    afterEach(() => {
        jest.clearAllMocks();
    });

    test("deve exigir equipamento", async () => {
        await expect(servicoService.create({})).rejects.toThrow(
            "Equipamento é obrigatório"
        );
    });

    test("deve exigir cliente", async () => {
        await expect(
            servicoService.create({ equipamento: "TV" })
        ).rejects.toThrow("Cliente é obrigatório");
    });

    test("deve exigir usuário responsável", async () => {
        await expect(
            servicoService.create({ equipamento: "TV", clienteId: 1 })
        ).rejects.toThrow("Usuário responsável é obrigatório");
    });

    test("deve validar cliente existente", async () => {
        prisma.cliente.findUnique.mockResolvedValue(null);

        await expect(
            servicoService.create({
                equipamento: "TV",
                clienteId: 1,
                usuarioId: 1,
            })
        ).rejects.toThrow("Cliente não encontrado");
    });

    test("deve validar usuário existente", async () => {
        prisma.cliente.findUnique.mockResolvedValue({ id: 1 });
        prisma.usuario.findUnique.mockResolvedValue(null);

        await expect(
            servicoService.create({
                equipamento: "TV",
                clienteId: 1,
                usuarioId: 1,
            })
        ).rejects.toThrow("Usuário não encontrado");
    });

    test("deve buscar serviço por ID", async () => {
        servicoRepository.findById.mockResolvedValue({ id: 1 });

        const resultado = await servicoService.findById(1);

        expect(resultado.id).toBe(1);
    });

    test("deve lançar erro quando serviço não existir", async () => {
        servicoRepository.findById.mockResolvedValue(null);

        await expect(servicoService.findById(999)).rejects.toThrow(
            "Serviço não encontrado"
        );
    });

    test("deve aceitar os status oficiais usados pelo Flutter", async () => {
        servicoRepository.update.mockResolvedValue({ status: "CONCLUIDO" });

        const resultado = await servicoService.atualizarStatus(1, "CONCLUIDO");

        expect(resultado.status).toBe("CONCLUIDO");
        expect(servicoRepository.update).toHaveBeenCalledWith(1, {
            status: "CONCLUIDO",
        });
    });

    test("deve rejeitar status que não fazem parte da lista oficial", async () => {
        await expect(
            servicoService.atualizarStatus(1, "PRONTO")
        ).rejects.toThrow("Status inválido");
    });

    test("deve permitir salvar um serviço antigo sem trocar seu status legado", async () => {
        servicoRepository.findById.mockResolvedValue({
            id: 1,
            status: "PRONTO",
        });
        servicoRepository.update.mockResolvedValue({
            id: 1,
            status: "PRONTO",
        });

        const resultado = await servicoService.update(1, {
            status: "PRONTO",
            equipamento: "TV",
        });

        expect(resultado.status).toBe("PRONTO");
    });

    test("deve rejeitar status legado quando for uma nova alteração", async () => {
        servicoRepository.findById.mockResolvedValue({
            id: 1,
            status: "ABERTO",
        });

        await expect(
            servicoService.update(1, { status: "PRONTO" })
        ).rejects.toThrow("Status inválido");
    });

    test("deve validar serviço existente ao adicionar peça", async () => {
        configurarTransacao({ servicoEncontrado: null });

        await expect(servicoService.adicionarPeca(1, 1, 2)).rejects.toThrow(
            "Serviço não encontrado."
        );
    });

    test("deve validar peça existente ao adicionar peça", async () => {
        configurarTransacao({ estoqueEncontrado: null });

        await expect(servicoService.adicionarPeca(1, 1, 2)).rejects.toThrow(
            "Peça não encontrada no estoque."
        );
    });

    test("deve rejeitar quantidade acima do estoque", async () => {
        configurarTransacao({ quantidadeAtualizada: 0 });

        await expect(servicoService.adicionarPeca(1, 1, 20)).rejects.toThrow(
            "Quantidade insuficiente no estoque."
        );
    });

    test("deve adicionar peça com a assinatura atual de três parâmetros", async () => {
        const tx = configurarTransacao();

        const resultado = await servicoService.adicionarPeca(1, 1, 2);

        expect(resultado.id).toBe(1);
        expect(tx.estoque.updateMany).toHaveBeenCalledWith({
            where: { id: 1, quantidade: { gte: 2 } },
            data: { quantidade: { decrement: 2 } },
        });
        expect(tx.movimentacaoEstoque.create).toHaveBeenCalledWith(
            expect.objectContaining({
                data: { tipo: "SAIDA", quantidade: 2, estoqueId: 1 },
            })
        );
    });
});
