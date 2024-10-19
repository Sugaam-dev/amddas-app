import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // Import flutter_secure_storage

import 'forgot_password_page.dart';
import 'signup_page.dart';
import 'menu_page.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Initialize controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Initialize flutter_secure_storage
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  bool _isLoading = false;
  bool _isPasswordVisible = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  /// Check if a token already exists and is valid
  Future<void> _checkLoginStatus() async {
    String? token = await _secureStorage.read(key: 'jwt_token');
    if (token != null && !JwtDecoder.isExpired(token)) {
      print('Existing valid token found: $token');
      // Token exists and is valid, navigate to MenuPage
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => MenuPage()),
      );
    } else {
      if (token != null) {
        print('Token expired: $token');
        // Optionally, delete the expired token
        await _secureStorage.delete(key: 'jwt_token');
      } else {
        print('No existing token found');
      }
    }
  }

  @override
  void dispose() {
    // Dispose controllers to free resources
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Handle user login
  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _error = null; // Clear previous error
      });

      var url = Uri.parse('https://www.backend.amddas.net/login');
      var body = json.encode({
        "email": _emailController.text.trim(),
        "password": _passwordController.text.trim()
      });

      try {
        print('Sending login request...');
        final response = await http.put(
          url,
          headers: {'Content-Type': 'application/json'},
          body: body,
        );

        print('Response status: ${response.statusCode}');
        print('Response body: ${response.body}');

        if (response.statusCode == 200) {
          final token = response
              .body; // Assuming the token is directly in the response body
          print('Received token: $token');

          // Decode the JWT
          Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
          print('Decoded token: $decodedToken');

          // Extract email and user ID from the token
          String? userEmail = decodedToken['sub'] ??
              decodedToken['email'] ??
              decodedToken['userEmail'];
          String? userId = decodedToken['userId'] ?? decodedToken['user_id'];

          print('Extracted email: $userEmail');
          print('Extracted userId: $userId');

          if (userEmail == null) {
            print(
                'Warning: Unable to extract email from token. Token payload: $decodedToken');
            userEmail = _emailController.text.trim();
          }

          // Store the token and user info securely
          await _secureStorage.write(key: 'jwt_token', value: token);
          await _secureStorage.write(key: 'user_email', value: userEmail);
          if (userId != null) {
            await _secureStorage.write(key: 'user_id', value: userId);
          }

          // Optionally, verify stored data
          String? storedToken = await _secureStorage.read(key: 'jwt_token');
          String? storedEmail = await _secureStorage.read(key: 'user_email');
          String? storedUserId = await _secureStorage.read(key: 'user_id');

          print('Stored token: $storedToken');
          print('Stored email: $storedEmail');
          print('Stored userId: $storedUserId');

          // Navigate to MenuPage
          print('Navigating to MenuPage...');
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => MenuPage()),
          );
        } else if (response.statusCode == 401) {
          setState(() {
            _error = "Invalid email or password.";
          });
        } else {
          setState(() {
            _error = "Something went wrong. Please try again later.";
          });
        }
      } catch (error) {
        setState(() {
          _error = "Login failed. Please try again.";
        });
        print('Error during login: $error');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Amddas Foods',
          style: GoogleFonts.josefinSans(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 32,
          ),
        ),
        centerTitle: true,
        backgroundColor: Color.fromARGB(255, 41, 110, 61),
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
                  Image.asset(
                    'gif/login.gif',
                    height: 250,
                    fit: BoxFit.cover,
                  ),
                  SizedBox(height: 20.0),
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: const Color(0xFFFC8019)),
                      ),
                    ),
                    cursorColor: Colors.orange,
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
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.orange),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        color: Colors.black,
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                    ),
                    cursorColor: Colors.orange,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 10.0),
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
                  if (_error != null)
                    Text(
                      _error!,
                      style: TextStyle(color: Colors.red),
                    ),
                  SizedBox(height: 10.0),
                  _isLoading
                      ? CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: _isLoading
                              ? null
                              : _login, // Disable button if loading
                          child: Text(
                            'Login',
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color.fromARGB(255, 41, 110, 61),
                            padding: EdgeInsets.symmetric(
                                horizontal: 80, vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                  SizedBox(height: 20.0),
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
