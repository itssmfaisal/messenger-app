import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:messenger_app/bloc/authbloc/auth_event.dart';
import 'package:messenger_app/bloc/authbloc/auth_state.dart';
import 'package:messenger_app/data/models/sources/auth_service.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService authService;

  AuthBloc(this.authService) : super(AuthInitial()) {
    on<AppStarted>((event, emit) async {
      final token = await authService.getToken();
      if (token != null && token.isNotEmpty) {
        emit(Authenticated());
      } else {
        emit(Unauthenticated());
      }
    });

    on<LoggedIn>((event, emit) => emit(Authenticated()));
    on<LoggedOut>((event, emit) async {
      await authService.logout();
      emit(Unauthenticated());
    });
  }
}
