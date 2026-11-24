const prisma = require("../config/prisma");
const servicoRepository = require("../repositories/servicoRepository");
const gerarCodigo = require("../utils/createCodeServico");
const gerarCodigoConsulta = require("../utils/createCodigoConsulta");

const STATUS_SERVICO_VALIDOS = Object.freeze([
    "ABERTO",
    "EM_ANDAMENTO",
    "AGUARDANDO_PECA",
    "CONCLUIDO",
    "ENTREGUE",
    "CANCELADO",
]);

const STATUS_LEGADOS = new Set([
    "EM_ANALISE",
    "EM_MANUTENCAO",
    "PRONTO",
]);

function erroHttp(mensagem, statusCode) {
    const error = new Error(mensagem);
    error.statusCode = statusCode;
    return error;
}

async function create(data) {

    if (!data.equipamento) {
        throw new Error("Equipamento é obrigatório");
    }

    if (!data.clienteId) {
        throw new Error("Cliente é obrigatório");
    }

    if (!data.usuarioId) {
        throw new Error("Usuário responsável é obrigatório");
    }

    const cliente = await prisma.cliente.findUnique({
        where: { id: Number(data.clienteId) }
    });

    if (!cliente) {
        throw new Error("Cliente não encontrado");
    }

    const usuario = await prisma.usuario.findUnique({
        where: { id: Number(data.usuarioId) }
    });

    if (!usuario) {
        throw new Error("Usuário não encontrado");
    }

    data.status = "ABERTO";
    data.codigoConsulta = gerarCodigoConsulta();

    const servico = await servicoRepository.create(data);

    const codigo = gerarCodigo(servico.id);

    await prisma.servico.update({
        where: { id: servico.id },
        data: { codigo }
    });

    return servicoRepository.findById(servico.id);

}

async function findAll() {

    return servicoRepository.findAll();
}

async function findById(id) {

    const servico = await servicoRepository.findById(
        Number(id)
    );

    if (!servico) {
        throw new Error("Serviço não encontrado");
    }

    return servico;
}

async function consultarStatusPublico(codigoConsulta) {
    if (typeof codigoConsulta !== "string") {
        return null;
    }

    const codigoNormalizado = codigoConsulta.trim().toUpperCase();

    if (!/^TA-[A-F0-9]{32}$/.test(codigoNormalizado)) {
        return null;
    }

    return servicoRepository.findByCodigoConsulta(codigoNormalizado);
}

async function update(id, data) {
    const servicoId = Number(id);
    const dadosAtualizados = { ...data };

    if (dadosAtualizados.status !== undefined) {
        const status = String(dadosAtualizados.status).trim().toUpperCase();

        if (!STATUS_SERVICO_VALIDOS.includes(status)) {
            if (STATUS_LEGADOS.has(status)) {
                const atual = await servicoRepository.findById(servicoId);

                if (!atual || atual.status.toUpperCase() !== status) {
                    throw erroHttp("Status inválido", 400);
                }
            } else {
                throw erroHttp("Status inválido", 400);
            }
        }

        dadosAtualizados.status = status;
    }

    return servicoRepository.update(servicoId, dadosAtualizados);
}

async function remove(id) {
    const idServico = Number(id);

    if (!Number.isInteger(idServico) || idServico <= 0) {
        throw erroHttp("Identificador do serviço inválido.", 400);
    }

    try {
        return await prisma.$transaction(async (tx) => {

            const servico = await tx.servico.findUnique({
                where: {
                    id: idServico
                },
                select: {
                    id: true,
                    codigo: true,
                    pecas: {
                        select: {
                            id: true,
                            estoqueId: true,
                            quantidade: true
                        }
                    }
                }
            });

            if (!servico) {
                throw erroHttp("Serviço não encontrado.", 404);
            }

            let unidadesDevolvidas = 0;

            for (const vinculo of servico.pecas) {

                const atualizacao = await tx.estoque.updateMany({
                    where: {
                        id: vinculo.estoqueId
                    },
                    data: {
                        quantidade: {
                            increment: vinculo.quantidade
                        }
                    }
                });

                if (atualizacao.count !== 1) {
                    throw erroHttp(
                        "Uma das peças vinculadas não foi encontrada no estoque. Nenhuma alteração foi realizada.",
                        409
                    );
                }

                await tx.movimentacaoEstoque.create({
                    data: {
                        tipo: "ENTRADA",
                        quantidade: vinculo.quantidade,
                        estoqueId: vinculo.estoqueId
                    }
                });

                unidadesDevolvidas += vinculo.quantidade;
            }

            const vinculosRemovidos = await tx.servicoPeca.deleteMany({
                where: {
                    servicoId: idServico
                }
            });

            if (vinculosRemovidos.count !== servico.pecas.length) {
                throw erroHttp(
                    "Os vínculos das peças foram alterados durante a operação. Atualize a tela e tente novamente.",
                    409
                );
            }

            await servicoRepository.remove(idServico, tx);

            return {
                message: "Serviço excluído e peças devolvidas ao estoque com sucesso.",
                servicoId: idServico,
                codigo: servico.codigo,
                pecasDevolvidas: servico.pecas.length,
                unidadesDevolvidas
            };
        });

    } catch (error) {

        if (error.statusCode) {
            throw error;
        }

        if (error.code === "P2025") {
            throw erroHttp(
                "O serviço não foi encontrado ou já foi excluído.",
                404
            );
        }

        if (error.code === "P2003") {
            throw erroHttp(
                "Não foi possível excluir o serviço porque ainda existem registros vinculados. Nenhuma alteração foi realizada.",
                409
            );
        }

        console.error("Erro ao excluir serviço:", error);

        throw erroHttp(
            "Ocorreu um problema ao excluir o serviço. Nenhuma alteração foi realizada. Tente novamente.",
            500
        );
    }
}

async function atualizarStatus(id, status) {
    const statusNormalizado =
        typeof status === "string" ? status.trim().toUpperCase() : "";

    if (!STATUS_SERVICO_VALIDOS.includes(statusNormalizado)) {
        throw erroHttp("Status inválido", 400);
    }

    return servicoRepository.update(
        Number(id),
        { status: statusNormalizado }
    );
}

async function adicionarPeca(
    servicoId,
    estoqueId,
    quantidade
) {
    const idServico = Number(servicoId);
    const idEstoque = Number(estoqueId);
    const qtd = Number(quantidade);

    if (
        !Number.isInteger(idServico) ||
        idServico <= 0 ||
        !Number.isInteger(idEstoque) ||
        idEstoque <= 0 ||
        !Number.isInteger(qtd) ||
        qtd <= 0
    ) {
        throw erroHttp(
            "Serviço, peça e quantidade precisam ser válidos.",
            400
        );
    }

    return prisma.$transaction(async (tx) => {
        const servico = await tx.servico.findUnique({
            where: {
                id: idServico,
            },
            select: {
                id: true,
                status: true,
            },
        });

        if (!servico) {
            throw erroHttp(
                "Serviço não encontrado.",
                404
            );
        }

        const status = servico.status.toUpperCase();

        if (
            status === "CANCELADO" ||
            status === "ENTREGUE" ||
            status === "FINALIZADO"
        ) {
            throw erroHttp(
                "Não é possível adicionar peças a um serviço encerrado.",
                409
            );
        }

        const estoque = await tx.estoque.findUnique({
            where: {
                id: idEstoque,
            },
            select: {
                id: true,
                quantidade: true,
            },
        });

        if (!estoque) {
            throw erroHttp(
                "Peça não encontrada no estoque.",
                404
            );
        }

        const atualizacao = await tx.estoque.updateMany({
            where: {
                id: idEstoque,
                quantidade: {
                    gte: qtd,
                },
            },
            data: {
                quantidade: {
                    decrement: qtd,
                },
            },
        });

        if (atualizacao.count !== 1) {
            throw erroHttp(
                "Quantidade insuficiente no estoque.",
                409
            );
        }

        const vinculo = await tx.servicoPeca.create({
            data: {
                servicoId: idServico,
                estoqueId: idEstoque,
                quantidade: qtd,
            },
            include: {
                estoque: {
                    select: {
                        id: true,
                        nome: true,
                        descricao: true,
                        valor: true,
                        quantidade: true,
                    },
                },
            },
        });

        await tx.movimentacaoEstoque.create({
            data: {
                tipo: "SAIDA",
                quantidade: qtd,
                estoqueId: idEstoque,
            },
        });

        return vinculo;
    });
}

async function removerPeca(
    servicoId,
    servicoPecaId
) {
    const idServico = Number(servicoId);
    const idVinculo = Number(servicoPecaId);

    if (
        !Number.isInteger(idServico) ||
        idServico <= 0 ||
        !Number.isInteger(idVinculo) ||
        idVinculo <= 0
    ) {
        throw erroHttp(
            "Serviço ou vínculo de peça inválido.",
            400
        );
    }

    return prisma.$transaction(async (tx) => {
        const vinculo = await tx.servicoPeca.findFirst({
            where: {
                id: idVinculo,
                servicoId: idServico,
            },
            include: {
                servico: {
                    select: {
                        id: true,
                        status: true,
                    },
                },
            },
        });

        if (!vinculo) {
            throw erroHttp(
                "Peça não encontrada neste serviço.",
                404
            );
        }

        const status = vinculo.servico.status.toUpperCase();

        if (
            status === "CANCELADO" ||
            status === "ENTREGUE" ||
            status === "FINALIZADO"
        ) {
            throw erroHttp(
                "Não é possível alterar peças de um serviço encerrado.",
                409
            );
        }

        await tx.estoque.update({
            where: {
                id: vinculo.estoqueId,
            },
            data: {
                quantidade: {
                    increment: vinculo.quantidade,
                },
            },
        });

        await tx.movimentacaoEstoque.create({
            data: {
                tipo: "ENTRADA",
                quantidade: vinculo.quantidade,
                estoqueId: vinculo.estoqueId,
            },
        });

        await tx.servicoPeca.delete({
            where: {
                id: vinculo.id,
            },
        });

        return {
            message: "Peça devolvida ao estoque.",
            servicoId: idServico,
            estoqueId: vinculo.estoqueId,
            quantidade: vinculo.quantidade,
        };
    });
}

module.exports = {
    create,
    findAll,
    findById,
    consultarStatusPublico,
    update,
    remove,
    atualizarStatus,
    adicionarPeca,
    removerPeca
};