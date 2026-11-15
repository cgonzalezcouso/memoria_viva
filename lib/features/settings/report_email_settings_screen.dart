import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/env.dart';
import '../../core/models/report_email_settings.dart';
import '../../core/providers/auth_providers.dart';
import '../../core/providers/report_email_providers.dart';
import '../../core/router/app_router.dart';
import '../../shared/widgets/info_banner.dart';
import '../../shared/widgets/section_header.dart';

class ReportEmailSettingsScreen extends ConsumerStatefulWidget {
  const ReportEmailSettingsScreen({super.key});

  @override
  ConsumerState<ReportEmailSettingsScreen> createState() =>
      _ReportEmailSettingsScreenState();
}

class _ReportEmailSettingsScreenState
    extends ConsumerState<ReportEmailSettingsScreen> {
  final _emailController = TextEditingController();
  bool _autoSend = false;
  bool _loaded = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final patientId = ref.read(activePatientIdProvider);
    final settings = ReportEmailSettings(
      patientId: patientId,
      recipientEmail: _emailController.text.trim(),
      autoSendWeekly: _autoSend,
    );

    await ref.read(reportEmailSettingsServiceProvider).save(settings);
    ref.invalidate(reportEmailSettingsProvider);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configuración guardada')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(reportEmailSettingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Envío de informes')),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(child: Text('Error al cargar ajustes')),
        data: (settings) {
          if (!_loaded) {
            _emailController.text = settings.recipientEmail;
            _autoSend = settings.autoSendWeekly;
            _loaded = true;
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const SectionHeader(
                title: 'Informe semanal por correo',
                description:
                    'Envía el PDF del informe a un familiar o cuidador. '
                    'Con envío automático, se mandará cada 7 días al abrir la app.',
              ),
              if (!Env.isSupabaseConfigured) ...[
                const SizedBox(height: 16),
                const InfoBanner(
                  message:
                      'El envío por correo requiere Supabase y la función '
                      'send-weekly-report con Resend configurado.',
                ),
              ],
              const SizedBox(height: 20),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Correo del destinatario',
                  prefixIcon: Icon(Icons.email_outlined),
                  helperText: 'Ej.: familiar o cuidador principal',
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Envío automático semanal'),
                subtitle: const Text(
                  'Al abrir la app, envía el informe si han pasado 7 días.',
                ),
                value: _autoSend,
                onChanged: (value) => setState(() => _autoSend = value),
              ),
              if (settings.lastSentAt != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Último envío: ${settings.lastSentAt!.toLocal()}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  child: const Text('Guardar configuración'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => context.push(AppRoutes.weeklyReport),
                  child: const Text('Ir al informe semanal'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
