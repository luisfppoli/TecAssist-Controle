const prisma = require("./config/prisma");
const createAdmin = require("./utils/createAdmin");

const app = require("./app");

const PORT = Number(process.env.PORT) || 3000;

app.listen(PORT, "0.0.0.0", async () => {
    console.log(`Servidor rodando na porta ${PORT}`);

    try {
        await createAdmin();
    } catch (error) {
        console.error(
            "Não foi possível configurar o administrador inicial:",
            error.message
        );
    }
});