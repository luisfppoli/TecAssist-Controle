/*
  Warnings:

  - A unique constraint covering the columns `[codigoConsulta]` on the table `Servico` will be added. If there are existing duplicate values, this will fail.

*/
-- AlterTable
ALTER TABLE "ConfiguracaoAssistencia" ALTER COLUMN "mensagemWhatsApp" SET DEFAULT 'Olá, {cliente}! Aqui é da {assistencia}. Temos uma atualização sobre o seu atendimento. Código do serviço: {codigo}. Código para consulta pública: {codigoConsulta}. Equipamento: {equipamento}. Status atual: {status}. Em caso de dúvidas, estamos à disposição!';

-- AlterTable
ALTER TABLE "Servico" ADD COLUMN     "codigoConsulta" TEXT;

-- CreateIndex
CREATE UNIQUE INDEX "Servico_codigoConsulta_key" ON "Servico"("codigoConsulta");
