import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/consulta/views/consulta_status_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const apiBaseUrl = String.fromEnvironment('API_URL');

  runApp(ConsultaPublicaApp(apiBaseUrl: apiBaseUrl));
}

class ConsultaPublicaApp extends StatelessWidget {
  final String apiBaseUrl;

  const ConsultaPublicaApp({super.key, required this.apiBaseUrl});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Consulta de Serviço | TecAssist',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: ConsultaStatusPage(apiBaseUrl: apiBaseUrl),
    );
  }
}
