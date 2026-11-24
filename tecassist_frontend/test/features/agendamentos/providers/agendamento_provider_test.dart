import 'package:flutter_test/flutter_test.dart';
import 'package:tecassist_frontend/features/agendamentos/models/agendamento_model.dart';
import 'package:tecassist_frontend/features/agendamentos/providers/agendamento_provider.dart';
import 'package:tecassist_frontend/features/agendamentos/services/agendamento_service.dart';

void main() {
  late FakeAgendamentoService service;
  late AgendamentoProvider provider;

  setUp(() {
    service = FakeAgendamentoService();
    provider = AgendamentoProvider(service);
  });

  tearDown(() {
    provider.dispose();
  });

  test('carrega agendamentos e marca que a primeira carga foi concluída', () async {
    service.itens = [
      _agendamento(id: 1, descricao: 'Troca de tela'),
      _agendamento(id: 2, descricao: 'Revisão de notebook'),
    ];

    await provider.carregar();

    expect(provider.jaCarregou, isTrue);
    expect(provider.isLoading, isFalse);
    expect(provider.agendamentos, hasLength(2));
    expect(provider.errorMessage, isNull);
  });

  test('filtra agendamentos por descrição, cliente e status', () async {
    service.itens = [
      _agendamento(
        id: 1,
        descricao: 'Troca de tela',
        cliente: 'Ana Souza',
        status: 'AGENDADO',
      ),
      _agendamento(
        id: 2,
        descricao: 'Revisão elétrica',
        cliente: 'Carlos Lima',
        status: 'CANCELADO',
      ),
    ];
    await provider.carregar();

    provider.setBusca('TELA');
    expect(provider.agendamentosFiltrados.map((item) => item.id), [1]);

    provider.setBusca('carlos');
    expect(provider.agendamentosFiltrados.map((item) => item.id), [2]);

    provider.setBusca('cancelado');
    expect(provider.agendamentosFiltrados.map((item) => item.id), [2]);
  });

  test('ordena os agendamentos filtrados por data crescente', () async {
    service.itens = [
      _agendamento(id: 1, data: DateTime(2026, 11, 22, 10)),
      _agendamento(id: 2, data: DateTime(2026, 11, 20, 10)),
    ];
    await provider.carregar();

    expect(provider.agendamentosFiltrados.map((item) => item.id), [2, 1]);
  });

  test('filtra os agendamentos da data selecionada', () async {
    service.itens = [
      _agendamento(id: 1, data: DateTime(2026, 11, 20, 9)),
      _agendamento(id: 2, data: DateTime(2026, 11, 20, 16)),
      _agendamento(id: 3, data: DateTime(2026, 11, 21, 9)),
    ];
    await provider.carregar();

    provider.setDataSelecionada(DateTime(2026, 11, 20, 23));

    expect(provider.agendamentosDoDia.map((item) => item.id), [1, 2]);
    expect(provider.totalNoDia(DateTime(2026, 11, 20)), 2);
  });

  test('navega entre semanas de sete dias', () {
    provider.setDataSelecionada(DateTime(2026, 11, 16, 18));
    final inicial = provider.dataSelecionada;

    provider.proximaSemana();
    expect(provider.dataSelecionada, inicial.add(const Duration(days: 7)));

    provider.semanaAnterior();
    expect(provider.dataSelecionada, inicial);
  });

  test('altera o modo de visualização entre lista e calendário', () {
    expect(provider.visualizacao, AgendamentoVisualizacao.lista);

    provider.setVisualizacao(AgendamentoVisualizacao.calendario);
    expect(provider.visualizacao, AgendamentoVisualizacao.calendario);
  });

  test('informa erro quando não consegue carregar os agendamentos', () async {
    service.falharListagem = true;

    await provider.carregar();

    expect(provider.isLoading, isFalse);
    expect(provider.jaCarregou, isFalse);
    expect(provider.errorMessage, 'Erro inesperado ao carregar os agendamentos.');
  });
}

AgendamentoModel _agendamento({
  required int id,
  String descricao = 'Atendimento',
  String cliente = 'Cliente de teste',
  String status = 'AGENDADO',
  DateTime? data,
}) {
  return AgendamentoModel(
    id: id,
    descricao: descricao,
    data: data ?? DateTime(2026, 11, 20, 10),
    status: status,
    clienteId: id,
    clienteNome: cliente,
  );
}

class FakeAgendamentoService extends AgendamentoService {
  List<AgendamentoModel> itens = [];
  bool falharListagem = false;

  @override
  Future<List<AgendamentoModel>> findAll() async {
    if (falharListagem) {
      throw Exception('Falha simulada');
    }
    return itens;
  }
}
