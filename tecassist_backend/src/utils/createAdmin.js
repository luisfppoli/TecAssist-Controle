const bcrypt = require("bcrypt");
const prisma = require("../config/prisma");

async function createAdmin() {
    const email = process.env.ADMIN_EMAIL?.trim().toLowerCase();
    const senha = process.env.ADMIN_PASSWORD;
    const nome = process.env.ADMIN_NAME?.trim() || "Administrador";

    // Sem credenciais explícitas, não cria uma conta padrão conhecida.
    if (!email || !senha) {
        console.warn(
            "Criação automática do administrador ignorada: configure ADMIN_EMAIL e ADMIN_PASSWORD no .env."
        );
        return null;
    }

    if (senha.length < 12) {
        throw new Error(
            "ADMIN_PASSWORD deve possuir pelo menos 12 caracteres."
        );
    }

    const adminExiste = await prisma.usuario.findUnique({
        where: { email },
        select: { id: true },
    });

    if (adminExiste) {
        console.log("Administrador inicial já está configurado.");
        return null;
    }

    const senhaHash = await bcrypt.hash(senha, 12);

    await prisma.usuario.create({
        data: {
            nome,
            email,
            senha: senhaHash,
            tipo: "ADMIN",
            ativo: true,
        },
        select: {
            id: true,
            nome: true,
            email: true,
            tipo: true,
        },
    });

    console.log(`Administrador inicial criado para ${email}.`);
    return true;
}

module.exports = createAdmin;
