const request = require("supertest");
const bcrypt = require("bcrypt");
const { randomUUID } = require("node:crypto");

const app = require("../../app");
const prisma = require("../../config/prisma");
const gerarCodigoConsulta = require("../../utils/createCodigoConsulta");

let clienteId;
let servicoId;
let codigoConsulta;

const identificador = randomUUID();

describe("Consulta pública do status do serviço", () => {
    beforeAll(async () => {
        const senha = await bcrypt.hash("123456", 10);

        const usuario = await prisma.usuario.upsert({
            where: { email: "admin@teste.com" },
            update: {},
            create: {
                nome: "Administrador de Teste",
                email: "admin@teste.com",
                senha,
                tipo: "ADMIN",
            },
        });

        const cliente = await prisma.cliente.create({
            data: {
                nome: `Cliente Consulta ${identificador}`,
                telefone: "67999990000",
            },
        });
        clienteId = cliente.id;
        codigoConsulta = gerarCodigoConsulta();

        const servico = await prisma.servico.create({
            data: {
                codigo: `TESTE-${identificador}`,
                codigoConsulta,
                equipamento: "Televisão de teste",
                marca: "Marca de teste",
                modelo: "Modelo de teste",
                problema: "Não liga",
                status: "ABERTO",
                clienteId,
                usuarioId: usuario.id,
            },
        });
        servicoId = servico.id;
    });

    afterAll(async () => {
        if (servicoId) {
            await prisma.servico.deleteMany({ where: { id: servicoId } });
        }
        if (clienteId) {
            await prisma.cliente.deleteMany({ where: { id: clienteId } });
        }
        await prisma.$disconnect();
    });

    test("consulta o status sem exigir login e sem retornar dados pessoais", async () => {
        const response = await request(app)
            .post("/consulta-publica")
            .send({ codigoConsulta: codigoConsulta.toLowerCase() });

        expect(response.statusCode).toBe(200);
        expect(response.headers["cache-control"]).toBe("no-store");
        expect(response.body.servico).toMatchObject({
            equipamento: "Televisão de teste",
            marca: "Marca de teste",
            modelo: "Modelo de teste",
            status: "ABERTO",
        });
        expect(Object.keys(response.body.servico).sort()).toEqual([
            "createdAt",
            "equipamento",
            "marca",
            "modelo",
            "status",
        ]);
        expect(response.body.servico).not.toHaveProperty("cliente");
        expect(response.body.servico).not.toHaveProperty("clienteId");
    });

    test("retorna o status atualizado do serviço", async () => {
        await prisma.servico.update({
            where: { id: servicoId },
            data: { status: "PRONTO" },
        });

        const response = await request(app)
            .post("/consulta-publica")
            .send({ codigoConsulta });

        expect(response.statusCode).toBe(200);
        expect(response.body.servico.status).toBe("PRONTO");
    });

    test("não aceita o código sequencial interno", async () => {
        const response = await request(app)
            .post("/consulta-publica")
            .send({ codigoConsulta: "TA2026.0001" });

        expect(response.statusCode).toBe(404);
        expect(response.body).toHaveProperty("error");
    });

    test("retorna erro genérico para código aleatório inexistente", async () => {
        const response = await request(app)
            .post("/consulta-publica")
            .send({ codigoConsulta: gerarCodigoConsulta() });

        expect(response.statusCode).toBe(404);
        expect(response.body).toHaveProperty("error");
    });
});
