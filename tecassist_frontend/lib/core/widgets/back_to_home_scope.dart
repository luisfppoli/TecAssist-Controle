import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BackToHomeScope extends StatelessWidget {
  final Widget child;

  const BackToHomeScope({super.key, required this.child});

  String _rotaDeRetorno(BuildContext context) {
    final caminho = GoRouterState.of(context).uri.path;

    if (caminho.startsWith('/clientes')) {
      return '/app/clientes';
    }

    if (caminho.startsWith('/agendamentos')) {
      return '/app/agenda';
    }

    if (caminho.startsWith('/servicos')) {
      return '/app/servicos';
    }

    if (caminho.startsWith('/estoque')) {
      return '/app/estoque';
    }

    return '/app/home';
  }

  @override
  Widget build(BuildContext context) {
    final podeVoltar = context.canPop();

    return PopScope(
      canPop: podeVoltar,

      onPopInvoked: (didPop) {
        if (didPop) return;

        context.go(_rotaDeRetorno(context));
      },

      child: child,
    );
  }
}
