import 'package:flutter_test/flutter_test.dart';
import 'package:tecassist_frontend/features/servicos/models/servico_model.dart';
import 'package:tecassist_frontend/features/servicos/providers/servico_provider.dart';
import 'package:tecassist_frontend/features/servicos/services/servico_service.dart';

void main() {
  late FakeServicoService service;
  late ServicoProvider provider;

  setUp(() {
    service = FakeServicoService();
    provider = ServicoProvider(service);
  });

  tearDown(() {
    provider.dispose();
  });

  test('carrega serviços ordenados do mais recente para o mais antigo', () async {
    service.itens = [
      _servicoJson(id: 1, data: '2026-11-10T10:00:00.000Z'),
      _servicoJson(id: 2, data: '2026-11-15T10:00:00.000Z'),
    ];

    await provider.carregar();

    expect(provider.jaCarregou, isTrue);
    expect(provider.servicos.map((item) => item.id), [2, 1]);
    expect(provider.isLoading, isFalse);
  });

  test('atualiza status do serviço e recarrega a listagem', () async {
    service.itens = [_servicoJson(id: 10, status: 'ABERTO')];
    await provider.carregar();

    final sucesso = await provider.atualizarStatus(
      provider.servicos.single,
      'EM_ANDAMENTO',
    );

    expect(sucesso, isTrue);
    expect(service.ultimoStatusEnviado, 'EM_ANDAMENTO');
    expect(provider.servicos.single.status, 'EM_ANDAMENTO');
    expect(provider.isSaving, isFalse);
  });

  test('retorna serviço pelo ID usando a resposta do service', () async {
    service.servicoPorId = _servicoJson(id: 23, equipamento: 'Impressora');

    final resultado = await provider.buscarPorId(23);

    expect(resultado, isNotNull);
    expect(resultado!.id, 23);
    expect(resultado.equipamento, 'Impressora');
  });

  test('retorna erro controlado quando a listagem falha', () async {
    service.falharListagem = true;

    await provider.carregar();

    expect(provider.servicos, isEmpty);
    expect(provider.errorMessage, 'Não foi possível carregar os serviços.');
    expect(provider.isLoading, isFalse);
  });
}

Map<String, dynamic> _servicoJson({
  required int id,
  String status = 'ABERTO',
  String data = '2026-11-10T10:00:00.000Z',
  String equipamento = 'Notebook',
}) {
  return {
    'id': id,
    'codigo': 'TA2026.${id.toString().padLeft(4, '0')}',
    'equipamento': equipamento,
    'status': status,
    'createdAt': data,
    'clienteId': 7,
    'usuarioId': 9,
    'cliente': {'id': 7, 'nome': 'Cliente teste', 'telefone': '67999990000'},
    'usuario': {'id': 9, 'nome': 'Funcionário teste'},
    'pecas': <Map<String, dynamic>>[],
  };
}

class FakeServicoService extends ServicoService {
  List<Map<String, dynamic>> itens = [];
  Map<String, dynamic>? servicoPorId;
  bool falharListagem = false;
  String? ultimoStatusEnviado;

  @override
  Future<List<Map<String, dynamic>>> listar() async {
    if (falharListagem) {
      throw Exception('Falha simulada');
    }
    return itens;
  }

  @override
  Future<Map<String, dynamic>> buscarPorId(int id) async {
    return servicoPorId ?? _servicoJson(id: id);
  }

  @override
  Future<void> atualizar({
    required int id,
    required int clienteId,
    required String equipamento,
    required String status,
    String? marca,
    String? modelo,
    String? problema,
    String? diagnostico,
    String? solucao,
    double? valor,
  }) async {
    ultimoStatusEnviado = status;
    final indice = itens.indexWhere((item) => item['id'] == id);
    if (indice >= 0) {
      itens[indice] = {...itens[indice], 'status': status};
    }
  }
}
