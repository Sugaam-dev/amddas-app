import 'package:flutter/material.dart';
import 'forgot_password_otp_page.dart'; // Import for OTP page navigation
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';

class ForgotPasswordPage extends StatefulWidget {
  @override
  _ForgotPasswordPageState createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Send OTP to email using API
  void _sendOTP() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      String email = _emailController.text.trim();
      String url = 'https://www.backend.amddas.net/auth/forgot-password';
      var headers = {'Content-Type': 'application/json'};
      var body = json.encode({'email': email});

      try {
        final response = await http.post(
          Uri.parse(url),
          headers: headers,
          body: body,
        );

        print('Response status: ${response.statusCode}');
        print('Response body: ${response.body}');

        // Check if response is JSON
        bool isJson = false;
        try {
          final contentType = response.headers['content-type'];
          if (contentType != null && contentType.contains('application/json')) {
            isJson = true;
          }
        } catch (e) {
          isJson = false;
        }

        if (response.statusCode == 200 || response.statusCode == 201) {
          // OTP sent successfully
          if (isJson) {
            var responseData = json.decode(response.body);
            print('OTP sent successfully: $responseData');
          } else {
            print('OTP sent successfully: ${response.body}');
          }

          // Navigate to the Forgot Password OTP Page, passing the email
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => ForgotPasswordOTPPage(
                    email: email)), // Redirect to OTP Page
          );
        } else {
          // Handle error response
          String errorMessage = 'Failed to send OTP. Please try again.';
          if (isJson) {
            var errorData = json.decode(response.body);
            errorMessage = errorData['message'] ?? errorMessage;
          } else {
            errorMessage =
                response.body.isNotEmpty ? response.body : errorMessage;
          }
          // Show error message
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(errorMessage)));
        }
      } catch (e) {
        print('Error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('An error occurred. Please try again.')));
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Back Button Handler
  Future<bool> _onWillPop() async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Exit App?'),
            content: Text('Do you want to exit the application?'),
            actions: [
              TextButton(
                child: Text('No'),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              TextButton(
                child: Text('Yes'),
                onPressed: () {
                  Navigator.of(context).pop(true);
                  SystemNavigator.pop(); // Exit the app
                },
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  void dispose() {
    // Dispose controllers
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop, // Back button handler
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          child: Column(
            children: [
              // Custom Header Section
              Stack(
                children: [
                  ClipPath(
                    clipper: HeaderClipper(),
                    child: Container(
                      height: 150,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color.fromARGB(255, 41, 110, 61),
                            Color.fromARGB(255, 58, 190, 96)
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 40),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Text(
                          'Forgot Password',
                          style: TextStyle(
                            fontSize: 28,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontFamily: GoogleFonts.josefinSans().fontFamily,
                          ),
                        ),
                        SizedBox(width: 40), // For balance with back button
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.0), // Small gap below header

              // Main Content Section
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      // Display GIF before text fields
                      Lottie.network(
                        'https://lottie.host/bb02c48b-83b6-435e-8dc1-ee22844aad6e/JQsEehMGzf.json',
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                      SizedBox(
                          height: 20.0), // Space between GIF and text fields

                      // Email Input Field
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Color(
                                    0xFFFC8019)), // Custom color when active
                          ),
                        ),
                        cursorColor: Color(0xFFFC8019), // Custom cursor color
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                            return 'Please enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 20.0),

                      // Send OTP Button
                      _isLoading
                          ? CircularProgressIndicator()
                          : ElevatedButton(
                              onPressed: _isLoading ? null : _sendOTP,
                              child: Text(
                                'Send OTP',
                                style: TextStyle(color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Color.fromARGB(255, 41, 110, 61),
                                padding: EdgeInsets.symmetric(
                                    horizontal: 80, vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom Clipper for Header
class HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    // Starting point
    path.lineTo(0, size.height - 60);
    // Single curve as in UserPage
    path.quadraticBezierTo(
      size.width / 4,
      size.height,
      size.width / 2,
      size.height - 40,
    );
    // Continuing to the top-right
    path.lineTo(size.width, size.height - 120);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
