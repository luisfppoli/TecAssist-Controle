import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../models/configuracao_model.dart';
import '../services/configuracao_service.dart';

class ConfiguracaoProvider extends ChangeNotifier {
  final ConfiguracaoService _service = ConfiguracaoService();

  ConfiguracaoModel? _configuracao;
  bool _isLoading = false;
  bool _isSaving = false;
  bool _jaCarregou = false;
  String? _errorMessage;

  ConfiguracaoModel? get configuracao => _configuracao;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get jaCarregou => _jaCarregou;
  String? get errorMessage => _errorMessage;
  int get estoqueMinimo => _configuracao?.estoqueMinimo ?? 5;

  Future<void> carregar({bool forcar = false}) async {
    if (_isLoading || (_jaCarregou && !forcar)) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _configuracao = await _service.buscar();
      _jaCarregou = true;
    } on DioException catch (error) {
      _errorMessage = _mensagemErro(error);
    } catch (error) {
      _errorMessage = error is FormatException
          ? error.message
          : 'Não foi possível carregar as configurações.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> salvar(ConfiguracaoModel configuracao) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _configuracao = await _service.salvar(configuracao);
      _jaCarregou = true;
      return true;
    } on DioException catch (error) {
      _errorMessage = _mensagemErro(error);
      return false;
    } catch (error) {
      _errorMessage = error is FormatException
          ? error.message
          : 'Não foi possível salvar as configurações.';
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  String _mensagemErro(DioException error) {
    final dados = error.response?.data;
    if (dados is Map && dados['error'] != null) {
      return dados['error'].toString();
    }
    if (dados is Map && dados['message'] != null) {
      return dados['message'].toString();
    }
    if (error.response?.statusCode == 403) {
      return 'Somente o administrador pode alterar as configurações.';
    }
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout) {
      return 'Não foi possível conectar ao servidor.';
    }
    return 'Não foi possível realizar a operação.';
  }
}
