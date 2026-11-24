import 'package:flutter_test/flutter_test.dart';
import 'package:tecassist_frontend/features/configuracoes/models/configuracao_model.dart';

void main() {
  group('ConfiguracaoModel', () {
    test('usa valores padrão quando a API não retorna configurações', () {
      final configuracao = ConfiguracaoModel.fromJson({});

      expect(configuracao.estoqueMinimo, 5);
      expect(configuracao.mensagemWhatsApp, ConfiguracaoModel.mensagemPadrao);
      expect(configuracao.nomeAssistencia, isEmpty);
      expect(configuracao.telefoneAssistencia, isEmpty);
      expect(configuracao.enderecoAssistencia, isEmpty);
      expect(configuracao.emailSuporte, isEmpty);
    });

    test('converte todas as configurações retornadas pela API', () {
      final configuracao = ConfiguracaoModel.fromJson({
        'estoqueMinimo': 50,
        'mensagemWhatsApp': 'Olá, {cliente}!',
        'nomeAssistencia': 'Tec Frio',
        'telefoneAssistencia': '6733334444',
        'enderecoAssistencia': 'Rua A, 100',
        'emailSuporte': 'suporte@tecassist.com',
      });

      expect(configuracao.estoqueMinimo, 50);
      expect(configuracao.mensagemWhatsApp, 'Olá, {cliente}!');
      expect(configuracao.nomeAssistencia, 'Tec Frio');
      expect(configuracao.telefoneAssistencia, '6733334444');
      expect(configuracao.enderecoAssistencia, 'Rua A, 100');
      expect(configuracao.emailSuporte, 'suporte@tecassist.com');
    });

    test('substitui modelo de mensagem vazio pelo modelo padrão', () {
      final configuracao = ConfiguracaoModel.fromJson({
        'mensagemWhatsApp': '   ',
      });

      expect(configuracao.mensagemWhatsApp, ConfiguracaoModel.mensagemPadrao);
    });

    test('copyWith preserva configurações não alteradas', () {
      const original = ConfiguracaoModel(
        estoqueMinimo: 5,
        nomeAssistencia: 'Assistência A',
        emailSuporte: 'suporte@a.com',
      );

      final atualizada = original.copyWith(estoqueMinimo: 50);

      expect(atualizada.estoqueMinimo, 50);
      expect(atualizada.nomeAssistencia, 'Assistência A');
      expect(atualizada.emailSuporte, 'suporte@a.com');
    });

    test('toJson mantém os campos usados pela API', () {
      const configuracao = ConfiguracaoModel(
        estoqueMinimo: 25,
        nomeAssistencia: 'Tec Frio',
        emailSuporte: 'suporte@tecfrio.com',
      );

      final json = configuracao.toJson();

      expect(json['estoqueMinimo'], 25);
      expect(json['nomeAssistencia'], 'Tec Frio');
      expect(json['emailSuporte'], 'suporte@tecfrio.com');
      expect(json.containsKey('mensagemWhatsApp'), isTrue);
    });
  });
}
