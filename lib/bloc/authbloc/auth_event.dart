abstract class AuthEvent {}

class AppStarted extends AuthEvent {} // triggered on main.dart load

class LoggedIn extends AuthEvent {}

class LoggedOut extends AuthEvent {}
