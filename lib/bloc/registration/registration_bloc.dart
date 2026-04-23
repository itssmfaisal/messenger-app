import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:messenger_app/bloc/registration/registration_event.dart';
import 'package:messenger_app/bloc/registration/registration_state.dart';
import 'package:messenger_app/data/models/sources/auth_service.dart';

class RegistrationBloc extends Bloc<RegistrationEvent, RegistrationState> {
  final AuthService authService;

  RegistrationBloc(this.authService) : super(RegistrationInitial()) {
    on<RegistrationSubmitted>((event, emit) async {
      emit(RegistrationLoading());
      try {
        final result = await authService.register(
          event.username,
          event.email,
          event.password,
        );
        emit(RegistrationSuccess(result['username']));
      } catch (e) {
        emit(RegistrationError(e.toString()));
      }
    });
  }
}
