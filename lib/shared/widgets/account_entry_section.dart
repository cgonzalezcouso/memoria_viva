import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import 'section_header.dart';

/// Acceso directo a registro e inicio de sesión (sin configuración técnica).
class AccountEntrySection extends StatelessWidget {
  const AccountEntrySection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader(
          title: 'Tu cuenta',
          description:
              'Crea una cuenta con tu correo y contraseña, '
              'o inicia sesión si ya te registraste.',
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => context.push(AppRoutes.register),
            icon: const Icon(Icons.person_add_outlined),
            label: const Text('Crear cuenta'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => context.go(AppRoutes.login),
            icon: const Icon(Icons.login),
            label: const Text('Iniciar sesión'),
          ),
        ),
      ],
    );
  }
}
