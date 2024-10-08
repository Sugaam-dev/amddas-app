import 'package:flutter/material.dart';
import 'forgot_password_page.dart';
import 'signup_page.dart';
import 'menu_page.dart';
import 'package:google_fonts/google_fonts.dart';

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

  String dummyEmail = "bpanda272@gmail.com";
  String dummyPassword = "123";

  // Dummy login function
  void _login() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // Simulate login delay
      Future.delayed(Duration(seconds: 2), () {
        setState(() {
          _isLoading = false;
        });

        // Check if credentials match the dummy credentials
        if (_emailController.text == dummyEmail &&
            _passwordController.text == dummyPassword) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => MenuPage()), // Redirect to Home Page
          );
        } else {
          // Show error if login fails
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Invalid email or password')));
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Set the background color to white
      appBar: AppBar(
        title: Text('AMDDAS Foods - Login',
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
                        color: Colors.black, // Set icon color to orange
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
                          onPressed: _login,
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
