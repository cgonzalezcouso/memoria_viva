import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/user_role.dart';
import '../../core/providers/auth_providers.dart';
import '../../core/router/app_router.dart';
import '../../shared/widgets/account_entry_section.dart';
import '../../shared/widgets/info_banner.dart';
import '../../shared/widgets/section_header.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider).value;
    final theme = Theme.of(context);

    if (auth == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (auth.isGuest) {
      return Scaffold(
        appBar: AppBar(title: const Text('Perfil')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SectionHeader(
              title: 'Modo local',
              description:
                  'Sin cuenta activa. Los datos se guardan solo '
                  'en este dispositivo.',
            ),
            const SizedBox(height: 20),
            const AccountEntrySection(),
            const SizedBox(height: 24),
            const _AccessibilityButton(),
          ],
        ),
      );
    }

    final profile = auth.profile;
    if (profile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Perfil')),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('No se pudo cargar el perfil.'),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await ref.read(authControllerProvider.notifier).signOut();
                      if (context.mounted) context.go(AppRoutes.login);
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Cerrar sesión'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Mi perfil')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Icon(
              profile.role == UserRole.patient
                  ? Icons.person
                  : Icons.family_restroom,
              size: 40,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(profile.fullName, style: theme.textTheme.headlineMedium),
          Text(profile.role.label, style: theme.textTheme.titleMedium),
          if (auth.session?.user.email != null) ...[
            const SizedBox(height: 8),
            Text(
              auth.session!.user.email!,
              style: theme.textTheme.bodyLarge,
            ),
          ],
          const SizedBox(height: 24),
          if (profile.role == UserRole.patient) ...[
            const InfoBanner(
              icon: Icons.share_outlined,
              message:
                  'Comparte este código con tu cuidador o familiar '
                  'para que pueda ver tu progreso.',
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                title: const Text('Código de vinculación'),
                subtitle: SelectableText(
                  profile.id,
                  style: theme.textTheme.bodyMedium,
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.copy),
                  tooltip: 'Copiar código',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: profile.id));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Código copiado')),
                    );
                  },
                ),
              ),
            ),
          ],
          if (profile.role == UserRole.caregiver) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.push(AppRoutes.linkPatient),
                icon: const Icon(Icons.link),
                label: const Text('Vincular persona'),
              ),
            ),
            const SizedBox(height: 12),
            _LinkedPatientsSection(),
          ],
          const SizedBox(height: 24),
          const _AccessibilityButton(),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                await ref.read(authControllerProvider.notifier).signOut();
                if (context.mounted) context.go(AppRoutes.login);
              },
              icon: const Icon(Icons.logout),
              label: const Text('Cerrar sesión'),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccessibilityButton extends StatelessWidget {
  const _AccessibilityButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => context.push(AppRoutes.accessibility),
        icon: const Icon(Icons.accessibility_new),
        label: const Text('Accesibilidad'),
      ),
    );
  }
}

class _LinkedPatientsSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final linkedPatients = ref.watch(linkedPatientsProvider);
    final theme = Theme.of(context);
    final selectedId = ref.watch(selectedPatientIdProvider);

    return linkedPatients.when(
      loading: () => const CircularProgressIndicator(),
      error: (_, _) => const SizedBox.shrink(),
      data: (patients) {
        if (patients.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Persona activa', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            ...patients.map(
              (patient) {
                final isSelected =
                    (selectedId ?? patients.first.id) == patient.id;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(
                      isSelected ? Icons.check_circle : Icons.circle_outlined,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline,
                    ),
                    title: Text(patient.fullName),
                    onTap: () {
                      ref
                          .read(selectedPatientIdProvider.notifier)
                          .select(patient.id);
                    },
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
