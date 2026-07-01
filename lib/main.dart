import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'data/event_repository.dart';
import 'ui/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('it', null); // nomi mesi/giorni in italiano
  await eventRepository.load(); // ripristina gli eventi salvati
  runApp(const AuraApp());
}

/// Palette e tipografia pensate per l'uso in stato post-critico: alto contrasto,
/// testo grande, target touch ampi. L'accessibilità qui non è un extra, è il
/// requisito centrale (l'utente può essere confuso o poco coordinato).
class AuraApp extends StatelessWidget {
  const AuraApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Viola: colore simbolo della consapevolezza sull'epilessia.
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF6A3EA1),
      brightness: Brightness.light,
    );
    final base = ThemeData(colorScheme: scheme, useMaterial3: true);

    return MaterialApp(
      title: 'Aura',
      debugShowCheckedModeBanner: false,
      // Testo più grande di default (accessibilità) via TextScaler: è il
      // meccanismo sicuro, non altera gli stili con fontSize nullo di M3.
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(textScaler: const TextScaler.linear(1.15)),
          child: child!,
        );
      },
      theme: base.copyWith(
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(64),
            textStyle:
                const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
