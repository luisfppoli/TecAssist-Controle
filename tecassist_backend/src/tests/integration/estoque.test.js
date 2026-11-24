const request = require("supertest");
const bcrypt = require("bcrypt");
const prisma = require("../../config/prisma");

const app = require("../../app");

let token;
let estoqueId;

describe("Fluxo Estoque", () => {

    beforeAll(async () => {

        const senhaHash = await bcrypt.hash("123456", 10);
        await prisma.usuario.upsert({
            where: { email: "admin@teste.com" },
            update: { ativo: true },
            create: {
                nome: "Administrador de Teste",
                email: "admin@teste.com",
                senha: senhaHash,
                tipo: "ADMIN",
                ativo: true,
            },
        });

        const login = await request(app)
            .post("/auth/login")
            .send({
                email: "admin@teste.com",
                senha: "123456"
            });

        token = login.body.token;

    });

    test("Criar item estoque", async () => {

        const response = await request(app)
            .post("/estoque")
            .set("Authorization", `Bearer ${token}`)
            .send({
                nome: "Capacitor",
                descricao: "Capacitor 2200uF",
                quantidade: 10,
                valor: 5,
                fornecedor: "Fornecedor Teste"
            });

        expect(response.statusCode).toBe(201);

        estoqueId = response.body.id;

    });

    test("Entrada estoque", async () => {

        const response = await request(app)
            .post(`/movimentacoes/entrada/${estoqueId}`)
            .set("Authorization", `Bearer ${token}`)
            .send({
                quantidade: 5
            });

        expect(response.statusCode).toBe(201);

    });

    test("Saída estoque", async () => {

        const response = await request(app)
            .post(`/movimentacoes/saida/${estoqueId}`)
            .set("Authorization", `Bearer ${token}`)
            .send({
                quantidade: 3
            });

        expect(response.statusCode).toBe(201);

    });

});