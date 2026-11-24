const prisma = require("../config/prisma");

const MENSAGEM_PADRAO =
  "Olá, {cliente}!\n\n" +
  "Aqui é da {assistencia}. Temos uma atualização sobre o seu atendimento.\n\n" +
  "Código do serviço: {codigo}\n" +
  "Código para consulta pública: {codigoConsulta}\n" +
  "Equipamento: {equipamento}\n" +
  "Status atual: {status}\n\n" +
  "Em caso de dúvidas, estamos à disposição!";

function erroHttp(mensagem, statusCode = 400) {
  const error = new Error(mensagem);
  error.statusCode = statusCode;
  return error;
}

function textoOpcional(valor, limite, campo) {
  if (valor === undefined || valor === null) return null;
  const texto = String(valor).trim();
  if (texto.length > limite) {
    throw erroHttp(`${campo} deve possuir no máximo ${limite} caracteres.`);
  }
  return texto || null;
}

async function buscar() {
  return prisma.configuracaoAssistencia.upsert({
    where: { id: 1 },
    update: {},
    create: {
      id: 1,
      estoqueMinimo: 5,
      mensagemWhatsApp: MENSAGEM_PADRAO,
    },
  });
}

async function salvar(data) {
  const estoqueMinimo = Number(data.estoqueMinimo);
  if (!Number.isInteger(estoqueMinimo) || estoqueMinimo < 0 || estoqueMinimo > 1000000) {
    throw erroHttp("A quantidade mínima deve ser um número inteiro entre 0 e 1.000.000.");
  }

  if (typeof data.mensagemWhatsApp !== "string" || !data.mensagemWhatsApp.trim()) {
    throw erroHttp("O modelo de mensagem do WhatsApp não pode ficar vazio.");
  }

  if (data.mensagemWhatsApp.length > 4000) {
    throw erroHttp("O modelo de mensagem deve possuir no máximo 4.000 caracteres.");
  }

  const emailSuporte = textoOpcional(data.emailSuporte, 200, "E-mail de suporte");
  if (emailSuporte && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(emailSuporte)) {
    throw erroHttp("E-mail de suporte inválido.");
  }

  const dados = {
    estoqueMinimo,
    mensagemWhatsApp: data.mensagemWhatsApp.trim(),
    nomeAssistencia: textoOpcional(data.nomeAssistencia, 120, "Nome da assistência"),
    telefoneAssistencia: textoOpcional(data.telefoneAssistencia, 20, "Telefone"),
    enderecoAssistencia: textoOpcional(data.enderecoAssistencia, 250, "Endereço"),
    emailSuporte,
  };

  return prisma.configuracaoAssistencia.upsert({
    where: { id: 1 },
    create: { id: 1, ...dados },
    update: dados,
  });
}

module.exports = { buscar, salvar };