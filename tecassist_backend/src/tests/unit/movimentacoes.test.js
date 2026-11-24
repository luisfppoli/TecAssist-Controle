const movimentacaoService = require("../../services/movimentacaoService");
const movimentacaoRepository = require("../../repositories/movimentacaoRepository");
const prisma = require("../../config/prisma");

jest.mock("../../repositories/movimentacaoRepository");
jest.mock("../../config/prisma", () => ({
    $transaction: jest.fn(),
}));

function configurarTransacao({ itemExiste = true, quantidadeAtualizada = 1 } = {}) {
    const tx = {
        estoque: {
            findUnique: jest.fn().mockResolvedValue(itemExiste ? { id: 1 } : null),
            update: jest.fn().mockResolvedValue({ id: 1, quantidade: 15 }),
            updateMany: jest.fn().mockResolvedValue({ count: quantidadeAtualizada }),
        },
        movimentacaoEstoque: {
            create: jest.fn().mockResolvedValue({ id: 1, tipo: "ENTRADA" }),
        },
    };

    prisma.$transaction.mockImplementation((callback) => callback(tx));
    return tx;
}

describe("movimentacaoService", () => {
    beforeEach(() => jest.clearAllMocks());

    test("deve realizar entrada de estoque e registrar movimento na mesma transação", async () => {
        const tx = configurarTransacao();

        const resultado = await movimentacaoService.entrada(1, 5);

        expect(tx.estoque.update).toHaveBeenCalledWith({
            where: { id: 1 },
            data: { quantidade: { increment: 5 } },
        });
        expect(tx.movimentacaoEstoque.create).toHaveBeenCalledWith({
            data: { tipo: "ENTRADA", quantidade: 5, estoqueId: 1 },
            include: { estoque: true },
        });
        expect(resultado.tipo).toBe("ENTRADA");
    });

    test("deve rejeitar entrada em item inexistente", async () => {
        configurarTransacao({ itemExiste: false });

        await expect(movimentacaoService.entrada(999, 5)).rejects.toThrow(
            "Item não encontrado"
        );
    });

    test("deve realizar saída de estoque e registrar movimento na mesma transação", async () => {
        const tx = configurarTransacao();
        tx.movimentacaoEstoque.create.mockResolvedValue({ id: 2, tipo: "SAIDA" });

        const resultado = await movimentacaoService.saida(1, 3);

        expect(tx.estoque.updateMany).toHaveBeenCalledWith({
            where: { id: 1, quantidade: { gte: 3 } },
            data: { quantidade: { decrement: 3 } },
        });
        expect(resultado.tipo).toBe("SAIDA");
    });

    test("deve rejeitar saída de item inexistente", async () => {
        configurarTransacao({ itemExiste: false });

        await expect(movimentacaoService.saida(999, 1)).rejects.toThrow(
            "Item não encontrado"
        );
    });

    test("deve rejeitar saída com estoque insuficiente", async () => {
        configurarTransacao({ quantidadeAtualizada: 0 });

        await expect(movimentacaoService.saida(1, 50)).rejects.toThrow(
            "Quantidade insuficiente"
        );
    });

    test("deve validar quantidades inválidas", async () => {
        await expect(movimentacaoService.entrada(1, 0)).rejects.toThrow(
            "A quantidade deve ser um número inteiro maior que zero."
        );
        expect(prisma.$transaction).not.toHaveBeenCalled();
    });

    test("deve retornar histórico", async () => {
        movimentacaoRepository.findAll.mockResolvedValue([
            { id: 1, tipo: "ENTRADA" },
        ]);

        const resultado = await movimentacaoService.historico();

        expect(resultado).toHaveLength(1);
        expect(movimentacaoRepository.findAll).toHaveBeenCalled();
    });
});
