import 'dart:async';
import 'package:flutter/material.dart';
import 'login_page.dart'; // Make sure you create or link to the Login Page

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // Navigate to Login Page after 3 seconds
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    });
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
