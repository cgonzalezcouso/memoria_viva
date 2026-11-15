import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/auth_providers.dart';
import '../../core/router/app_router.dart';
import '../../shared/widgets/account_entry_section.dart';
import '../../shared/widgets/active_patient_banner.dart';
import '../../shared/widgets/accessible_card.dart';
import '../../shared/widgets/info_banner.dart';
import '../../shared/widgets/section_header.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider).value;
    final profileName = auth?.profile?.fullName;
    final greeting = profileName != null ? 'Hola, $profileName' : 'Bienvenido';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Memoria Viva'),
        actions: [
          IconButton(
            icon: const Icon(Icons.accessibility_new),
            tooltip: 'Accesibilidad',
            onPressed: () => context.push(AppRoutes.accessibility),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Mi perfil',
            onPressed: () => context.push(AppRoutes.profile),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            SectionHeader(
              title: greeting,
              description:
                  'Herramientas sencillas para entrenar la mente, '
                  'organizar el día y apoyar a cuidadores y familiares.',
            ),
            const SizedBox(height: 20),
            if (auth?.isGuest ?? false) ...[
              const AccountEntrySection(),
              const SizedBox(height: 20),
            ],
            const ActivePatientBanner(),
            const SizedBox(height: 12),
            const InfoBanner(
              message:
                  'Diseñado con botones grandes, textos claros y '
                  'navegación simple para facilitar el uso diario.',
            ),
            const SizedBox(height: 28),
            AccessibleCard(
              icon: Icons.psychology_outlined,
              title: 'Estimulación cognitiva',
              subtitle:
                  'Juegos de memoria, atención y orientación para '
                  'entrenar habilidades mentales.',
              color: const Color(0xFF2E7D5A),
              onTap: () => context.push(AppRoutes.stimulation),
            ),
            const SizedBox(height: 16),
            AccessibleCard(
              icon: Icons.calendar_today_outlined,
              title: 'Asistencia y rutinas',
              subtitle:
                  'Rutinas diarias, recordatorios de medicación '
                  'y panel para cuidadores.',
              color: const Color(0xFF8B5A2B),
              onTap: () => context.push(AppRoutes.routines),
            ),
          ],
        ),
      ),
    );
  }
}
