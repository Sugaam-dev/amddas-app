import 'package:flutter/material.dart';
import 'forgot_password_otp_page.dart'; // Import for OTP page navigation
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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

  @override
  void dispose() {
    // Dispose controllers
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Set the background color to white
      appBar: AppBar(
        title: Text('Forgot Password',
            style: GoogleFonts.pacifico(color: Colors.white)),
        centerTitle: true,
        backgroundColor:
            Color(0xFFEA4335), // Set the AppBar background color to orange
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  // Display GIF before text fields
                  Image.asset(
                    'gif/forgot.gif', // Path to your GIF
                    height: 250, // Adjust height as needed
                    fit: BoxFit.cover, // Ensure it covers available space
                  ),
                  SizedBox(
                      height:
                          20.0), // Add some space between GIF and text fields

                  // Email Input Field
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color:
                                Color(0xFFFC8019)), // Custom color when active
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
                            style: TextStyle(
                                color: Colors.white), // White text on button
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(
                                0xFFEA4335), // Set background color to orange
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
        ),
      ),
    );
  }
}
