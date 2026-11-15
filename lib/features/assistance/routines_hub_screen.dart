import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/app_providers.dart';
import '../../core/router/app_router.dart';
import '../../shared/widgets/accessible_card.dart';
import '../../shared/widgets/section_header.dart';

class RoutinesHubScreen extends ConsumerWidget {
  const RoutinesHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCaregiver = ref.watch(isCaregiverProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Asistencia y rutinas'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SectionHeader(
            title: 'Organiza el día',
            description:
                'Rutinas claras, recordatorios y apoyo para mantener '
                'la autonomía y coordinar a la familia.',
          ),
          const SizedBox(height: 24),
          AccessibleCard(
            icon: Icons.checklist_rtl,
            title: 'Rutina diaria',
            subtitle: 'Marca las actividades completadas del día.',
            onTap: () => context.push(AppRoutes.dailyRoutine),
          ),
          const SizedBox(height: 16),
          AccessibleCard(
            icon: Icons.medication_outlined,
            title: 'Medicación',
            subtitle: 'Consulta horarios y activa recordatorios.',
            onTap: () => context.push(AppRoutes.medication),
          ),
          if (isCaregiver) ...[
            const SizedBox(height: 16),
            AccessibleCard(
              icon: Icons.edit_calendar,
              title: 'Personalizar cuidados',
              subtitle: 'Configura rutinas y medicación de la persona.',
              color: const Color(0xFF5C4B8A),
              onTap: () => context.push(AppRoutes.manageCare),
            ),
          ],
          const SizedBox(height: 16),
          AccessibleCard(
            icon: Icons.family_restroom_outlined,
            title: 'Panel del cuidador',
            subtitle: 'Revisa progreso cognitivo y estado de rutinas.',
            onTap: () => context.push(AppRoutes.caregiver),
          ),
        ],
      ),
    );
  }
}
