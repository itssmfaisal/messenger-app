import 'package:equatable/equatable.dart';

sealed class RegistrationState extends Equatable {
  const RegistrationState();

  @override
  List<Object?> get props => [];
}

final class RegistrationInitial extends RegistrationState {}

final class RegistrationLoading extends RegistrationState {}

final class RegistrationError extends RegistrationState {
  final String message;

  const RegistrationError(this.message);

  @override
  List<Object?> get props => [message];
}

final class RegistrationSuccess extends RegistrationState {
  final String username;

  const RegistrationSuccess(this.username);

  @override
  List<Object?> get props => [username];
}
