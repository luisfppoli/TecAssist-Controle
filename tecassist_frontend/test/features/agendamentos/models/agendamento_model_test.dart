import 'package:flutter_test/flutter_test.dart';
import 'package:tecassist_frontend/features/agendamentos/models/agendamento_model.dart';

void main() {
  group('AgendamentoModel', () {
    test('converte agendamento com dados aninhados do cliente', () {
      final agendamento = AgendamentoModel.fromJson({
        'id': 15,
        'descricao': 'Manutenção de notebook',
        'data': '2026-11-20T14:30:00.000Z',
        'status': 'AGENDADO',
        'createdAt': '2026-11-15T10:00:00.000Z',
        'cliente': {
          'id': 7,
          'nome': 'Maria Silva',
          'telefone': '67999990000',
        },
      });

      expect(agendamento.id, 15);
      expect(agendamento.descricao, 'Manutenção de notebook');
      expect(agendamento.status, 'AGENDADO');
      expect(agendamento.clienteId, 7);
      expect(agendamento.clienteNome, 'Maria Silva');
      expect(agendamento.clienteTelefone, '67999990000');
      expect(agendamento.isConvertido, isFalse);
      expect(agendamento.isCancelado, isFalse);
    });

    test('reconhece status convertido e cancelado sem diferenciar maiúsculas', () {
      final convertido = _agendamento(status: 'convertido');
      final cancelado = _agendamento(status: 'Cancelado');

      expect(convertido.isConvertido, isTrue);
      expect(convertido.isCancelado, isFalse);
      expect(cancelado.isCancelado, isTrue);
      expect(cancelado.isConvertido, isFalse);
    });

    test('serializa data em ISO 8601 e mantém clienteId', () {
      final data = DateTime.utc(2026, 11, 20, 14, 30);
      final agendamento = _agendamento(data: data, clienteId: 12);
      final json = agendamento.toJson();

      expect(json['data'], data.toIso8601String());
      expect(json['clienteId'], 12);
      expect(json['descricao'], 'Revisão');
      expect(json['status'], 'AGENDADO');
    });

    test('copyWith altera somente os campos informados', () {
      final original = _agendamento();
      final atualizado = original.copyWith(
        descricao: 'Novo atendimento',
        status: 'CANCELADO',
      );

      expect(atualizado.descricao, 'Novo atendimento');
      expect(atualizado.status, 'CANCELADO');
      expect(atualizado.id, original.id);
      expect(atualizado.clienteId, original.clienteId);
      expect(atualizado.data, original.data);
    });
  });
}

AgendamentoModel _agendamento({
  String status = 'AGENDADO',
  String descricao = 'Revisão',
  DateTime? data,
  int clienteId = 3,
}) {
  return AgendamentoModel(
    id: 1,
    descricao: descricao,
    data: data ?? DateTime(2026, 11, 20, 14, 30),
    status: status,
    clienteId: clienteId,
    clienteNome: 'Cliente de teste',
  );
}
