import 'package:flutter/material.dart';
import 'forgot_password_otp_page.dart'; // Import for OTP page navigation
import 'package:google_fonts/google_fonts.dart';

class ForgotPasswordPage extends StatefulWidget {
  @override
  _ForgotPasswordPageState createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Simulate sending the OTP to email
  void _sendOTP() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      // Simulate a delay for sending the OTP
      Future.delayed(Duration(seconds: 2), () {
        setState(() {
          _isLoading = false;
        });

        // Navigate to the Forgot Password OTP Page
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  ForgotPasswordOTPPage()), // Redirect to OTP Page
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Set the background color to white
      appBar: AppBar(
        title: Text('Forgot Password',
            style: GoogleFonts.pacifico(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Color(
            0xFFEA4335), // Set the AppBar background color to Pumpkin #FC8019
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
                      return null;
                    },
                  ),
                  SizedBox(height: 20.0),

                  // Send OTP Button
                  _isLoading
                      ? CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: _sendOTP,
                          child: Text(
                            'Send OTP',
                            style: TextStyle(
                                color: Colors.white), // White text on button
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(
                                0xFFEA4335), // Set background color to Pumpkin #FC8019
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
