import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_bottom_navigation.dart';
import '../../../core/widgets/back_to_home_scope.dart';
import '../../../core/widgets/blue_pattern_background.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/configuracao_model.dart';
import '../providers/configuracao_provider.dart';

class ConfiguracoesPage extends StatefulWidget {
  const ConfiguracoesPage({super.key});

  @override
  State<ConfiguracoesPage> createState() => _ConfiguracoesPageState();
}

class _ConfiguracoesPageState extends State<ConfiguracoesPage> {
  final _formKey = GlobalKey<FormState>();
  final _estoqueMinimoController = TextEditingController(text: '5');
  final _nomeController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _enderecoController = TextEditingController();
  final _mensagemController = TextEditingController(
    text: ConfiguracaoModel.mensagemPadrao,
  );

  bool _preencheuFormulario = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _carregar());
  }

  @override
  void dispose() {
    _estoqueMinimoController.dispose();
    _nomeController.dispose();
    _telefoneController.dispose();
    _enderecoController.dispose();
    _mensagemController.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    final provider = context.read<ConfiguracaoProvider>();
    await provider.carregar(forcar: true);

    if (!mounted) return;

    final configuracao = provider.configuracao;
    if (configuracao != null) {
      _aplicarConfiguracao(configuracao);
    }
  }

  void _aplicarConfiguracao(ConfiguracaoModel configuracao) {
    if (!mounted) return;

    setState(() {
      _estoqueMinimoController.text = configuracao.estoqueMinimo.toString();
      _nomeController.text = configuracao.nomeAssistencia;
      _telefoneController.text = configuracao.telefoneAssistencia;
      _enderecoController.text = configuracao.enderecoAssistencia;
      _mensagemController.text = configuracao.mensagemWhatsApp;
      _preencheuFormulario = true;
    });
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<ConfiguracaoProvider>();
    final configuracao = ConfiguracaoModel(
      estoqueMinimo: int.parse(_estoqueMinimoController.text.trim()),
      nomeAssistencia: _nomeController.text.trim(),
      telefoneAssistencia: _telefoneController.text.trim(),
      enderecoAssistencia: _enderecoController.text.trim(),
      mensagemWhatsApp: _mensagemController.text.trim(),
      emailSuporte: provider.configuracao?.emailSuporte ?? '',
    );

    final sucesso = await provider.salvar(configuracao);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          sucesso
              ? 'Configurações salvas com sucesso.'
              : provider.errorMessage ??
                    'Não foi possível salvar as configurações.',
        ),
        backgroundColor: sucesso ? null : AppColors.error,
      ),
    );

    if (sucesso && provider.configuracao != null) {
      _aplicarConfiguracao(provider.configuracao!);
    }
  }

  void _restaurarMensagemPadrao() {
    setState(() {
      _mensagemController.text = ConfiguracaoModel.mensagemPadrao;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final provider = context.watch<ConfiguracaoProvider>();
    final somenteLeitura = !auth.isAdmin;

    return BackToHomeScope(
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          toolbarHeight: 85,
          automaticallyImplyLeading: false,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          flexibleSpace: BluePatternBackground(
            showTopCircles: true,
            showBottomCircles: false,
            compactTopCircles: true,
            child: const SizedBox.expand(),
          ),
          leading: Transform.translate(
            offset: const Offset(0, 18),
            child: IconButton(
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/app/home');
                }
              },
              icon: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
          title: const Padding(
            padding: EdgeInsets.only(top: 18),
            child: Text(
              'Configurações',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        bottomNavigationBar: const AppBottomNavigation(),
        body: provider.isLoading && !_preencheuFormulario
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(18),
                  children: [
                    if (somenteLeitura)
                      _aviso(
                        'As configurações são administradas pelo usuário ADMIN. Você pode consultar os dados, mas não alterá-los.',
                        Icons.info_outline,
                      ),
                    if (provider.errorMessage != null &&
                        provider.configuracao == null)
                      _aviso(
                        provider.errorMessage!,
                        Icons.warning_amber_rounded,
                      ),
                    _secao(
                      titulo: 'Estoque',
                      descricao:
                          'Defina a quantidade que será considerada como estoque baixo.',
                      icone: Icons.inventory_2_outlined,
                      filhos: [
                        TextFormField(
                          controller: _estoqueMinimoController,
                          enabled: !somenteLeitura,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Quantidade mínima de estoque',
                            helperText:
                                'Exemplo: 50. Itens com quantidade entre 1 e 50 serão sinalizados como estoque baixo.',
                            prefixIcon: Icon(Icons.numbers_outlined),
                          ),
                          validator: (value) {
                            final numero = int.tryParse(value ?? '');
                            if (numero == null ||
                                numero < 0 ||
                                numero > 1000000) {
                              return 'Informe um número entre 0 e 1.000.000.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Use 0 para desativar o alerta de estoque baixo. Itens zerados continuam aparecendo como “Sem estoque”.',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _secao(
                      titulo: 'Dados da assistência',
                      descricao:
                          'Essas informações podem ser utilizadas nas mensagens enviadas aos clientes.',
                      icone: Icons.business_outlined,
                      filhos: [
                        TextFormField(
                          controller: _nomeController,
                          enabled: !somenteLeitura,
                          maxLength: 120,
                          decoration: const InputDecoration(
                            labelText: 'Nome da assistência técnica',
                            prefixIcon: Icon(Icons.store_outlined),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _telefoneController,
                          enabled: !somenteLeitura,
                          keyboardType: TextInputType.phone,
                          maxLength: 20,
                          decoration: const InputDecoration(
                            labelText: 'Telefone da assistência',
                            prefixIcon: Icon(Icons.phone_outlined),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _enderecoController,
                          enabled: !somenteLeitura,
                          maxLength: 250,
                          decoration: const InputDecoration(
                            labelText: 'Endereço da assistência',
                            prefixIcon: Icon(Icons.location_on_outlined),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _secao(
                      titulo: 'Modelo de mensagem WhatsApp',
                      descricao:
                          'Personalize o texto que será preenchido ao atualizar o cliente sobre um serviço.',
                      icone: Icons.chat_outlined,
                      filhos: [
                        TextFormField(
                          controller: _mensagemController,
                          enabled: !somenteLeitura,
                          minLines: 7,
                          maxLines: 12,
                          maxLength: 4000,
                          decoration: const InputDecoration(
                            labelText: 'Mensagem',
                            alignLabelWithHint: true,
                            helperText:
                                'O texto será preenchido automaticamente com os dados do serviço.',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'A mensagem não pode ficar vazia.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Variáveis disponíveis: {cliente}, {codigo}, {codigoConsulta}, {equipamento}, {marca}, {modelo}, {problema}, {diagnostico}, {solucao}, {status}, {assistencia}, {telefoneAssistencia} e {enderecoAssistencia}.',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            height: 1.45,
                          ),
                        ),
                        if (!somenteLeitura)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: _restaurarMensagemPadrao,
                              icon: const Icon(Icons.restart_alt),
                              label: const Text('Restaurar mensagem padrão'),
                            ),
                          ),
                      ],
                    ),
                    if (auth.isAdmin) ...[
                      const SizedBox(height: 14),
                      _secao(
                        titulo: 'Cadastro de funcionários',
                        descricao:
                            'Gere e acompanhe códigos temporários para permitir o cadastro de novos funcionários.',
                        icone: Icons.key_outlined,
                        filhos: [
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => context.push('/codigo-cadastro'),
                              icon: const Icon(Icons.password_outlined),
                              label: const Text('Gerenciar código de cadastro'),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (!somenteLeitura) ...[
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: provider.isSaving ? null : _salvar,
                          icon: provider.isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.save_outlined),
                          label: Text(
                            provider.isSaving
                                ? 'Salvando...'
                                : 'Salvar configurações',
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 26),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _aviso(String texto, IconData icone) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, color: AppColors.warning),
          const SizedBox(width: 9),
          Expanded(child: Text(texto, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  Widget _secao({
    required String titulo,
    required String descricao,
    required IconData icone,
    required List<Widget> filhos,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icone, color: AppColors.primary, size: 23),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  titulo,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            descricao,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          ...filhos,
        ],
      ),
    );
  }
}
