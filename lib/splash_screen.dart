import 'dart:async';
import 'package:flutter/material.dart';
import 'login_page.dart'; // Import the Login Page
import 'menu_page.dart'; // Import the Menu Page
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // Import flutter_secure_storage

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // Initialize FlutterSecureStorage
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _navigateBasedOnAuth();
  }

  // Function to check token and navigate accordingly
  void _navigateBasedOnAuth() async {
    // Wait for 3 seconds to show the splash screen
    await Future.delayed(const Duration(seconds: 3));

    // Read the JWT token from secure storage
    String? token = await _secureStorage.read(key: 'jwt_token');

    if (token != null) {
      // Token exists, navigate to MenuPage
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MenuPage()),
      );
    } else {
      // No token found, navigate to LoginPage
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Background color of the splash screen
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Replace this with your company logo or image
            Image.asset(
              'images/amd.png', // Add AMDDAS Foods logo here
              height: 150.0, // Adjust the height as needed
            ),
            const SizedBox(height: 20.0), // Space between logo and text
            const Text(
              'AMDDAS Foods', // Branding the app with AMDDAS Foods name
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
