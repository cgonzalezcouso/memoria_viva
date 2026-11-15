import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/user_role.dart';
import '../../core/providers/auth_providers.dart';
import '../../core/router/app_router.dart';

class ActivePatientBanner extends ConsumerWidget {
  const ActivePatientBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider).value;
    if (auth == null || auth.isGuest || auth.profile?.role != UserRole.caregiver) {
      return const SizedBox.shrink();
    }

    final linkedAsync = ref.watch(linkedPatientsProvider);
    final activeId = ref.watch(activePatientIdProvider);

    return linkedAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (patients) {
        if (patients.isEmpty) {
          return Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: ListTile(
              leading: const Icon(Icons.link_off),
              title: const Text('Sin persona vinculada'),
              subtitle: const Text(
                'Vincula una persona para ver su progreso y rutinas.',
              ),
              trailing: TextButton(
                onPressed: () => context.push(AppRoutes.linkPatient),
                child: const Text('Vincular'),
              ),
            ),
          );
        }

        final match = patients.where((patient) => patient.id == activeId);
        final activeName = match.isEmpty ? null : match.first.fullName;

        return Card(
          child: ListTile(
            leading: const Icon(Icons.person_pin_outlined),
            title: const Text('Persona activa'),
            subtitle: Text(activeName ?? patients.first.fullName),
            trailing: TextButton(
              onPressed: () => context.push(AppRoutes.profile),
              child: const Text('Cambiar'),
            ),
          ),
        );
      },
    );
  }
}
