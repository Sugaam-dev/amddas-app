import 'package:flutter/material.dart';
import 'otp_page.dart'; // Import for OTP Page navigation
import 'package:url_launcher/url_launcher.dart'; // For launching the privacy policy URL
import 'login_page.dart';
import 'package:google_fonts/google_fonts.dart'; // for Google Fonts
import 'package:http/http.dart' as http; // Import the http package
import 'dart:convert'; // For JSON encoding and decoding
import 'package:flutter/services.dart';

class SignUpPage extends StatefulWidget {
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isAgreeToPrivacy = false;
  bool _isLoading = false; // Loading state

  // Back Button Handler
  Future<bool> _onWillPop() async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Exit App!'),
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

  // Password validation
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 6) {
      return 'Password must be 6 characters long';
    }
    if (!RegExp(r'^(?=.*[A-Z])').hasMatch(value)) {
      return 'Password must contain one uppercase letter';
    }
    if (!RegExp(r'^(?=.*[0-9])').hasMatch(value)) {
      return 'Password must contain one number';
    }
    if (!RegExp(r'^(?=.*[!@#\$&*~])').hasMatch(value)) {
      return 'Password must contain special character';
    }
    return null;
  }

  // Launch privacy policy URL
  void _launchPrivacyPolicy() async {
    final Uri url = Uri.parse('https://www.amddas.net/privacy-policy');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      // Show error if URL can't be launched
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch Privacy Policy')),
      );
    }
  }

  // Registration API Call
  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) {
      // If form is not valid, do not proceed
      return;
    }

    if (!_isAgreeToPrivacy) {
      // If user hasn't agreed to privacy policy, do not proceed
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You must agree to the Privacy Policy')),
      );
      return;
    }

    setState(() {
      _isLoading = true; // Start loading
    });

    var headers = {
      'Content-Type': 'application/json',
      // Add any other required headers here
    };
    var url = Uri.parse('https://www.backend.amddas.net/register');
    var body = json.encode({
      "name": _nameController.text.trim(),
      "email": _emailController.text.trim(),
      "password": _passwordController.text.trim()
    });

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: body,
      );

      // Debug: Print response status and body
      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      // Check if response is JSON
      bool isJson = false;
      try {
        final contentType = response.headers['content-type'];
        if (contentType != null && contentType.contains('application/json')) {
          isJson = true;
        }
      } catch (e) {
        // If checking content-type fails, assume it's not JSON
        isJson = false;
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Handle successful registration
        String email = _emailController.text.trim();

        if (isJson) {
          var responseData = json.decode(response.body);
          // You can process responseData as needed
          print('Registration Successful: $responseData');
        } else {
          // If response is not JSON, handle accordingly
          print('Registration Successful: ${response.body}');
        }

        // Navigate to OTP Page and pass the email
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => OTPPage(email: email)), // Pass email
        );
      } else {
        // Custom error message for account already exists
        String errorMessage = 'Account exists! Try logging in.';

        /*
        // Previous error message logic
        String errorMessage = 'Registration failed. Please try again.';
        if (isJson) {
          var errorData = json.decode(response.body);
          // Adjust based on your API's error response structure
          errorMessage = errorData['message'] ?? errorMessage;
        } else {
          // If response is not JSON, use the raw response body
          errorMessage = response.body.isNotEmpty ? response.body : errorMessage;
        }
        */

        // Show custom error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      // Handle any exceptions, such as network errors
      print('Error during registration: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred. Please try again.')),
      );
    } finally {
      setState(() {
        _isLoading = false; // Stop loading
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
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
                          'Sign Up',
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
              // Main Content Section
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Image.asset(
                        'gif/signup.gif',
                        height: 150,
                      ),
                      SizedBox(height: 20.0),

                      // Name Input
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Name',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                          focusedBorder: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Color(0xFFFC8019), width: 2),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16.0),

                      // Email Input
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email),
                          border: OutlineInputBorder(),
                          focusedBorder: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Color(0xFFFC8019), width: 2),
                          ),
                        ),
                        keyboardType: TextInputType.emailAddress,
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
                      SizedBox(height: 16.0),

                      // Password Input
                      TextFormField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: Icon(Icons.lock),
                          border: OutlineInputBorder(),
                          focusedBorder: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Color(0xFFFC8019), width: 2),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Colors.black,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                        ),
                        cursorColor: Color(0xFFFC8019),
                        validator: _validatePassword,
                      ),
                      SizedBox(height: 16.0),

                      // Confirm Password Input
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: !_isConfirmPasswordVisible,
                        decoration: InputDecoration(
                          labelText: 'Confirm Password',
                          prefixIcon: Icon(Icons.lock_outline),
                          border: OutlineInputBorder(),
                          focusedBorder: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Color(0xFFFC8019), width: 2),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isConfirmPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Colors.black,
                            ),
                            onPressed: () {
                              setState(() {
                                _isConfirmPasswordVisible =
                                    !_isConfirmPasswordVisible;
                              });
                            },
                          ),
                        ),
                        cursorColor: Color(0xFFFC8019),
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

                      // Privacy Policy Checkbox
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Checkbox(
                            value: _isAgreeToPrivacy,
                            onChanged: (value) {
                              setState(() {
                                _isAgreeToPrivacy = value ?? false;
                              });
                            },
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: _launchPrivacyPolicy,
                              child: RichText(
                                text: TextSpan(
                                  text:
                                      'By creating an account, you agree to the ',
                                  style: TextStyle(color: Colors.black),
                                  children: [
                                    TextSpan(
                                      text: 'Privacy Policy',
                                      style: TextStyle(
                                        color: Colors.blue,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20.0),

                      // Sign Up Button
                      ElevatedButton(
                        onPressed: _isAgreeToPrivacy && !_isLoading
                            ? _registerUser
                            : null,
                        child: _isLoading
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.0,
                                ),
                              )
                            : Text('Sign Up',
                                style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isAgreeToPrivacy
                              ? Color.fromARGB(255, 41, 110, 61)
                              : Colors.grey,
                          padding: EdgeInsets.symmetric(
                              horizontal: 80, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      SizedBox(height: 20.0),

                      // Login Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Already have an account?"),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => LoginPage()),
                              );
                            },
                            child: Text('Login',
                                style: TextStyle(color: Color(0xFFFC8019))),
                          ),
                        ],
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

  @override
  void dispose() {
    // Dispose controllers when not needed
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}

// HeaderClipper class (same as in LoginPage)
class HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 60);
    path.quadraticBezierTo(
      size.width / 4,
      size.height,
      size.width / 2,
      size.height - 40,
    );
    path.lineTo(size.width, size.height - 120);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
