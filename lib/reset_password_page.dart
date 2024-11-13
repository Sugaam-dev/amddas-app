import 'package:flutter/material.dart';
import 'login_page.dart'; // Import the login page to redirect after confirmation
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http; // Import http package
import 'dart:convert'; // For JSON encoding and decoding
import 'package:flutter/services.dart';

class ResetPasswordPage extends StatefulWidget {
  final String email; // Accept the email as a parameter
  final String otp; // Accept the OTP as a parameter

  ResetPasswordPage({required this.email, required this.otp});

  @override
  _ResetPasswordPageState createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isPasswordReset = false; // Track if password is reset
  bool _passwordVisible = false; // Toggle for password visibility
  bool _confirmPasswordVisible =
      false; // Toggle for confirm password visibility

  // Function to validate password based on conditions
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters long';
    }
    if (!RegExp(r'^(?=.*[A-Z])').hasMatch(value)) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!RegExp(r'^(?=.*[0-9])').hasMatch(value)) {
      return 'Password must contain at least one number';
    }
    if (!RegExp(r'^(?=.*[!@#\$&*~])').hasMatch(value)) {
      return 'Password must contain at least one special character';
    }
    return null;
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

  // Function to reset the password using the API
  void _resetPassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      String email = widget.email;
      String otp = widget.otp;
      String password = _passwordController.text.trim();

      // Prepare data for the API request
      var data = json.encode({
        'email': email,
        'otp': otp,
        'newPassword': password,
      });

      // API URL
      String url = 'https://www.backend.amddas.net/auth/reset-password';

      try {
        var headers = {'Content-Type': 'application/json'};

        final response = await http.post(
          Uri.parse(url),
          headers: headers,
          body: data,
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

        if (response.statusCode == 200) {
          // Password reset successful
          setState(() {
            _isLoading = false;
            _isPasswordReset = true; // Mark the password as reset
          });

          // Automatically redirect to Login Page after 3 seconds
          Future.delayed(Duration(seconds: 3), () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => LoginPage()),
              (Route<dynamic> route) => false,
            );
          });
        } else {
          // Handle error response
          String errorMessage = 'Failed to reset password. Please try again.';
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
          setState(() {
            _isLoading = false;
          });
        }
      } catch (e) {
        print('Error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('An error occurred. Please try again.')));
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    // Dispose controllers
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop, // Back button handler
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
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
                          'Reset Password',
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
              _isPasswordReset
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline,
                              color: Colors.green, size: 100),
                          SizedBox(height: 20),
                          Text(
                            'Your password has been reset successfully!',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 10),
                          Text('Redirecting to Login Page in 3 seconds...',
                              textAlign: TextAlign.center),
                        ],
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Display GIF
                        Image.asset(
                          'gif/reset.gif',
                          height: 200,
                        ),
                        SizedBox(height: 20.0), // Margin below the GIF

                        // Form for password reset
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              // New Password Input Field
                              TextFormField(
                                controller: _passwordController,
                                obscureText: !_passwordVisible,
                                decoration: InputDecoration(
                                  labelText: 'New Password',
                                  border: OutlineInputBorder(
                                    borderSide:
                                        BorderSide(color: Color(0xFFFC8019)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: Color(0xFFFC8019), width: 2),
                                  ),
                                  prefixIcon: Icon(Icons.lock),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _passwordVisible
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _passwordVisible = !_passwordVisible;
                                      });
                                    },
                                  ),
                                ),
                                validator: _validatePassword,
                              ),
                              SizedBox(height: 16.0),

                              // Confirm Password Input Field
                              TextFormField(
                                controller: _confirmPasswordController,
                                obscureText: !_confirmPasswordVisible,
                                decoration: InputDecoration(
                                  labelText: 'Confirm Password',
                                  border: OutlineInputBorder(
                                    borderSide:
                                        BorderSide(color: Color(0xFFFC8019)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                        color: Color(0xFFFC8019), width: 2),
                                  ),
                                  prefixIcon: Icon(Icons.lock),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _confirmPasswordVisible
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _confirmPasswordVisible =
                                            !_confirmPasswordVisible;
                                      });
                                    },
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please confirm your password';
                                  }
                                  if (value != _passwordController.text) {
                                    return 'Passwords do not match';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 20.0),

                              // Reset Password Button
                              _isLoading
                                  ? CircularProgressIndicator()
                                  : ElevatedButton(
                                      onPressed: _resetPassword,
                                      child: Text('Reset Password',
                                          style:
                                              TextStyle(color: Colors.white)),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            Color.fromARGB(255, 41, 110, 61),
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 80, vertical: 15),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                    ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
