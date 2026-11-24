import '../../../core/network/api_client.dart';
import '../models/configuracao_model.dart';

class ConfiguracaoService {
  Future<ConfiguracaoModel> buscar() async {
    final response = await ApiClient.dio.get('/configuracoes');
    final dados = response.data;

    if (dados is! Map) {
      throw const FormatException('A API retornou configurações inválidas.');
    }

    return ConfiguracaoModel.fromJson(Map<String, dynamic>.from(dados));
  }

  Future<ConfiguracaoModel> salvar(ConfiguracaoModel configuracao) async {
    final response = await ApiClient.dio.put(
      '/configuracoes',
      data: configuracao.toJson(),
    );
    final dados = response.data;

    if (dados is! Map) {
      throw const FormatException(
        'A API não retornou as configurações salvas.',
      );
    }

    return ConfiguracaoModel.fromJson(Map<String, dynamic>.from(dados));
  }
}
