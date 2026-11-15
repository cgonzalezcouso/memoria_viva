import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/accessibility_settings.dart';
import '../../core/providers/accessibility_providers.dart';
import '../../shared/widgets/info_banner.dart';
import '../../shared/widgets/section_header.dart';

class AccessibilitySettingsScreen extends ConsumerWidget {
  const AccessibilitySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(accessibilitySettingsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Accesibilidad')),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(
          child: Text('No se pudieron cargar los ajustes.'),
        ),
        data: (settings) {
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const SectionHeader(
                title: 'Adapta la app a tus necesidades',
                description:
                    'Ajusta el contraste y el tamaño del texto '
                    'para una lectura más cómoda.',
              ),
              const SizedBox(height: 20),
              const InfoBanner(
                icon: Icons.visibility_outlined,
                message:
                    'Los cambios se aplican al instante y se guardan '
                    'en este dispositivo.',
              ),
              const SizedBox(height: 24),
              Text('Alto contraste', style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Activar alto contraste'),
                subtitle: const Text(
                  'Colores más intensos y bordes marcados para mejor legibilidad.',
                ),
                value: settings.highContrast,
                onChanged: (value) {
                  ref
                      .read(accessibilitySettingsProvider.notifier)
                      .setHighContrast(value);
                },
              ),
              const SizedBox(height: 24),
              Text('Tamaño del texto', style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              ...TextSizeOption.values.map(
                (option) {
                  final isSelected = settings.textSize == option;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Icon(
                        isSelected ? Icons.check_circle : Icons.circle_outlined,
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline,
                      ),
                      title: Text(option.label),
                      subtitle: Text('Escala ${option.scaleFactor}x'),
                      onTap: () {
                        ref
                            .read(accessibilitySettingsProvider.notifier)
                            .setTextSize(option);
                      },
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              Text('Vista previa', style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ejemplo de título',
                        style: theme.textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Este es un texto de ejemplo para comprobar '
                        'el tamaño y contraste seleccionados.',
                        style: theme.textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {},
                          child: const Text('Botón de ejemplo'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
