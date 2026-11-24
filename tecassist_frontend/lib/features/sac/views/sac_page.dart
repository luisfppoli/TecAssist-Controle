import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_bottom_navigation.dart';
import '../../../core/widgets/back_to_home_scope.dart';
import '../../../core/widgets/blue_pattern_background.dart';
import '../../auth/providers/auth_provider.dart';
import '../../configuracoes/models/configuracao_model.dart';
import '../../configuracoes/providers/configuracao_provider.dart';

class SacPage extends StatefulWidget {
  const SacPage({super.key});

  @override
  State<SacPage> createState() => _SacPageState();
}

class _SacPageState extends State<SacPage> {
  final _formKey = GlobalKey<FormState>();
  final _assuntoController = TextEditingController(
    text: 'Relato de problema - TecAssist Controle',
  );
  final _descricaoController = TextEditingController();
  final _emailSuporteController = TextEditingController();

  bool _emailCarregado = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _carregarConfiguracao(),
    );
  }

  @override
  void dispose() {
    _assuntoController.dispose();
    _descricaoController.dispose();
    _emailSuporteController.dispose();
    super.dispose();
  }

  Future<void> _carregarConfiguracao() async {
    final provider = context.read<ConfiguracaoProvider>();
    await provider.carregar(forcar: true);

    if (!mounted) return;

    _emailSuporteController.text = provider.configuracao?.emailSuporte ?? '';
    setState(() => _emailCarregado = true);
  }

  Future<void> _salvarEmailSuporte() async {
    if (!_emailCarregado) return;

    final email = _emailSuporteController.text.trim();
    final emailValido = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

    if (!emailValido.hasMatch(email)) {
      _mensagem('Informe um endereço de e-mail válido.');
      return;
    }

    final provider = context.read<ConfiguracaoProvider>();
    final atual = provider.configuracao ?? const ConfiguracaoModel();
    final sucesso = await provider.salvar(atual.copyWith(emailSuporte: email));

    if (!mounted) return;

    _mensagem(
      sucesso
          ? 'E-mail de suporte salvo com sucesso.'
          : provider.errorMessage ?? 'Não foi possível salvar o e-mail.',
      erro: !sucesso,
    );

    if (sucesso) {
      _emailSuporteController.text =
          provider.configuracao?.emailSuporte ?? email;
    }
  }

  Future<void> _abrirEmail({
    required String assunto,
    required String corpo,
  }) async {
    final destinatario =
        context
            .read<ConfiguracaoProvider>()
            .configuracao
            ?.emailSuporte
            .trim() ??
        '';

    if (destinatario.isEmpty ||
        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(destinatario)) {
      _mensagem(
        'O e-mail de suporte ainda não foi configurado. Solicite ao administrador que cadastre o endereço nesta página.',
        erro: true,
      );
      return;
    }

    // mailto usa percent-encoding (RFC 6068). Uri(queryParameters:)
    // codifica espaços como '+', o que alguns clientes Android/Gmail
    // exibem literalmente. encodeComponent preserva os espaços como %20.
    final corpoNormalizado = corpo
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .replaceAll('\n', '\r\n');

    final uri = Uri.parse(
      'mailto:$destinatario'
      '?subject=${Uri.encodeComponent(assunto)}'
      '&body=${Uri.encodeComponent(corpoNormalizado)}',
    );

    try {
      final abriu = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!mounted) return;
      if (!abriu) {
        _mensagem(
          'Não foi possível abrir um aplicativo de e-mail neste dispositivo.',
          erro: true,
        );
      }
    } catch (_) {
      if (mounted) {
        _mensagem(
          'Não foi possível abrir um aplicativo de e-mail neste dispositivo.',
          erro: true,
        );
      }
    }
  }

  void _enviarRelato() {
    if (!_formKey.currentState!.validate()) return;

    final usuario = context.read<AuthProvider>().usuario;
    final corpo =
        'Olá, equipe TecAssist!\n\n'
        'Gostaria de relatar o seguinte problema:\n\n'
        '${_descricaoController.text.trim()}\n\n'
        'Usuário: ${usuario?.nome ?? 'Não informado'}\n'
        'E-mail da conta: ${usuario?.email ?? 'Não informado'}\n\n'
        'Enviado pelo TecAssist Controle.';

    _abrirEmail(assunto: _assuntoController.text.trim(), corpo: corpo);
  }

  void _mensagem(String texto, {bool erro = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(texto),
          backgroundColor: erro ? AppColors.error : null,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final configuracaoProvider = context.watch<ConfiguracaoProvider>();
    final somenteLeitura = !auth.isAdmin;
    final emailConfigurado =
        configuracaoProvider.configuracao?.emailSuporte.trim().isNotEmpty ==
        true;

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
              'SAC',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        bottomNavigationBar: const AppBottomNavigation(),
        body: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            _card(
              icone: Icons.headset_mic_outlined,
              titulo: 'Contato com o suporte',
              descricao:
                  'Entre em contato com a equipe do TecAssist para tirar dúvidas ou solicitar ajuda.',
              filho: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (emailConfigurado)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        'E-mail: ${configuracaoProvider.configuracao!.emailSuporte}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    )
                  else
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Text(
                        'O endereço de suporte ainda não foi cadastrado.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _abrirEmail(
                        assunto: 'Contato - TecAssist Controle',
                        corpo:
                            'Olá, equipe TecAssist!\n\nGostaria de entrar em contato sobre o aplicativo.',
                      ),
                      icon: const Icon(Icons.email_outlined),
                      label: const Text('Enviar e-mail ao suporte'),
                    ),
                  ),
                ],
              ),
            ),
            if (auth.isAdmin) ...[
              const SizedBox(height: 14),
              _card(
                icone: Icons.alternate_email_outlined,
                titulo: 'E-mail da equipe de suporte',
                descricao:
                    'Cadastre o endereço que receberá as mensagens de contato e os relatos de problemas. Essa informação ficará compartilhada com os funcionários.',
                filho: Column(
                  children: [
                    TextFormField(
                      controller: _emailSuporteController,
                      enabled:
                          _emailCarregado && !configuracaoProvider.isSaving,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(
                        labelText: 'E-mail de suporte',
                        hintText: 'suporte@empresa.com',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed:
                            !_emailCarregado || configuracaoProvider.isSaving
                            ? null
                            : _salvarEmailSuporte,
                        icon: configuracaoProvider.isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save_outlined),
                        label: const Text('Salvar e-mail de suporte'),
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (!_emailCarregado || configuracaoProvider.isLoading) ...[
              const SizedBox(height: 14),
              const Center(child: CircularProgressIndicator()),
            ],
            const SizedBox(height: 14),
            _card(
              icone: Icons.bug_report_outlined,
              titulo: 'Relatar um problema',
              descricao:
                  'Descreva o que aconteceu. O aplicativo abrirá seu e-mail com as informações preenchidas para você revisar e enviar.',
              filho: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _assuntoController,
                      maxLength: 120,
                      decoration: const InputDecoration(
                        labelText: 'Assunto',
                        prefixIcon: Icon(Icons.subject_outlined),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Informe o assunto.'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descricaoController,
                      minLines: 5,
                      maxLines: 8,
                      maxLength: 3000,
                      decoration: const InputDecoration(
                        labelText: 'Descreva o problema',
                        alignLabelWithHint: true,
                        prefixIcon: Icon(Icons.description_outlined),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Descreva o problema antes de continuar.'
                          : null,
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _enviarRelato,
                        icon: const Icon(Icons.send_outlined),
                        label: const Text('Preparar e-mail'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            _card(
              icone: Icons.info_outline,
              titulo: 'Sobre o aplicativo',
              descricao:
                  'TecAssist Controle é um aplicativo desenvolvido para apoiar a gestão de assistências técnicas, reunindo em um único sistema as principais rotinas de atendimento e organização.',
              filho: const _SobreAplicativo(),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _card({
    required IconData icone,
    required String titulo,
    required String descricao,
    required Widget filho,
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
              Icon(icone, color: AppColors.primary, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            descricao,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          filho,
        ],
      ),
    );
  }
}

class _SobreAplicativo extends StatelessWidget {
  const _SobreAplicativo();

  static const funcionalidades = <(IconData, String)>[
    (Icons.people_outline, 'Gestão de clientes e usuários'),
    (Icons.build_outlined, 'Controle de ordens de serviço'),
    (Icons.calendar_month_outlined, 'Gerenciamento de agendamentos'),
    (Icons.inventory_2_outlined, 'Controle de estoque e movimentações'),
    (Icons.notifications_none_outlined, 'Notificações e acompanhamento'),
    (Icons.chat_bubble_outline, 'Integração com WhatsApp'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Principais funcionalidades',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 12),
        ...funcionalidades.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 11),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(item.$1, color: AppColors.textSecondary, size: 19),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.$2,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 24),
        const Text(
          'Informações do projeto',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 8),
        const _ProjetoLinha(texto: 'Projeto: TecAssist'),
        const _ProjetoLinha(texto: 'Instituição: UNIGRAN'),
        const _ProjetoLinha(
          texto: 'Finalidade: Trabalho de Conclusão de Curso (TCC)',
        ),
        const _ProjetoLinha(texto: 'Desenvolvido em: 2026'),
        const Divider(height: 28),
        const Align(
          alignment: Alignment.centerRight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'TecAssist © 2026',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              SizedBox(height: 4),
              Text(
                'Todos os direitos reservados.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProjetoLinha extends StatelessWidget {
  final String texto;

  const _ProjetoLinha({required this.texto});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•  ', style: TextStyle(color: AppColors.textPrimary)),
          Expanded(
            child: Text(
              texto,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
