import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/providers/app_startup_provider.dart';
import 'core/providers/report_email_providers.dart';

/// Arranque: muestra la UI enseguida e inicializa servicios en segundo plano.
class AppBootstrap extends ConsumerWidget {
  const AppBootstrap({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final startup = ref.watch(appStartupProvider);

    return startup.when(
      loading: () => MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: const Color(0xFFF7F4EF),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/branding/app_icon.png',
                  width: 180,
                  height: 180,
                ),
                const SizedBox(height: 24),
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'Iniciando Memoria Viva…',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
        ),
      ),
      error: (_, _) {
        ref.watch(autoSendWeeklyReportProvider);
        return const MemoriaVivaApp();
      },
      data: (_) {
        ref.watch(autoSendWeeklyReportProvider);
        return const MemoriaVivaApp();
      },
    );
  }
}
