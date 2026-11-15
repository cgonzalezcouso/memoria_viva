enum UserRole {
  patient('persona', 'Persona con deterioro cognitivo'),
  caregiver('cuidador', 'Cuidador o familiar');

  const UserRole(this.value, this.label);

  final String value;
  final String label;

  static UserRole fromValue(String value) {
    return UserRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => UserRole.patient,
    );
  }
}
