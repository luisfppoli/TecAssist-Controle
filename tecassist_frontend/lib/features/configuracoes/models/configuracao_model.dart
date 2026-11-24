class ConfiguracaoModel {
  static const String mensagemPadrao =
      'Olá, {cliente}!\n\n'
      'Aqui é da {assistencia}. Temos uma atualização sobre o seu atendimento.\n\n'
      'Código do serviço: {codigo}\n'
      'Código para consulta pública: {codigoConsulta}\n'
      'Equipamento: {equipamento}\n'
      'Status atual: {status}\n\n'
      'Em caso de dúvidas, estamos à disposição!';

  final int estoqueMinimo;
  final String mensagemWhatsApp;
  final String nomeAssistencia;
  final String telefoneAssistencia;
  final String enderecoAssistencia;
  final String emailSuporte;

  const ConfiguracaoModel({
    this.estoqueMinimo = 5,
    this.mensagemWhatsApp = mensagemPadrao,
    this.nomeAssistencia = '',
    this.telefoneAssistencia = '',
    this.enderecoAssistencia = '',
    this.emailSuporte = '',
  });

  factory ConfiguracaoModel.fromJson(Map<String, dynamic> json) {
    return ConfiguracaoModel(
      estoqueMinimo: (json['estoqueMinimo'] as num?)?.toInt() ?? 5,
      mensagemWhatsApp:
          json['mensagemWhatsApp']?.toString().trim().isNotEmpty == true
          ? json['mensagemWhatsApp'].toString()
          : mensagemPadrao,
      nomeAssistencia: json['nomeAssistencia']?.toString() ?? '',
      telefoneAssistencia: json['telefoneAssistencia']?.toString() ?? '',
      enderecoAssistencia: json['enderecoAssistencia']?.toString() ?? '',
      emailSuporte: json['emailSuporte']?.toString() ?? '',
    );
  }

  ConfiguracaoModel copyWith({
    int? estoqueMinimo,
    String? mensagemWhatsApp,
    String? nomeAssistencia,
    String? telefoneAssistencia,
    String? enderecoAssistencia,
    String? emailSuporte,
  }) {
    return ConfiguracaoModel(
      estoqueMinimo: estoqueMinimo ?? this.estoqueMinimo,
      mensagemWhatsApp: mensagemWhatsApp ?? this.mensagemWhatsApp,
      nomeAssistencia: nomeAssistencia ?? this.nomeAssistencia,
      telefoneAssistencia: telefoneAssistencia ?? this.telefoneAssistencia,
      enderecoAssistencia: enderecoAssistencia ?? this.enderecoAssistencia,
      emailSuporte: emailSuporte ?? this.emailSuporte,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'estoqueMinimo': estoqueMinimo,
      'mensagemWhatsApp': mensagemWhatsApp,
      'nomeAssistencia': nomeAssistencia,
      'telefoneAssistencia': telefoneAssistencia,
      'enderecoAssistencia': enderecoAssistencia,
      'emailSuporte': emailSuporte,
    };
  }
}
