import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:messenger_app/bloc/profile/profile_event.dart';
import 'package:messenger_app/bloc/profile/profile_state.dart';
import 'package:messenger_app/domain/repositories/profile_repository.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProfileRepository _repository;

  ProfileBloc(this._repository) : super(ProfileInitial()) {
    on<LoadProfile>((event, emit) async {
      emit(ProfileLoading());
      try {
        final profile = await _repository.getProfile();
        emit(ProfileLoaded(profile));
      } catch (e) {
        emit(ProfileError(e.toString()));
      }
    });
  }
}
