import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:messenger_app/bloc/authbloc/auth_bloc.dart';
import 'package:messenger_app/bloc/authbloc/auth_event.dart';
import 'package:messenger_app/bloc/authbloc/auth_state.dart';
import 'package:messenger_app/bloc/login/login_bloc.dart';
import 'package:messenger_app/bloc/profile/profile_bloc.dart';
import 'package:messenger_app/bloc/registration/registration_bloc.dart';
import 'package:messenger_app/data/models/sources/auth_service.dart';
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

    return MultiBlocProvider(
      providers: [
        BlocProvider<LoginBloc>(create: (context) => LoginBloc(authService)),
        BlocProvider<RegistrationBloc>(
          create: (context) => RegistrationBloc(authService),
        ),
        BlocProvider<ProfileBloc>(
          create: (context) => ProfileBloc(authService),
        ),
        BlocProvider(create: (_) => AuthBloc(authService)..add(AppStarted())),
      ],
      child: MaterialApp(
        title: 'Messenger App',
        theme: ThemeData(
          useMaterial3: true,
          fontFamily: 'Poppins',
          primaryColor: Colors.blue,
        ),
        home: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            if (state is Authenticated) {
              return const MainWrapperPage();
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
