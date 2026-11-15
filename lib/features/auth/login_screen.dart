import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/auth_providers.dart';
import 'auth_error_message.dart';
import '../../core/router/app_router.dart';
import '../../shared/widgets/section_header.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _repairingProfile = false;
  String? _profileError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = ref.read(authControllerProvider).value;
      if (auth?.needsProfile ?? false) {
        _repairProfile();
      }
    });
  }

  Future<void> _repairProfile() async {
    if (_repairingProfile) return;
    setState(() {
      _repairingProfile = true;
      _profileError = null;
    });
    final error =
        await ref.read(authControllerProvider.notifier).ensureProfileLoaded();
    if (!mounted) return;
    setState(() {
      _repairingProfile = false;
      _profileError = error;
    });
    _goHomeIfReady();
  }

  Future<void> _signOutAndReset() async {
    await ref.read(authControllerProvider.notifier).signOut();
    if (!mounted) return;
    setState(() => _profileError = null);
  }

  void _goHomeIfReady() {
    final auth = ref.read(authControllerProvider).value;
    if (auth?.session != null && auth?.profile != null) {
      context.go(AppRoutes.home);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    await ref.read(authControllerProvider.notifier).signIn(
          _emailController.text,
          _passwordController.text,
        );

    if (!mounted) return;

    final auth = ref.read(authControllerProvider);
    if (auth.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authErrorMessage(auth.error))),
      );
      return;
    }

    _goHomeIfReady();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final isLoading = auth.isLoading || _repairingProfile;

    ref.listen(authControllerProvider, (previous, next) {
      next.whenData((state) {
        if (state.session != null && state.profile != null && mounted) {
          context.go(AppRoutes.home);
        }
      });
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Iniciar sesión')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Image.asset(
              'assets/branding/app_icon.png',
              width: 120,
              height: 120,
            ),
            const SizedBox(height: 20),
            const SectionHeader(
              title: 'Accede a tu cuenta',
              description:
                  'Inicia sesión para sincronizar rutinas, progreso '
                  'cognitivo y apoyo entre familiares.',
            ),
            if (auth.value?.needsProfile ?? false) ...[
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      if (_repairingProfile)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: CircularProgressIndicator(),
                        ),
                      Text(
                        _profileError ??
                            'Tu sesión está activa pero falta el perfil. '
                            'Estamos recuperándolo…',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: _profileError != null
                                  ? Theme.of(context).colorScheme.error
                                  : null,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Si no tienes red estable, cierra sesión y vuelve '
                        'a entrar cuando el móvil tenga internet.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: _repairingProfile ? null : _repairProfile,
                        child: const Text('Reintentar'),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _repairingProfile ? null : _signOutAndReset,
                        child: const Text('Cerrar sesión'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    decoration: const InputDecoration(
                      labelText: 'Correo electrónico',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Escribe tu correo';
                      }
                      if (!value.contains('@')) {
                        return 'Correo no válido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.length < 6) {
                        return 'Mínimo 6 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _submit,
                      child: isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Entrar'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () => context.push(AppRoutes.register),
              child: const Text('¿No tienes cuenta? Regístrate'),
            ),
          ],
        ),
      ),
    );
  }
}
