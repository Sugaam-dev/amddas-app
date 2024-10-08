import 'package:flutter/material.dart';
import 'splash_screen.dart'; // Import the SplashScreen
import 'login_page.dart'; // Import the LoginPage
import 'otp_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AMDDAS Foods',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      // Set SplashScreen as the initial route
      initialRoute: '/',
      routes: {
        '/': (context) => SplashScreen(), // The initial splash screen
        '/login': (context) => LoginPage(), // The login page after splash
        '/otp': (context) => OTPPage(),
      },
    );
  }
}
