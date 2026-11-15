import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:memoria_viva/core/providers/auth_providers.dart';
import 'package:memoria_viva/core/services/auth_service.dart';
import 'package:memoria_viva/features/auth/login_screen.dart';
import 'package:memoria_viva/features/auth/register_screen.dart';

class _ReadyAuthController extends AuthController {
  @override
  Future<AuthState> build() async => const AuthState();
}

void main() {
  testWidgets('Login muestra correo y contraseña', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(_ReadyAuthController.new),
        ],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(find.text('Correo electrónico'), findsOneWidget);
    expect(find.text('Contraseña'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
  });

  testWidgets('Registro muestra perfiles y campos', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(_ReadyAuthController.new),
        ],
        child: const MaterialApp(home: RegisterScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Crear cuenta'), findsWidgets);
    expect(find.text('Persona con deterioro cognitivo'), findsOneWidget);
    expect(find.text('Cuidador o familiar'), findsOneWidget);
    expect(find.text('Nombre completo'), findsOneWidget);
    expect(find.text('Correo electrónico'), findsOneWidget);
    expect(find.text('Contraseña'), findsOneWidget);
  });
}
