import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:messenger_app/bloc/registration/registration_event.dart';
import 'package:messenger_app/bloc/registration/registration_state.dart';
import 'package:messenger_app/domain/repositories/auth_repository.dart';

class RegistrationBloc extends Bloc<RegistrationEvent, RegistrationState> {
  final AuthRepository _repository;

  RegistrationBloc(this._repository) : super(RegistrationInitial()) {
    on<RegistrationSubmitted>((event, emit) async {
      emit(RegistrationLoading());
      try {
        final result = await _repository.register(
          username: event.username,
          email: event.email,
          password: event.password,
        );
        emit(RegistrationSuccess(result['username']));
      } catch (e) {
        emit(RegistrationError(e.toString()));
      }
    });
  }
}
