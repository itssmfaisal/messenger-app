import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:messenger_app/data/models/sources/auth_service.dart';
import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final AuthService authService;

  ProfileBloc(this.authService) : super(ProfileInitial()) {
    on<LoadProfile>((event, emit) async {
      emit(ProfileLoading());
      try {
        // Fetches data from the /auth/me or profile endpoint
        final userData = await authService.getProfile();
        emit(ProfileLoaded(userData));
      } catch (e) {
        emit(ProfileError(e.toString()));
      }
    });
  }
}
