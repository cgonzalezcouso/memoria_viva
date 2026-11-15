import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../shared/widgets/info_banner.dart';

class MedicationReminderScreen extends ConsumerWidget {
  const MedicationReminderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final medicationsAsync = ref.watch(medicationsProvider);
    final notificationsAsync = ref.watch(notificationsEnabledProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Medicación')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Recordatorios del día',
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Consulta con tu médico antes de modificar cualquier tratamiento.',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 20),
          notificationsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
            data: (enabled) => SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Recordatorios en el dispositivo',
                style: theme.textTheme.titleMedium,
              ),
              subtitle: const Text(
                'Recibe un aviso a la hora de cada medicamento.',
              ),
              value: enabled,
              onChanged: (value) async {
                final notificationService = ref.read(notificationServiceProvider);
                if (value) {
                  await notificationService.initialize();
                  final granted = await notificationService.requestPermissions();
                  if (!granted && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Se necesitan permisos de notificación'),
                      ),
                    );
                    return;
                  }
                }

                await notificationService.setRemindersEnabled(value);
                ref.invalidate(notificationsEnabledProvider);
                ref.invalidate(medicationsProvider);
              },
            ),
          ),
          const SizedBox(height: 16),
          medicationsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => const InfoBanner(
              message: 'No se pudieron cargar los medicamentos.',
            ),
            data: (medications) {
              if (medications.isEmpty) {
                return const InfoBanner(
                  message:
                      'No hay medicamentos configurados. '
                      'Un cuidador puede añadirlos desde Personalizar cuidados.',
                );
              }

              return Column(
                children: medications
                    .map(
                      (med) => Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.alarm,
                                    size: 32,
                                    color: theme.colorScheme.primary,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    med.scheduledTime,
                                    style: theme.textTheme.headlineMedium,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(med.name, style: theme.textTheme.titleLarge),
                              if (med.instructions != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  med.instructions!,
                                  style: theme.textTheme.bodyLarge,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
