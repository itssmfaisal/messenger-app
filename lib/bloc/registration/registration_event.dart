import 'package:equatable/equatable.dart';

sealed class RegistrationEvent extends Equatable {
  const RegistrationEvent();

  @override
  List<Object?> get props => [];
}

final class RegistrationSubmitted extends RegistrationEvent {
  final String username;
  final String email;
  final String password;

  const RegistrationSubmitted({
    required this.username,
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [username, email, password];
}
