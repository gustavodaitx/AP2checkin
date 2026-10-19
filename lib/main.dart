import 'package:flutter/material.dart';
import 'tela_principal.dart';

void main() {
  runApp(const AppCheckinEvento());
}

/// Aplicativo Flutter para a AP2 — App de Check-in de Evento
class AppCheckinEvento extends StatelessWidget {
  const AppCheckinEvento({super.key});

  @override
  Widget build(BuildContext context) {
    const corPrimaria = Color(0xFF00695C); // Verde-petróleo

    return MaterialApp(
      title: 'Semana da Computação 2026',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: corPrimaria,
          primary: corPrimaria,
          surface: const Color(0xFFF7FAF9),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: corPrimaria,
          foregroundColor: Colors.white,
          elevation: 2,
          centerTitle: true,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      home: const TelaPrincipal(),
    );
  }
}
