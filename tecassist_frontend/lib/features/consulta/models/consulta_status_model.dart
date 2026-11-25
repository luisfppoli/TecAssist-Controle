class ConsultaStatusModel {
  final String equipamento;
  final String? marca;
  final String? modelo;
  final String status;
  final double? valor;
  final DateTime? createdAt;
  final DateTime? finishedAt;

  const ConsultaStatusModel({
    required this.equipamento,
    this.marca,
    this.modelo,
    required this.status,
    this.valor,
    this.createdAt,
    this.finishedAt,
  });

  factory ConsultaStatusModel.fromJson(Map<String, dynamic> json) {
    return ConsultaStatusModel(
      equipamento: json['equipamento']?.toString() ?? 'Equipamento',
      marca: json['marca']?.toString(),
      modelo: json['modelo']?.toString(),
      status: json['status']?.toString() ?? 'ABERTO',

      valor: json['valor'] == null
          ? null
          : double.tryParse(json['valor'].toString()),

      createdAt: json['createdAt'] == null
          ? null
          : DateTime.tryParse(json['createdAt'].toString()),

      finishedAt: json['finishedAt'] == null
          ? null
          : DateTime.tryParse(json['finishedAt'].toString()),
    );
  }
}
