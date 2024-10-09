import 'package:flutter/material.dart';
import 'splash_screen.dart'; // Import the SplashScreen
import 'login_page.dart'; // Import the LoginPage
import 'signup_page.dart'; // Import the SignUpPage
import 'menu_page.dart'; // Import the MenuPage

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // Root of the app
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AMDDAS Foods',
      theme: ThemeData(
        primarySwatch:
            Colors.orange, // Updated to match your app's color scheme
      ),
      // Set SplashScreen as the initial route
      home: SplashScreen(), // Start with the SplashScreen
      routes: {
        '/login': (context) => LoginPage(), // The login page after splash
        '/signup': (context) => SignUpPage(), // The sign-up page
        '/menu': (context) => MenuPage(), // The menu page after login
        // Add other routes as needed
      },
      debugShowCheckedModeBanner: false, // Remove the debug banner
    );
  }
}
