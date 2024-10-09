import 'package:flutter/material.dart';
import 'forgot_password_page.dart';
import 'signup_page.dart';
import 'menu_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isPasswordVisible = false; // For toggling password visibility
  final FlutterSecureStorage _secureStorage =
      FlutterSecureStorage(); // Initialize secure storage

  // Login function using API
  void _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      var headers = {'Content-Type': 'application/json'};
      var url = Uri.parse('https://www.backend.amddas.net/login');
      var body = json.encode({
        "email": _emailController.text.trim(),
        "password": _passwordController.text.trim()
      });

      try {
        final response = await http.put(
          url,
          headers: headers,
          body: body,
        );

        // Debug: print response
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
          // Login successful
          if (isJson) {
            var responseData = json.decode(response.body);
            // Assuming the JWT token is in responseData['token']
            String token = responseData['token'];

            // Store the token securely
            await _secureStorage.write(key: 'jwt_token', value: token);

            print('Login successful: $responseData');
          } else {
            print('Login successful: ${response.body}');
          }

          // Navigate to MenuPage
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => MenuPage()),
          );
        } else {
          // Login failed
          var errorMessage = 'Invalid email or password';

          if (isJson) {
            try {
              var errorData = json.decode(response.body);
              if (errorData['message'] != null) {
                errorMessage = errorData['message'];
              }
            } catch (e) {
              // Error decoding JSON
              errorMessage = response.body;
            }
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

  // Logout function (if you want to implement it here)
  Future<void> _logout() async {
    await _secureStorage.delete(key: 'jwt_token');
    // Navigate to LoginPage
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  @override
  void dispose() {
    // Dispose controllers
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Set the background color to white
      appBar: AppBar(
        title: Text('Amddas Foods',
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
                  // GIF with no top padding or margin
                  Image.asset(
                    'gif/login.gif', // Path to your GIF
                    height: 250, // Adjust height as needed
                    fit: BoxFit.cover, // Ensure no padding/margin at the top
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
                            color: const Color(
                                0xFFFC8019)), // Orange border when active
                      ),
                    ),
                    cursorColor: Colors.orange, // Orange cursor
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

                  // Password Input Field with Eye Button
                  TextFormField(
                    controller: _passwordController,
                    obscureText:
                        !_isPasswordVisible, // Toggle password visibility
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color: Colors.orange), // Orange border when active
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        color: Colors.black, // Set icon color to black
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible =
                                !_isPasswordVisible; // Toggle the visibility
                          });
                        },
                      ),
                    ),
                    cursorColor: Colors.orange, // Orange cursor
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 10.0),

                  // Forgot Password Link
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => ForgotPasswordPage()),
                        );
                      },
                      child: Text('Forgot Password?'),
                    ),
                  ),

                  SizedBox(height: 20.0),

                  // Login Button
                  _isLoading
                      ? CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          child: Text(
                            'Login',
                            style: TextStyle(
                                color: Colors
                                    .white), // White text on orange button
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

                  SizedBox(height: 20.0),

                  // Sign-Up Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Don't have an account?"),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => SignUpPage()),
                          );
                        },
                        child: Text('Sign Up'),
                      ),
                    ],
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
