const prisma = require("./config/prisma");
const createAdmin = require("./utils/createAdmin");

const app = require("./app");

const PORT = 3000;

app.listen(PORT, async () => {
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