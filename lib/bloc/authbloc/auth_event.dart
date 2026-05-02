import 'package:equatable/equatable.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

final class AppStarted extends AuthEvent {}

final class LoggedIn extends AuthEvent {}

final class LoggedOut extends AuthEvent {}
