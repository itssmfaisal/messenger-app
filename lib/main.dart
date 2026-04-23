import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:messenger_app/bloc/login_bloc.dart';
import 'package:messenger_app/data/models/sources/auth_service.dart';
import 'package:messenger_app/presentation/pages/authscreen/loginscreen.dart';

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
      ],
      child: MaterialApp(
        title: 'Messenger App',
        theme: ThemeData(
          useMaterial3: true,
          fontFamily: 'Poppins',
          primaryColor: Colors.blue,
        ),
        home: LoginScreen(), // Pointing to your new file
      ),
    );
  }
}
