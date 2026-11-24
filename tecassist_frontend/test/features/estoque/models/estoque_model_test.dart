import 'package:flutter_test/flutter_test.dart';
import 'package:tecassist_frontend/features/estoque/models/estoque_model.dart';

void main() {
  group('EstoqueModel', () {
    test('converte os dados retornados pela API', () {
      final item = EstoqueModel.fromJson({
        'id': 4,
        'nome': 'Fonte 19V',
        'descricao': 'Fonte para notebook',
        'quantidade': 12,
        'valor': '89.90',
        'fornecedor': 'Fornecedor A',
        'dataCadastro': '2026-11-10T12:00:00.000Z',
      });

      expect(item.id, 4);
      expect(item.nome, 'Fonte 19V');
      expect(item.descricao, 'Fonte para notebook');
      expect(item.quantidade, 12);
      expect(item.valor, 89.90);
      expect(item.fornecedor, 'Fornecedor A');
      expect(item.dataCadastro, DateTime.parse('2026-11-10T12:00:00.000Z'));
    });

    test('utiliza createdAt quando dataCadastro não está presente', () {
      final item = EstoqueModel.fromJson({
        'id': 1,
        'nome': 'Cabo HDMI',
        'quantidade': 3,
        'valor': 15,
        'createdAt': '2026-11-01T08:00:00.000Z',
      });

      expect(item.dataCadastro, isNotNull);
      expect(item.dataCadastro!.year, 2026);
    });

    test('identifica item sem estoque', () {
      final item = _item(quantidade: 0);

      expect(item.semEstoque, isTrue);
      expect(item.estoqueBaixo, isFalse);
    });

    test('identifica estoque baixo no limite padrão', () {
      expect(_item(quantidade: 1).estoqueBaixo, isTrue);
      expect(_item(quantidade: 5).estoqueBaixo, isTrue);
      expect(_item(quantidade: 6).estoqueBaixo, isFalse);
    });

    test('permite avaliar estoque baixo com limite personalizado', () {
      final item = _item(quantidade: 40);

      expect(item.estoqueBaixoComLimite(50), isTrue);
      expect(item.estoqueBaixoComLimite(30), isFalse);
      expect(_item(quantidade: 0).estoqueBaixoComLimite(50), isFalse);
    });

    test('converte para JSON sem perder os dados principais', () {
      final item = _item(quantidade: 9);
      final json = item.toJson();

      expect(json['id'], 1);
      expect(json['nome'], 'Peça de teste');
      expect(json['quantidade'], 9);
      expect(json['valor'], 25.5);
      expect(json['fornecedor'], 'Fornecedor');
    });
  });
}

EstoqueModel _item({required int quantidade}) {
  return EstoqueModel(
    id: 1,
    nome: 'Peça de teste',
    descricao: 'Descrição',
    quantidade: quantidade,
    valor: 25.5,
    fornecedor: 'Fornecedor',
    dataCadastro: DateTime(2026, 11, 1),
  );
}
