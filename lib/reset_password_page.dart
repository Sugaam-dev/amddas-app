import 'package:flutter/material.dart';
import 'login_page.dart'; // Import the login page to redirect after confirmation
import 'package:google_fonts/google_fonts.dart';

class ResetPasswordPage extends StatefulWidget {
  @override
  _ResetPasswordPageState createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isPasswordReset = false; // Track if password is reset

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

  // Function to simulate resetting the password
  void _resetPassword() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // Simulate a delay for resetting the password
      Future.delayed(Duration(seconds: 2), () {
        setState(() {
          _isLoading = false;
          _isPasswordReset = true; // Mark the password as reset
        });

        // Automatically redirect to Login Page after 3 seconds
        Future.delayed(Duration(seconds: 3), () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => LoginPage()),
          );
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reset Password',
            style: GoogleFonts.pacifico(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Color(0xFFEA4335), // Set AppBar to Pumpkin color
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isPasswordReset
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_outline,
                        color: Colors.green, size: 100),
                    SizedBox(height: 20),
                    Text(
                      'Your password has been reset successfully!',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 10),
                    Text('Redirecting to Login Page in 3 seconds...',
                        textAlign: TextAlign.center),
                  ],
                ),
              )
            : Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Display GIF at the top before the input fields
                    Image.asset(
                      'gif/reset.gif', // Path to your GIF
                      height: 250, // Adjust height as needed
                    ),
                    SizedBox(
                        height: 10.0), // Space between GIF and input fields

                    // New Password Input Field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'New Password',
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFFC8019)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: Color(0xFFFC8019),
                              width: 2), // Pumpkin color
                        ),
                        prefixIcon: Icon(Icons.lock),
                      ),
                      validator: _validatePassword,
                    ),
                    SizedBox(height: 16.0),

                    // Confirm Password Input Field
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFFC8019)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: Color(0xFFFC8019),
                              width: 2), // Pumpkin color
                        ),
                        prefixIcon: Icon(Icons.lock),
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
                                style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Color(0xFFFC8019), // Pumpkin color button
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
    );
  }
}
