import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // Import flutter_secure_storage
import 'package:flutter/services.dart';
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
          _error = "Details don’t match! Try again or sign up.";
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
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          child: Column(
            children: [
              // Header Section
              Stack(
                children: [
                  ClipPath(
                    clipper: HeaderClipper(),
                    child: Container(
                      height: 160,
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
                        Text(
                          'Amddas Foods',
                          style: TextStyle(
                            fontSize: 34,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontFamily: GoogleFonts.josefinSans().fontFamily,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // Main Content Section
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: <Widget>[
                      Image.asset(
                        'gif/login3.gif',
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                      SizedBox(height: 20.0),
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email),
                          border: OutlineInputBorder(),
                          focusedBorder: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: const Color(0xFFFC8019)),
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
                          prefixIcon: Icon(Icons.lock),
                          border: OutlineInputBorder(),
                          focusedBorder: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: const Color(0xFFFC8019)),
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
                          child: Text(
                            'Forgot Password?',
                            style: TextStyle(color: Color(0xFFFC8019)),
                          ),
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
                              onPressed: _isLoading ? null : _login,
                              child: Text(
                                'Login',
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
                            child: Text(
                              'Sign Up',
                              style: TextStyle(color: Color(0xFFFC8019)),
                            ),
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
