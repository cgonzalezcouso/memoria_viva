import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/user_role.dart';
import '../../core/providers/auth_providers.dart';
import '../../core/router/app_router.dart';
import '../../shared/widgets/info_banner.dart';
import '../../shared/widgets/section_header.dart';

class LinkPatientScreen extends ConsumerStatefulWidget {
  const LinkPatientScreen({super.key});

  @override
  ConsumerState<LinkPatientScreen> createState() => _LinkPatientScreenState();
}

class _LinkPatientScreenState extends ConsumerState<LinkPatientScreen> {
  final _formKey = GlobalKey<FormState>();
  final _patientIdController = TextEditingController();
  bool _isLinking = false;

  @override
  void dispose() {
    _patientIdController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLinking = true);

    try {
      await ref.read(authControllerProvider.notifier).linkPatient(
            _patientIdController.text,
          );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Persona vinculada correctamente')),
      );
      _patientIdController.clear();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) setState(() => _isLinking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider).value;
    final linkedPatients = ref.watch(linkedPatientsProvider);

    if (auth?.profile?.role != UserRole.caregiver) {
      return Scaffold(
        appBar: AppBar(title: const Text('Vincular persona')),
        body: const Padding(
          padding: EdgeInsets.all(20),
          child: InfoBanner(
            message: 'Solo los cuidadores pueden vincular personas.',
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Vincular persona')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SectionHeader(
              title: 'Conecta con la persona a tu cuidado',
              description:
                  'Pide el código de vinculación en la pantalla de perfil '
                  'de la persona. Así podrás ver su progreso y rutinas.',
            ),
            const SizedBox(height: 16),
            const InfoBanner(
              icon: Icons.link,
              message:
                  'El código es un identificador único. '
                  'Cópialo desde el perfil de la persona.',
            ),
            const SizedBox(height: 24),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _patientIdController,
                    decoration: const InputDecoration(
                      labelText: 'Código de vinculación',
                      prefixIcon: Icon(Icons.qr_code_2_outlined),
                      helperText: 'Pega el código completo',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().length < 8) {
                        return 'Código no válido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLinking ? null : _submit,
                      child: _isLinking
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Vincular'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Personas vinculadas',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            linkedPatients.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => const Text('No se pudieron cargar los vínculos.'),
              data: (patients) {
                if (patients.isEmpty) {
                  return const Text('Aún no has vinculado a ninguna persona.');
                }

                return Column(
                  children: patients
                      .map(
                        (patient) => Card(
                          child: ListTile(
                            leading: const Icon(Icons.person),
                            title: Text(patient.fullName),
                            subtitle: Text(patient.id),
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => context.go(AppRoutes.home),
                child: const Text('Ir al inicio'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
