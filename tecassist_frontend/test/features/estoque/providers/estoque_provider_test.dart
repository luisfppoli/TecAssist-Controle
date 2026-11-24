import 'package:flutter_test/flutter_test.dart';
import 'package:tecassist_frontend/features/estoque/providers/estoque_provider.dart';
import 'package:tecassist_frontend/features/estoque/services/estoque_service.dart';

void main() {
  late FakeEstoqueService service;
  late EstoqueProvider provider;

  setUp(() {
    service = FakeEstoqueService();
    provider = EstoqueProvider(service);
  });

  tearDown(() {
    provider.dispose();
  });

  test('carrega itens, ordena por nome e calcula os totais', () async {
    service.itens = [
      _item(id: 1, nome: 'Zíper', quantidade: 0),
      _item(id: 2, nome: 'Arruela', quantidade: 3),
      _item(id: 3, nome: 'Parafuso', quantidade: 8),
    ];

    await provider.carregar();

    expect(provider.jaCarregou, isTrue);
    expect(provider.itens.map((item) => item.nome), [
      'Arruela',
      'Parafuso',
      'Zíper',
    ]);
    expect(provider.totalItens, 3);
    expect(provider.totalSemEstoque, 1);
    expect(provider.totalEstoqueBaixo, 1);
  });

  test('não envia movimentação com quantidade zero ou negativa', () async {
    final entrada = await provider.registrarEntrada(
      estoqueId: 1,
      quantidade: 0,
    );
    final saida = await provider.registrarSaida(
      estoqueId: 1,
      quantidade: -2,
    );

    expect(entrada, isFalse);
    expect(saida, isFalse);
    expect(service.quantidadeChamadasMovimentacao, 0);
    expect(provider.errorMessage, 'A quantidade precisa ser maior que zero.');
  });

  test('registra entrada e atualiza a quantidade local após recarregar', () async {
    service.itens = [_item(id: 1, nome: 'Cabo', quantidade: 5)];

    await provider.carregar();
    final sucesso = await provider.registrarEntrada(
      estoqueId: 1,
      quantidade: 4,
    );

    expect(sucesso, isTrue);
    expect(service.ultimaQuantidadeMovimentada, 4);
    expect(provider.itens.single.quantidade, 9);
    expect(provider.isSaving, isFalse);
  });

  test('registra saída e atualiza a quantidade local após recarregar', () async {
    service.itens = [_item(id: 1, nome: 'Cabo', quantidade: 8)];

    await provider.carregar();
    final sucesso = await provider.registrarSaida(
      estoqueId: 1,
      quantidade: 3,
    );

    expect(sucesso, isTrue);
    expect(provider.itens.single.quantidade, 5);
  });

  test('remove item da listagem após exclusão bem-sucedida', () async {
    service.itens = [
      _item(id: 1, nome: 'Cabo', quantidade: 8),
      _item(id: 2, nome: 'Conector', quantidade: 4),
    ];
    await provider.carregar();

    final sucesso = await provider.excluir(1);

    expect(sucesso, isTrue);
    expect(provider.itens.map((item) => item.id), [2]);
  });
}

Map<String, dynamic> _item({
  required int id,
  required String nome,
  required int quantidade,
}) {
  return {
    'id': id,
    'nome': nome,
    'descricao': 'Item de teste',
    'quantidade': quantidade,
    'valor': 10.0,
  };
}

class FakeEstoqueService extends EstoqueService {
  List<Map<String, dynamic>> itens = [];
  int quantidadeChamadasMovimentacao = 0;
  int? ultimaQuantidadeMovimentada;

  @override
  Future<List<Map<String, dynamic>>> listar() async => itens;

  @override
  Future<List<Map<String, dynamic>>> listarMovimentacoes() async => [];

  @override
  Future<void> registrarEntrada({
    required int estoqueId,
    required int quantidade,
  }) async {
    quantidadeChamadasMovimentacao++;
    ultimaQuantidadeMovimentada = quantidade;
    final item = itens.firstWhere((item) => item['id'] == estoqueId);
    item['quantidade'] = (item['quantidade'] as num).toInt() + quantidade;
  }

  @override
  Future<void> registrarSaida({
    required int estoqueId,
    required int quantidade,
  }) async {
    quantidadeChamadasMovimentacao++;
    ultimaQuantidadeMovimentada = quantidade;
    final item = itens.firstWhere((item) => item['id'] == estoqueId);
    item['quantidade'] = (item['quantidade'] as num).toInt() - quantidade;
  }

  @override
  Future<void> excluir(int id) async {
    itens.removeWhere((item) => item['id'] == id);
  }
}
