/// Mensajes de error legibles para pantallas de autenticación.
String authErrorMessage(Object? error) {
  if (error == null) return 'Ha ocurrido un error. Inténtalo de nuevo.';

  final text = error.toString().toLowerCase();

  if (text.contains('host lookup') ||
      text.contains('socketexception') ||
      text.contains('authretryablefetchexception') ||
      text.contains('failed host lookup') ||
      text.contains('no address associated') ||
      text.contains('network is unreachable') ||
      text.contains('connection refused') ||
      text.contains('connection timed out') ||
      (text.contains('refresh_token') && text.contains('clientexception'))) {
    return 'No se puede conectar con el servidor. '
        'Comprueba Wi‑Fi o datos móviles, desactiva la VPN si la usas '
        'e inténtalo de nuevo.';
  }

  if (text.contains('invalid login credentials') ||
      text.contains('invalid_credentials')) {
    return 'Correo o contraseña incorrectos.';
  }

  if (text.contains('user already registered') ||
      text.contains('already been registered')) {
    return 'Ya existe una cuenta con ese correo. Prueba a iniciar sesión.';
  }

  if (text.contains('email not confirmed')) {
    return 'Confirma tu correo antes de iniciar sesión (revisa la bandeja de entrada).';
  }

  if (text.contains('password') && text.contains('weak')) {
    return 'La contraseña es demasiado débil. Usa al menos 6 caracteres.';
  }

  return error.toString().replaceFirst('Exception: ', '');
}
