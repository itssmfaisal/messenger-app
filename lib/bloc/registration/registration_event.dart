abstract class RegistrationEvent {}

class RegistrationSubmitted extends RegistrationEvent {
  final String username;
  final String email;
  final String password;

  RegistrationSubmitted({
    required this.username,
    required this.email,
    required this.password,
  });
}
