const agendamentoService = require("../../services/agendamentoService");
const agendamentoRepository = require("../../repositories/agendamentoRepository");
const clienteRepository = require("../../repositories/clienteRepository");
const prisma = require("../../config/prisma");

jest.mock("../../repositories/agendamentoRepository");
jest.mock("../../repositories/clienteRepository");
jest.mock("../../config/prisma", () => ({
    $transaction: jest.fn(),
}));

describe("AgendamentoService", () => {

    afterEach(() => {
        jest.clearAllMocks();
    });

    test("Deve criar agendamento com sucesso", async () => {

        clienteRepository.findById.mockResolvedValue({
            id: 1
        });

        agendamentoRepository.create.mockResolvedValue({
            id: 1,
            status: "AGENDADO"
        });

        const resultado = await agendamentoService.create({
            descricao: "Troca de tela",
            data: "2030-12-10T10:00:00.000Z",
            clienteId: 1
        });

        expect(resultado.id).toBe(1);
        expect(resultado.status).toBe("AGENDADO");

    });

    test("Deve exigir descrição", async () => {

        await expect(
            agendamentoService.create({
                data: "2030-12-10T10:00:00.000Z",
                clienteId: 1
            })
        ).rejects.toThrow("Descrição é obrigatória");

    });

    test("Deve exigir data", async () => {

        await expect(
            agendamentoService.create({
                descricao: "Teste",
                clienteId: 1
            })
        ).rejects.toThrow("Data é obrigatória");

    });

    test("Deve impedir data passada", async () => {

        await expect(
            agendamentoService.create({
                descricao: "Teste",
                data: "2020-01-01T10:00:00.000Z",
                clienteId: 1
            })
        ).rejects.toThrow(
            "Não é possível agendar para uma data passada"
        );

    });

    test("Deve exigir cliente", async () => {

        await expect(
            agendamentoService.create({
                descricao: "Teste",
                data: "2030-12-10T10:00:00.000Z"
            })
        ).rejects.toThrow("Cliente é obrigatório");

    });

    test("Deve validar cliente existente", async () => {

        clienteRepository.findById.mockResolvedValue(null);

        await expect(
            agendamentoService.create({
                descricao: "Teste",
                data: "2030-12-10T10:00:00.000Z",
                clienteId: 999
            })
        ).rejects.toThrow("Cliente não encontrado");

    });

    test("Deve buscar agendamento por id", async () => {

        agendamentoRepository.findById.mockResolvedValue({
            id: 1
        });

        const resultado = await agendamentoService.findById(1);

        expect(resultado.id).toBe(1);

    });

    test("Deve lançar erro ao buscar agendamento inexistente", async () => {

        agendamentoRepository.findById.mockResolvedValue(null);

        await expect(
            agendamentoService.findById(999)
        ).rejects.toThrow("Agendamento não encontrado");

    });

    test("Deve atualizar agendamento", async () => {

        agendamentoRepository.findById.mockResolvedValue({
            id: 1
        });

        agendamentoRepository.update.mockResolvedValue({
            id: 1
        });

        const resultado = await agendamentoService.update(
            1,
            { descricao: "Nova descrição" }
        );

        expect(resultado.id).toBe(1);

    });

    test("Deve remover agendamento", async () => {

        agendamentoRepository.findById.mockResolvedValue({
            id: 1
        });

        agendamentoRepository.remove.mockResolvedValue({
            id: 1
        });

        const resultado = await agendamentoService.remove(1);

        expect(resultado.id).toBe(1);

    });

    test("Deve atualizar status", async () => {

        agendamentoRepository.update.mockResolvedValue({
            id: 1,
            status: "CONVERTIDO"
        });

        const resultado =
            await agendamentoService.atualizarStatus(
                1,
                "CONVERTIDO"
            );

        expect(resultado.status).toBe("CONVERTIDO");

    });

    test("Deve rejeitar status inválido", async () => {

        await expect(
            agendamentoService.atualizarStatus(
                1,
                "TESTE"
            )
        ).rejects.toThrow("Status inválido");

    });


    test("deve converter agendamento em serviço com código, status oficial e transação", async () => {
        const tx = {
            agendamento: {
                findUnique: jest.fn().mockResolvedValue({
                    id: 12,
                    clienteId: 8,
                    status: "AGENDADO",
                    servicos: [],
                }),
                updateMany: jest.fn().mockResolvedValue({ count: 1 }),
            },
            usuario: {
                findUnique: jest.fn().mockResolvedValue({ id: 4, ativo: true }),
            },
            servico: {
                create: jest.fn().mockResolvedValue({ id: 52 }),
                update: jest.fn().mockImplementation(({ data }) => ({
                    id: 52,
                    codigo: data.codigo,
                })),
                findUnique: jest.fn().mockResolvedValue({
                    id: 52,
                    codigo: `TA${new Date().getFullYear()}.0052`,
                    status: "ABERTO",
                }),
            },
        };

        prisma.$transaction.mockImplementation((callback) => callback(tx));

        const resultado = await agendamentoService.converterEmServico(12, 4, {
            equipamento: "Televisão",
            marca: "Samsung",
        });

        expect(resultado.status).toBe("ABERTO");
        expect(resultado.codigo).toBe(`TA${new Date().getFullYear()}.0052`);
        expect(tx.servico.create).toHaveBeenCalledWith(expect.objectContaining({
            data: expect.objectContaining({
                status: "ABERTO",
                clienteId: 8,
                usuarioId: 4,
                agendamentoId: 12,
            }),
            select: { id: true },
        }));
        expect(tx.servico.update).toHaveBeenCalledWith({
            where: { id: 52 },
            data: { codigo: `TA${new Date().getFullYear()}.0052` },
        });
        expect(tx.agendamento.updateMany).toHaveBeenCalledWith({
            where: { id: 12, status: "AGENDADO" },
            data: { status: "CONVERTIDO" },
        });
    });

    test("deve impedir conversão de agendamento que já possui serviço", async () => {
        const tx = {
            agendamento: {
                findUnique: jest.fn().mockResolvedValue({
                    id: 12,
                    clienteId: 8,
                    status: "CONVERTIDO",
                    servicos: [{ id: 52 }],
                }),
            },
            usuario: { findUnique: jest.fn() },
            servico: { create: jest.fn() },
        };

        prisma.$transaction.mockImplementation((callback) => callback(tx));

        await expect(
            agendamentoService.converterEmServico(12, 4, {
                equipamento: "Televisão",
            })
        ).rejects.toThrow("Este agendamento já foi convertido em serviço.");

        expect(tx.servico.create).not.toHaveBeenCalled();
    });

});