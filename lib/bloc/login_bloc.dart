import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:messenger_app/bloc/login_event.dart';
import 'package:messenger_app/bloc/login_state.dart';
import 'package:messenger_app/data/models/sources/auth_service.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final AuthService authService;

  LoginBloc(this.authService) : super(LoginInitial()) {
    on<LoginSubmitted>((event, emit) async {
      emit(LoginLoading());
      try {
        final token = await authService.login(event.username, event.password);
        emit(LoginSuccess(token));
      } catch (e) {
        emit(LoginError(e.toString()));
      }
    });
  }
}
