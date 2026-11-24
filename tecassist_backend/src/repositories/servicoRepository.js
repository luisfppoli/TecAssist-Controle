const prisma = require("../config/prisma");

const usuarioPublico = {
    id: true,
    nome: true,
    email: true,
    tipo: true,
};

const relacionamentosServico = {
    cliente: true,
    usuario: {
        select: usuarioPublico,
    },
    agendamento: true,
};

async function create(data) {
    return prisma.servico.create({
        data,
        include: relacionamentosServico,
    });
}

async function findAll() {
    return prisma.servico.findMany({
        include: {
            ...relacionamentosServico,
            pecas: {
                include: {
                    estoque: true,
                },
            },
        },
    });
}

async function findById(id) {
    return prisma.servico.findUnique({
        where: { id },
        include: {
            ...relacionamentosServico,
            pecas: {
                include: {
                    estoque: true,
                },
            },
        },
    });
}

async function findByCodigo(codigo) {
    return prisma.servico.findUnique({
        where: { codigo },
    });
}

async function findByCodigoConsulta(codigoConsulta) {
    return prisma.servico.findUnique({
        where: { codigoConsulta },
        select: {
            equipamento: true,
            marca: true,
            modelo: true,
            status: true,
            createdAt: true,
        },
    });
}

async function update(id, data) {
    return prisma.servico.update({
        where: { id },
        data,
    });
}

async function remove(id, transaction = prisma) {
    return transaction.servico.delete({
        where: {
            id
        }
    });
}

module.exports = {
    create,
    findAll,
    findById,
    findByCodigo,
    findByCodigoConsulta,
    update,
    remove,
};