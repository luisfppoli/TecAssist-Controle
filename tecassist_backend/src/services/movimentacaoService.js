const prisma = require("../config/prisma");
const movimentacaoRepository = require("../repositories/movimentacaoRepository");

function validarEntrada(estoqueId, quantidade) {
    const id = Number(estoqueId);
    const qtd = Number(quantidade);

    if (!Number.isInteger(id) || id <= 0) {
        throw new Error("ID do item inválido.");
    }

    if (!Number.isInteger(qtd) || qtd <= 0) {
        throw new Error("A quantidade deve ser um número inteiro maior que zero.");
    }

    return { id, qtd };
}

async function entrada(estoqueId, quantidade) {
    const { id, qtd } = validarEntrada(estoqueId, quantidade);

    return prisma.$transaction(async (tx) => {
        const item = await tx.estoque.findUnique({
            where: { id },
            select: { id: true },
        });

        if (!item) {
            throw new Error("Item não encontrado");
        }

        await tx.estoque.update({
            where: { id },
            data: {
                quantidade: { increment: qtd },
            },
        });

        return tx.movimentacaoEstoque.create({
            data: {
                tipo: "ENTRADA",
                quantidade: qtd,
                estoqueId: id,
            },
            include: { estoque: true },
        });
    });
}

async function saida(estoqueId, quantidade) {
    const { id, qtd } = validarEntrada(estoqueId, quantidade);

    return prisma.$transaction(async (tx) => {
        const item = await tx.estoque.findUnique({
            where: { id },
            select: { id: true },
        });

        if (!item) {
            throw new Error("Item não encontrado");
        }

        // A condição evita saldo negativo mesmo com duas saídas simultâneas.
        const atualizacao = await tx.estoque.updateMany({
            where: {
                id,
                quantidade: { gte: qtd },
            },
            data: {
                quantidade: { decrement: qtd },
            },
        });

        if (atualizacao.count !== 1) {
            throw new Error("Quantidade insuficiente");
        }

        return tx.movimentacaoEstoque.create({
            data: {
                tipo: "SAIDA",
                quantidade: qtd,
                estoqueId: id,
            },
            include: { estoque: true },
        });
    });
}

async function historico() {
    return movimentacaoRepository.findAll();
}

module.exports = {
    entrada,
    saida,
    historico,
};
