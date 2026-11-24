import 'package:dio/dio.dart';

import '../models/consulta_status_model.dart';

class ConsultaStatusException implements Exception {
  final String mensagem;

  const ConsultaStatusException(this.mensagem);

  @override
  String toString() => mensagem;
}

class ConsultaStatusService {
  late final Dio _dio;

  ConsultaStatusService({required String apiBaseUrl}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: apiBaseUrl.trim().replaceFirst(RegExp(r'/+$'), ''),
        connectTimeout: const Duration(seconds: 12),
        receiveTimeout: const Duration(seconds: 12),
        headers: const {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );
  }

  Future<ConsultaStatusModel> consultar(String codigo) async {
    if (_dio.options.baseUrl.isEmpty) {
      throw const ConsultaStatusException(
        'O endereço da API não foi configurado para a página de consulta.',
      );
    }

    final codigoNormalizado = codigo.trim().toUpperCase();

    try {
      final response = await _dio.post(
        '/consulta-publica',
        data: {'codigoConsulta': codigoNormalizado},
      );

      final dados = response.data;
      if (dados is! Map) {
        throw const ConsultaStatusException(
          'A resposta recebida do servidor é inválida.',
        );
      }

      final servico = dados['servico'];
      if (servico is! Map) {
        throw const ConsultaStatusException(
          'Não foi possível interpretar os dados do serviço.',
        );
      }

      return ConsultaStatusModel.fromJson(Map<String, dynamic>.from(servico));
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        throw const ConsultaStatusException(
          'Não encontramos um serviço com esse código. Confira o código informado e tente novamente.',
        );
      }

      if (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        throw const ConsultaStatusException(
          'Não foi possível conectar à assistência técnica. Verifique sua conexão e tente novamente.',
        );
      }

      throw const ConsultaStatusException(
        'Não foi possível consultar o serviço no momento. Tente novamente.',
      );
    }
  }
}
