-- CreateTable
CREATE TABLE "ConfiguracaoAssistencia" (
    "id" INTEGER NOT NULL DEFAULT 1,
    "estoqueMinimo" INTEGER NOT NULL DEFAULT 5,
    "mensagemWhatsApp" TEXT NOT NULL DEFAULT 'Olá, {cliente}! Aqui é da {assistencia}. Temos uma atualização sobre o seu atendimento. Código do serviço: {codigo}. Equipamento: {equipamento}. Status atual: {status}. Em caso de dúvidas, estamos à disposição!',
    "nomeAssistencia" TEXT,
    "telefoneAssistencia" TEXT,
    "enderecoAssistencia" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "ConfiguracaoAssistencia_pkey" PRIMARY KEY ("id")
);
