const prisma = require("../config/prisma");

function erroHttp(mensagem, statusCode) {
    const error = new Error(mensagem);
    error.statusCode = statusCode;
    return error;
}

async function buscarServico(servicoId) {
    const id = Number(servicoId);

    if (!Number.isInteger(id) || id <= 0) {
        throw erroHttp("Identificador do serviço inválido.", 400);
    }

    const servico = await prisma.servico.findUnique({
        where: { id },
        select: {
            id: true,
            codigo: true,
            equipamento: true,
            status: true,
            clienteId: true,
            cliente: {
                select: {
                    id: true,
                    nome: true,
                    telefone: true,
                },
            },
        },
    });

    if (!servico) {
        throw erroHttp("Serviço não encontrado.", 404);
    }

    return servico;
}

async function prepararWhatsApp(servicoId, mensagem) {
    if (typeof mensagem !== "string" || !mensagem.trim()) {
        throw erroHttp("A mensagem não pode ficar vazia.", 400);
    }

    if (mensagem.length > 4000) {
        throw erroHttp("A mensagem ultrapassa o limite permitido.", 400);
    }

    const servico = await buscarServico(servicoId);
    const telefone = servico.cliente?.telefone?.trim();

    if (!telefone) {
        throw erroHttp(
            "O cliente não possui telefone cadastrado.",
            422
        );
    }

    const notificacao = await prisma.notificacao.create({
        data: {
            mensagem: mensagem.trim(),
            status: "PREPARADA",
            tipo: "WHATSAPP",
            clienteId: servico.clienteId,
            servicoId: servico.id,
        },
    });

    return {
        notificacao,
        destinatario: {
            nome: servico.cliente.nome,
            telefone,
        },
    };
}

async function listarPorServico(servicoId) {
    const servico = await buscarServico(servicoId);

    return prisma.notificacao.findMany({
        where: {
            servicoId: servico.id,
        },
        orderBy: {
            createdAt: "desc",
        },
    });
}

async function marcarComoEnviada(notificacaoId) {
    const id = Number(notificacaoId);

    if (!Number.isInteger(id) || id <= 0) {
        throw erroHttp("Identificador da notificação inválido.", 400);
    }

    const notificacao = await prisma.notificacao.findUnique({
        where: { id },
    });

    if (!notificacao) {
        throw erroHttp("Notificação não encontrada.", 404);
    }

    if (notificacao.tipo !== "WHATSAPP") {
        throw erroHttp("Esta notificação não é uma mensagem de WhatsApp.", 409);
    }

    if (notificacao.status === "ENVIADA") {
        return notificacao;
    }

    if (notificacao.status !== "PREPARADA") {
        throw erroHttp("Esta notificação não pode ser marcada como enviada.", 409);
    }

    return prisma.notificacao.update({
        where: { id },
        data: {
            status: "ENVIADA",
        },
    });
}

module.exports = {
    prepararWhatsApp,
    listarPorServico,
    marcarComoEnviada,
};
