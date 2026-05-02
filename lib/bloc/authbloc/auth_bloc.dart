import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:messenger_app/bloc/authbloc/auth_event.dart';
import 'package:messenger_app/bloc/authbloc/auth_state.dart';
import 'package:messenger_app/domain/repositories/auth_repository.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _repository;

  AuthBloc(this._repository) : super(AuthInitial()) {
    on<AppStarted>((event, emit) async {
      final token = await _repository.getToken();
      if (token != null && token.isNotEmpty) {
        emit(Authenticated());
      } else {
        emit(Unauthenticated());
      }
    });

    on<LoggedIn>((event, emit) => emit(Authenticated()));
    on<LoggedOut>((event, emit) async {
      await _repository.logout();
      emit(Unauthenticated());
    });
  }
}
