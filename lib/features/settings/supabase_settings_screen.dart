import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/supabase_settings_providers.dart';
import '../../core/router/app_router.dart';
import '../../shared/widgets/info_banner.dart';
import '../../shared/widgets/section_header.dart';

class SupabaseSettingsScreen extends ConsumerStatefulWidget {
  const SupabaseSettingsScreen({super.key});

  @override
  ConsumerState<SupabaseSettingsScreen> createState() =>
      _SupabaseSettingsScreenState();
}

class _SupabaseSettingsScreenState extends ConsumerState<SupabaseSettingsScreen> {
  final _urlController = TextEditingController();
  final _anonKeyController = TextEditingController();
  bool _obscureKey = true;
  bool _fieldsInitialized = false;

  @override
  void dispose() {
    _urlController.dispose();
    _anonKeyController.dispose();
    super.dispose();
  }

  void _syncFields(SupabaseSettingsState settings) {
    if (_fieldsInitialized) return;
    _urlController.text = settings.url;
    _anonKeyController.text = settings.anonKey;
    _fieldsInitialized = true;
  }

  Future<void> _save() async {
    final error = await ref.read(supabaseSettingsProvider.notifier).save(
          url: _urlController.text,
          anonKey: _anonKeyController.text,
        );

    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      if (error.contains('Reinicia la app')) return;
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Conexión guardada. Inicia sesión.')),
    );
    context.go(AppRoutes.login);
  }

  Future<void> _clear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Borrar conexión'),
        content: const Text(
          'Se eliminarán las credenciales guardadas en este dispositivo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final message = await ref
        .read(supabaseSettingsProvider.notifier)
        .clearStoredConfig();

    if (!mounted) return;

    _fieldsInitialized = false;
    _urlController.clear();
    _anonKeyController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message ?? 'Conexión eliminada.'),
      ),
    );

    if (message == null) {
      context.go(AppRoutes.profile);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(supabaseSettingsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Conexión Supabase')),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(
          child: Text('No se pudieron cargar los ajustes.'),
        ),
        data: (settings) {
          _syncFields(settings);

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const SectionHeader(
                title: 'Conectar con la nube',
                description:
                    'Introduce la URL y la clave anónima de tu proyecto '
                    'Supabase para activar cuentas, sincronización e informes.',
              ),
              const SizedBox(height: 20),
              if (settings.isLockedByBuild) ...[
                const InfoBanner(
                  icon: Icons.lock_outline,
                  message:
                      'Las credenciales vienen definidas al compilar la app '
                      '(--dart-define) y no se pueden cambiar aquí.',
                ),
                const SizedBox(height: 20),
                _ReadOnlyField(label: 'URL del proyecto', value: settings.url),
                const SizedBox(height: 12),
                _ReadOnlyField(
                  label: 'Clave anónima',
                  value: _maskKey(settings.anonKey),
                ),
              ] else ...[
                const InfoBanner(
                  icon: Icons.cloud_outlined,
                  message:
                      'Los datos se guardan solo en este dispositivo. '
                      'Tras guardar podrás registrarte o iniciar sesión.',
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _urlController,
                  decoration: const InputDecoration(
                    labelText: 'URL del proyecto',
                    hintText: 'https://tu-proyecto.supabase.co',
                    prefixIcon: Icon(Icons.link),
                  ),
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  autofillHints: const [AutofillHints.url],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _anonKeyController,
                  decoration: InputDecoration(
                    labelText: 'Clave anónima (anon key)',
                    prefixIcon: const Icon(Icons.key_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureKey ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () => setState(() => _obscureKey = !_obscureKey),
                    ),
                  ),
                  obscureText: _obscureKey,
                  autocorrect: false,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save_outlined),
                    label: Text(settings.isConfigured ? 'Actualizar conexión' : 'Guardar y conectar'),
                  ),
                ),
                if (settings.isConfigured) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _clear,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Borrar conexión guardada'),
                    ),
                  ),
                ],
              ],
              const SizedBox(height: 24),
              Text(
                'Dónde encontrar estos datos',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'En Supabase: Project Settings → API → Project URL y anon public key.',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          );
        },
      ),
    );
  }

  String _maskKey(String key) {
    if (key.length <= 8) return '••••••••';
    return '${'•' * (key.length - 4)}${key.substring(key.length - 4)}';
  }
}

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        border: const OutlineInputBorder(),
      ),
      child: SelectableText(value),
    );
  }
}
