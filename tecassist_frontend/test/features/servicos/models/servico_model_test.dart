import 'package:flutter_test/flutter_test.dart';
import 'package:tecassist_frontend/features/servicos/models/servico_model.dart';

void main() {
  group('ServicoModel', () {
    test('converte serviço com cliente, responsável e peças vinculadas', () {
      final servico = ServicoModel.fromJson({
        'id': 52,
        'codigo': 'TA2026.0052',
        'equipamento': 'Notebook',
        'marca': 'Dell',
        'modelo': 'Inspiron',
        'problema': 'Não liga',
        'diagnostico': 'Falha na fonte',
        'solucao': 'Substituição da fonte',
        'status': 'EM_ANDAMENTO',
        'valor': '350.50',
        'createdAt': '2026-11-10T10:00:00.000Z',
        'finishedAt': null,
        'clienteId': 7,
        'usuarioId': 9,
        'cliente': {
          'id': 7,
          'nome': 'Maria Silva',
          'telefone': '67999990000',
        },
        'usuario': {'id': 9, 'nome': 'Carlos'},
        'agendamentoId': 12,
        'pecas': [
          {
            'id': 3,
            'servicoId': 52,
            'estoqueId': 4,
            'quantidade': 2,
            'estoque': {
              'id': 4,
              'nome': 'Fonte 19V',
              'valor': 120.0,
            },
          },
        ],
      });

      expect(servico.id, 52);
      expect(servico.codigo, 'TA2026.0052');
      expect(servico.equipamento, 'Notebook');
      expect(servico.valor, 350.50);
      expect(servico.clienteId, 7);
      expect(servico.clienteNome, 'Maria Silva');
      expect(servico.clienteTelefone, '67999990000');
      expect(servico.usuarioId, 9);
      expect(servico.usuarioNome, 'Carlos');
      expect(servico.agendamentoId, 12);
      expect(servico.pecas, hasLength(1));
      expect(servico.quantidadePecas, 1);
      expect(servico.pecas.first.estoqueNome, 'Fonte 19V');
      expect(servico.pecas.first.quantidade, 2);
    });

    test('usa identificadores aninhados quando os campos diretos não existem', () {
      final servico = ServicoModel.fromJson({
        'id': 1,
        'equipamento': 'Televisão',
        'status': 'ABERTO',
        'cliente': {'id': 2, 'nome': 'João'},
        'usuario': {'id': 3, 'nome': 'Ana'},
      });

      expect(servico.clienteId, 2);
      expect(servico.usuarioId, 3);
      expect(servico.clienteNome, 'João');
      expect(servico.usuarioNome, 'Ana');
    });

    test('aplica valores padrão para campos ausentes', () {
      final servico = ServicoModel.fromJson({'id': 8});

      expect(servico.equipamento, isEmpty);
      expect(servico.status, 'ABERTO');
      expect(servico.clienteNome, 'Cliente não informado');
      expect(servico.usuarioNome, 'Responsável não informado');
      expect(servico.pecas, isEmpty);
      expect(servico.valor, isNull);
    });
  });

  group('Status de serviço', () {
    test('disponibiliza a lista oficial de status na interface', () {
      expect(servicoStatusDisponiveis, [
        'ABERTO',
        'EM_ANDAMENTO',
        'AGUARDANDO_PECA',
        'CONCLUIDO',
        'ENTREGUE',
        'CANCELADO',
      ]);
    });

    test('apresenta rótulos legíveis para os status', () {
      expect(servicoStatusLabel('ABERTO'), 'Aberto');
      expect(servicoStatusLabel('EM_ANDAMENTO'), 'Em andamento');
      expect(servicoStatusLabel('AGUARDANDO_PECA'), 'Aguardando peça');
      expect(servicoStatusLabel('CONCLUIDO'), 'Concluído');
      expect(servicoStatusLabel('ENTREGUE'), 'Entregue');
      expect(servicoStatusLabel('CANCELADO'), 'Cancelado');
    });

    test('mantém rótulos de status antigos para registros já existentes', () {
      expect(servicoStatusLabel('EM_ANALISE'), 'Em análise');
      expect(servicoStatusLabel('EM_MANUTENCAO'), 'Em manutenção');
      expect(servicoStatusLabel('PRONTO'), 'Pronto para retirada');
    });
  });
}
