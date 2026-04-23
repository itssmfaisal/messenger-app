abstract class RegistrationState {}

class RegistrationInitial extends RegistrationState {}

class RegistrationLoading extends RegistrationState {}

class RegistrationError extends RegistrationState {
  final String message;
  RegistrationError(this.message);
}

class RegistrationSuccess extends RegistrationState {
  final String username;
  RegistrationSuccess(this.username);
}
