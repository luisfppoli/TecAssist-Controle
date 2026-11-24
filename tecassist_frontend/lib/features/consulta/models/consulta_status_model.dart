class ConsultaStatusModel {
  final String equipamento;
  final String? marca;
  final String? modelo;
  final String status;
  final DateTime? createdAt;

  const ConsultaStatusModel({
    required this.equipamento,
    this.marca,
    this.modelo,
    required this.status,
    this.createdAt,
  });

  factory ConsultaStatusModel.fromJson(Map<String, dynamic> json) {
    return ConsultaStatusModel(
      equipamento: json['equipamento']?.toString() ?? 'Equipamento',
      marca: json['marca']?.toString(),
      modelo: json['modelo']?.toString(),
      status: json['status']?.toString() ?? 'ABERTO',
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.tryParse(json['createdAt'].toString()),
    );
  }
}
