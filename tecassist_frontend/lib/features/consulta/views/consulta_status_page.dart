import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/auth_background.dart';
import '../../../core/widgets/tecassist_brand.dart';
import '../../servicos/models/servico_model.dart';
import '../models/consulta_status_model.dart';
import '../services/consulta_status_service.dart';

class ConsultaStatusPage extends StatefulWidget {
  final String apiBaseUrl;

  const ConsultaStatusPage({super.key, required this.apiBaseUrl});

  @override
  State<ConsultaStatusPage> createState() => _ConsultaStatusPageState();
}

class _ConsultaStatusPageState extends State<ConsultaStatusPage> {
  final _formKey = GlobalKey<FormState>();
  final _codigoController = TextEditingController();

  late final ConsultaStatusService _service;

  ConsultaStatusModel? _resultado;
  String? _erro;
  bool _carregando = false;

  @override
  void initState() {
    super.initState();
    _service = ConsultaStatusService(apiBaseUrl: widget.apiBaseUrl);
  }

  @override
  void dispose() {
    _codigoController.dispose();
    super.dispose();
  }

  Future<void> _consultar() async {
    if (!_formKey.currentState!.validate() || _carregando) {
      return;
    }

    final codigo = _codigoController.text
        .trim()
        .replaceAll(RegExp(r'\s+'), '')
        .toUpperCase();

    setState(() {
      _carregando = true;
      _erro = null;
      _resultado = null;
    });

    try {
      final resultado = await _service.consultar(codigo);
      if (!mounted) return;

      setState(() {
        _resultado = resultado;
      });
    } on ConsultaStatusException catch (error) {
      if (!mounted) return;

      setState(() {
        _erro = error.mensagem;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _erro = 'Ocorreu um erro inesperado. Tente novamente.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _carregando = false;
        });
      }
    }
  }

  void _consultarOutro() {
    setState(() {
      _resultado = null;
      _erro = null;
      _codigoController.clear();
    });
  }

  String _data(DateTime? data) {
    if (data == null) return 'Não informada';
    return DateFormat('dd/MM/yyyy').format(data.toLocal());
  }

  Color _corStatus(String status) {
    switch (status.toUpperCase()) {
      case 'ABERTO':
        return Colors.blue.shade700;
      case 'EM_ANALISE':
        return Colors.indigo.shade600;
      case 'AGUARDANDO_PECA':
        return Colors.deepOrange.shade700;
      case 'EM_MANUTENCAO':
      case 'EM_ANDAMENTO':
        return Colors.orange.shade800;
      case 'PRONTO':
      case 'CONCLUIDO':
        return AppColors.success;
      case 'ENTREGUE':
        return Colors.teal.shade700;
      case 'CANCELADO':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _iconeStatus(String status) {
    switch (status.toUpperCase()) {
      case 'ABERTO':
        return Icons.assignment_outlined;
      case 'EM_ANALISE':
        return Icons.search;
      case 'AGUARDANDO_PECA':
        return Icons.inventory_2_outlined;
      case 'EM_MANUTENCAO':
      case 'EM_ANDAMENTO':
        return Icons.build_outlined;
      case 'PRONTO':
      case 'CONCLUIDO':
        return Icons.check_circle_outline;
      case 'ENTREGUE':
        return Icons.done_all;
      case 'CANCELADO':
        return Icons.cancel_outlined;
      default:
        return Icons.info_outline;
    }
  }

  String _descricaoStatus(String status) {
    switch (status.toUpperCase()) {
      case 'ABERTO':
        return 'O atendimento foi registrado pela assistência técnica.';
      case 'EM_ANALISE':
        return 'O equipamento está em processo de avaliação técnica.';
      case 'AGUARDANDO_PECA':
        return 'O atendimento está aguardando a disponibilidade de uma peça.';
      case 'EM_MANUTENCAO':
      case 'EM_ANDAMENTO':
        return 'O equipamento está em processo de manutenção.';
      case 'PRONTO':
      case 'CONCLUIDO':
        return 'O serviço foi concluído e o equipamento está pronto para retirada.';
      case 'ENTREGUE':
        return 'O equipamento consta como entregue pela assistência técnica.';
      case 'CANCELADO':
        return 'Este atendimento consta como cancelado. Entre em contato com a assistência para mais informações.';
      default:
        return 'Consulte a assistência técnica para obter mais informações sobre este atendimento.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthBackground(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 28),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 60,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 540),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const TecAssistBrand(),
                      const SizedBox(height: 34),
                      _cartaoConsulta(),
                      const SizedBox(height: 22),
                      const Text(
                        'A consulta apresenta somente informações básicas do atendimento.\nEm caso de dúvidas, entre em contato com a assistência técnica.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _cartaoConsulta() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Consultar serviço',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 25,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Informe o código de consulta fornecido pela assistência técnica para verificar o andamento do seu atendimento.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 26),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _codigoController,
                  enabled: !_carregando,
                  textCapitalization: TextCapitalization.characters,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.search,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9-]')),
                    LengthLimitingTextInputFormatter(35),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Código de consulta',
                    hintText: 'TA- seguido do código recebido',
                    prefixIcon: Icon(Icons.confirmation_number_outlined),
                    counterText: '',
                  ),
                  validator: (value) {
                    final codigo = (value ?? '').trim().toUpperCase();
                    if (codigo.isEmpty) {
                      return 'Informe o código de consulta.';
                    }
                    if (!RegExp(r'^TA-[A-F0-9]{32}$').hasMatch(codigo)) {
                      return 'Confira o código. Ele deve começar com TA- e conter 32 caracteres.';
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) => _consultar(),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _carregando ? null : _consultar,
                    icon: _carregando
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.search),
                    label: Text(
                      _carregando ? 'Consultando...' : 'Consultar status',
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_erro != null) ...[
            const SizedBox(height: 18),
            _mensagemErro(_erro!),
          ],
          if (_resultado != null) ...[
            const SizedBox(height: 22),
            _cartaoResultado(_resultado!),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _consultarOutro,
              icon: const Icon(Icons.refresh),
              label: const Text('Consultar outro código'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _mensagemErro(String mensagem) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: AppColors.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              mensagem,
              style: const TextStyle(color: AppColors.error, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cartaoResultado(ConsultaStatusModel servico) {
    final cor = _corStatus(servico.status);
    final identificacaoEquipamento = [
      if (servico.marca?.trim().isNotEmpty == true) servico.marca!.trim(),
      if (servico.modelo?.trim().isNotEmpty == true) servico.modelo!.trim(),
    ].join(' • ');

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.lightBlue.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.fact_check_outlined, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'Resultado da consulta',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'Equipamento',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            servico.equipamento,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (identificacaoEquipamento.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              identificacaoEquipamento,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
          const SizedBox(height: 18),
          const Text(
            'Status atual',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: cor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: cor.withValues(alpha: 0.25)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_iconeStatus(servico.status), color: cor, size: 19),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    servicoStatusLabel(servico.status),
                    style: TextStyle(color: cor, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _descricaoStatus(servico.status),
            style: const TextStyle(color: AppColors.textPrimary, height: 1.45),
          ),
          if (servico.createdAt != null) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  color: AppColors.textSecondary,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'Entrada na assistência: ${_data(servico.createdAt)}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          const Text(
            'Esta consulta apresenta o status mais recente registrado pela assistência técnica.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
