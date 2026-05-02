import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:messenger_app/bloc/authbloc/auth_bloc.dart';
import 'package:messenger_app/bloc/authbloc/auth_event.dart';
import 'package:messenger_app/bloc/authbloc/auth_state.dart';
import 'package:messenger_app/bloc/chat_detail/chat_detail_bloc.dart';
import 'package:messenger_app/bloc/chat_list/chat_list_bloc.dart';
import 'package:messenger_app/bloc/login/login_bloc.dart';
import 'package:messenger_app/bloc/profile/profile_bloc.dart';
import 'package:messenger_app/bloc/registration/registration_bloc.dart';
import 'package:messenger_app/core/app_theme.dart';
import 'package:messenger_app/data/repositories/auth_repository_impl.dart';
import 'package:messenger_app/data/repositories/chat_repository_impl.dart';
import 'package:messenger_app/data/repositories/presence_repository_impl.dart';
import 'package:messenger_app/data/repositories/profile_repository_impl.dart';
import 'package:messenger_app/data/services/auth_service.dart';
import 'package:messenger_app/data/services/chat_service.dart';
import 'package:messenger_app/data/services/profile_service.dart';
import 'package:messenger_app/data/services/websocket_service.dart';
import 'package:messenger_app/domain/repositories/auth_repository.dart';
import 'package:messenger_app/domain/repositories/chat_repository.dart';
import 'package:messenger_app/domain/repositories/presence_repository.dart';
import 'package:messenger_app/domain/repositories/profile_repository.dart';
import 'package:messenger_app/presentation/pages/authscreen/loginscreen.dart';
import 'package:messenger_app/presentation/pages/main_wrapper/main_wrapper_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final chatService = ChatService();
    final webSocketService = WebSocketService();

    final AuthRepository authRepository = AuthRepositoryImpl(authService);
    final ProfileRepository profileRepository = ProfileRepositoryImpl(
      ProfileService(),
    );
    final ChatRepository chatRepository = ChatRepositoryImpl(chatService);
    final PresenceRepository presenceRepository = PresenceRepositoryImpl(
      chatService,
    );

    return MultiBlocProvider(
      providers: [
        BlocProvider<LoginBloc>(
          create: (_) => LoginBloc(authRepository),
        ),
        BlocProvider<RegistrationBloc>(
          create: (_) => RegistrationBloc(authRepository),
        ),
        BlocProvider<ProfileBloc>(
          create: (_) => ProfileBloc(profileRepository),
        ),
        BlocProvider<AuthBloc>(
          create: (_) => AuthBloc(authRepository)..add(AppStarted()),
        ),
        BlocProvider<ChatListBloc>(
          create: (_) => ChatListBloc(chatRepository),
        ),
        BlocProvider<ChatDetailBloc>(
          create: (_) => ChatDetailBloc(
            chatRepository,
            presenceRepository,
            webSocketService,
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Messenger App',
        theme: AppTheme.light,
        home: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            if (state is Authenticated) {
              return MainWrapperPage(webSocketService: webSocketService);
            } else if (state is Unauthenticated) {
              return const LoginScreen();
            }

            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          },
        ),
      ),
    );
  }
}
