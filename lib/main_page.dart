// main.dart

import 'package:flutter/material.dart';
import 'login_page.dart';
import 'forgot_password_page.dart';
import 'signup_page.dart';
import 'menu_page.dart';
import 'appnavigator.dart'; // Import the new file

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Amddas Foods',
      initialRoute: '/', // Default route
      routes: {
        '/': (context) => LoginPage(),
        '/forgot_password': (context) => ForgotPasswordPage(),
        '/signup': (context) => SignUpPage(),
        '/menu': (context) => MenuPage(),
        '/appnavigator': (context) => AppNavigator(),
      },
    );
  }
}
