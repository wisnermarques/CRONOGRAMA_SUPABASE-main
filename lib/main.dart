import 'package:cronograma/core/supabase_helper.dart';
import 'package:cronograma/presentation/pages/Cronograma/cronograma_page.dart';
import 'package:cronograma/presentation/pages/Instrutores/instrutor_page_form.dart';
import 'package:cronograma/presentation/pages/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await SupabaseHelper.initialize();
    runApp(const MyApp());
  } catch (e) {
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Erro ao conectar com o banco de dados: $e'),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gestão de Cronogramas SENAC',

      // Internacionalização
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pt', 'BR'),
      ],

      // Tema
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 2,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),

      // Tela inicial
      home: const SplashScreen(),

      // Rotas nomeadas
      routes: {
        '/cadatro': (context) => const CadastroInstrutorPage(),
        '/cronograma': (context) => const CronogramaPage(),

      },

      locale: const Locale('pt', 'BR'),
    );
  }
}
