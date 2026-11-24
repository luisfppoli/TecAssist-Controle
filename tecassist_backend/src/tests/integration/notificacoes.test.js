const request = require("supertest");
const bcrypt = require("bcrypt");

const app = require("../../app");
const prisma = require("../../config/prisma");

let token;
let usuarioId;
let clienteId;
let servicoId;
let notificacaoId;

const identificador = `${Date.now()}-${Math.floor(Math.random() * 100000)}`;

describe("Comunicação com cliente via WhatsApp", () => {
    beforeAll(async () => {
        const senha = await bcrypt.hash("123456", 10);

        const usuario = await prisma.usuario.upsert({
            where: { email: "admin@teste.com" },
            update: { ativo: true },
            create: {
                nome: "Administrador de Teste",
                email: "admin@teste.com",
                senha,
                tipo: "ADMIN",
                ativo: true,
            },
        });

        usuarioId = usuario.id;

        const login = await request(app)
            .post("/auth/login")
            .send({
                email: "admin@teste.com",
                senha: "123456",
            });

        token = login.body.token;

        const cliente = await prisma.cliente.create({
            data: {
                nome: "Cliente WhatsApp Teste",
                telefone: "67999990000",
            },
        });

        clienteId = cliente.id;

        const servico = await prisma.servico.create({
            data: {
                codigo: `TESTE-WA-${identificador}`,
                equipamento: "Televisão de teste",
                status: "ABERTO",
                clienteId,
                usuarioId,
            },
        });

        servicoId = servico.id;
    });

    afterAll(async () => {
        if (notificacaoId) {
            await prisma.notificacao.deleteMany({
                where: { id: notificacaoId },
            });
        }

        if (servicoId) {
            await prisma.servico.deleteMany({
                where: { id: servicoId },
            });
        }

        if (clienteId) {
            await prisma.cliente.deleteMany({
                where: { id: clienteId },
            });
        }

        await prisma.$disconnect();
    });

    test("prepara mensagem, consulta histórico e marca como enviada", async () => {
        const mensagem =
            "Olá, Cliente WhatsApp Teste! O status do seu serviço foi atualizado.";

        const preparada = await request(app)
            .post(`/notificacoes/servico/${servicoId}/whatsapp`)
            .set("Authorization", `Bearer ${token}`)
            .send({ mensagem });

        expect(preparada.statusCode).toBe(201);
        expect(preparada.body.notificacao.status).toBe("PREPARADA");
        expect(preparada.body.notificacao.tipo).toBe("WHATSAPP");
        expect(preparada.body.notificacao.servicoId).toBe(servicoId);
        expect(preparada.body.destinatario.telefone).toBe("67999990000");

        notificacaoId = preparada.body.notificacao.id;

        const historico = await request(app)
            .get(`/notificacoes/servico/${servicoId}`)
            .set("Authorization", `Bearer ${token}`);

        expect(historico.statusCode).toBe(200);
        expect(historico.body).toHaveLength(1);
        expect(historico.body[0].id).toBe(notificacaoId);

        const enviada = await request(app)
            .patch(`/notificacoes/${notificacaoId}/status`)
            .set("Authorization", `Bearer ${token}`)
            .send({ status: "ENVIADA" });

        expect(enviada.statusCode).toBe(200);
        expect(enviada.body.notificacao.status).toBe("ENVIADA");
    });

    test("não prepara mensagem sem texto", async () => {
        const response = await request(app)
            .post(`/notificacoes/servico/${servicoId}/whatsapp`)
            .set("Authorization", `Bearer ${token}`)
            .send({ mensagem: "   " });

        expect(response.statusCode).toBe(400);
        expect(response.body.error).toBe("A mensagem não pode ficar vazia.");
    });
});
