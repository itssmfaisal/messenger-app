import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:messenger_app/bloc/login/login_event.dart';
import 'package:messenger_app/bloc/login/login_state.dart';
import 'package:messenger_app/domain/repositories/auth_repository.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final AuthRepository _repository;

  LoginBloc(this._repository) : super(LoginInitial()) {
    on<LoginSubmitted>((event, emit) async {
      emit(LoginLoading());
      try {
        final token = await _repository.login(
          username: event.username,
          password: event.password,
        );
        emit(LoginSuccess(token));
      } catch (e) {
        emit(LoginError(e.toString()));
      }
    });
  }
}
