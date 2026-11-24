
const prisma = require("../config/prisma");
const agendamentoRepository = require("../repositories/agendamentoRepository");
const clienteRepository = require("../repositories/clienteRepository");
const gerarCodigo = require("../utils/createCodeServico");
const gerarCodigoConsulta = require("../utils/createCodigoConsulta");

async function create(data) {

    if (!data.descricao) {
        throw new Error("Descrição é obrigatória");
    }

    if (!data.data) {
        throw new Error("Data é obrigatória");
    }

    if (new Date(data.data) < new Date()) {
        throw new Error("Não é possível agendar para uma data passada");
    }

    if (!data.clienteId) {
        throw new Error("Cliente é obrigatório");
    }

    const cliente = await clienteRepository.findById(
        Number(data.clienteId)
    );

    if (!cliente) {
        throw new Error("Cliente não encontrado");
    }

    data.status = "AGENDADO";

    return agendamentoRepository.create(data);

}

async function findAll() {

    return agendamentoRepository.findAll();

}

async function findById(id) {

    const agendamento = await agendamentoRepository.findById(Number(id));

    if (!agendamento) {
        throw new Error("Agendamento não encontrado");
    }

    return agendamento;

}

async function update(id, data) {

    const agendamento = await agendamentoRepository.findById(Number(id));

    if (!agendamento) {
        throw new Error("Agendamento não encontrado");
    }

    return agendamentoRepository.update(
        Number(id),
        data
    );

}

async function remove(id) {

    const agendamento = await agendamentoRepository.findById(Number(id));

    if (!agendamento) {
        throw new Error("Agendamento não encontrado");
    }

    return agendamentoRepository.remove(
        Number(id)
    );

}

async function atualizarStatus(id, status) {

    const statusValidos = [
        "AGENDADO",
        "CONVERTIDO",
        "CANCELADO",
        "RETIRADO"
    ];

    if (!statusValidos.includes(status)) {
        throw new Error("Status inválido");
    }

    return agendamentoRepository.update(
        Number(id),
        { status }
    );
}

async function converterEmServico(agendamentoId, usuarioId, dados = {}) {

    const id = Number(agendamentoId);
    const responsavelId = Number(usuarioId);

    const equipamento =
        typeof dados.equipamento === "string"
            ? dados.equipamento.trim()
            : "";

    if (!Number.isInteger(id) || id <= 0) {
        const error = new Error("Identificador do agendamento inválido.");
        error.statusCode = 400;
        throw error;
    }

    if (!Number.isInteger(responsavelId) || responsavelId <= 0) {
        const error = new Error("Usuário responsável é obrigatório.");
        error.statusCode = 400;
        throw error;
    }

    if (!equipamento) {
        const error = new Error("Informe o equipamento.");
        error.statusCode = 400;
        throw error;
    }

    return prisma.$transaction(async (tx) => {

        const agendamento = await tx.agendamento.findUnique({
            where: { id },
            include: {
                servicos: {
                    select: { id: true },
                },
            },
        });

        if (!agendamento) {
            const error = new Error("Agendamento não encontrado.");
            error.statusCode = 404;
            throw error;
        }

        if (agendamento.status === "CANCELADO") {
            const error = new Error(
                "Um agendamento cancelado não pode ser convertido em serviço."
            );
            error.statusCode = 409;
            throw error;
        }

        if (agendamento.status === "CONVERTIDO" || agendamento.servicos.length > 0) {
            const error = new Error(
                "Este agendamento já foi convertido em serviço."
            );
            error.statusCode = 409;
            throw error;
        }

        if (agendamento.status !== "AGENDADO") {
            const error = new Error(
                "Somente agendamentos com status AGENDADO podem ser convertidos."
            );
            error.statusCode = 409;
            throw error;
        }

        const usuario = await tx.usuario.findUnique({
            where: { id: responsavelId },
            select: {
                id: true,
                ativo: true,
            },
        });

        if (!usuario || !usuario.ativo) {
            const error = new Error(
                "Usuário responsável não encontrado ou desativado."
            );
            error.statusCode = 404;
            throw error;
        }

        const reservaConversao = await tx.agendamento.updateMany({
            where: {
                id: agendamento.id,
                status: "AGENDADO",
            },
            data: { status: "CONVERTIDO" },
        });

        if (reservaConversao.count !== 1) {
            const error = new Error(
                "Este agendamento já foi convertido ou não está mais disponível."
            );
            error.statusCode = 409;
            throw error;
        }

        const novoServico = await tx.servico.create({
            data: {
                equipamento,
                marca: dados.marca?.trim() || null,
                modelo: dados.modelo?.trim() || null,
                problema: dados.problema?.trim() || null,

                status: "ABERTO",

                // Código público para consulta do cliente
                codigoConsulta: gerarCodigoConsulta(),

                clienteId: agendamento.clienteId,
                usuarioId: responsavelId,
                agendamentoId: agendamento.id,
            },
            select: { id: true },
        });

        // Gera o código interno do serviço
        const codigo = gerarCodigo(novoServico.id);

        await tx.servico.update({
            where: { id: novoServico.id },
            data: { codigo },
        });

        return tx.servico.findUnique({
            where: { id: novoServico.id },
            include: {
                cliente: true,
                usuario: {
                    select: {
                        id: true,
                        nome: true,
                        email: true,
                        tipo: true,
                    },
                },
                agendamento: true,
                pecas: {
                    include: { estoque: true },
                },
            },
        });

    });
}

module.exports = {
    create,
    findAll,
    findById,
    update,
    converterEmServico,
    remove,
    atualizarStatus
};