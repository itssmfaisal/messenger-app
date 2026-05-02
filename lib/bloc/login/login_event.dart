import 'package:equatable/equatable.dart';

sealed class LoginEvent extends Equatable {
  const LoginEvent();

  @override
  List<Object?> get props => [];
}

final class LoginSubmitted extends LoginEvent {
  final String username;
  final String password;

  const LoginSubmitted(this.username, this.password);

  @override
  List<Object?> get props => [username, password];
}
