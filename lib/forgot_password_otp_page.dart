import 'package:flutter/material.dart';
import 'package:quickalert/quickalert.dart'; // Import QuickAlert for the alerts
import 'reset_password_page.dart'; // Import for navigating to reset password page
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http; // Import http package
import 'dart:convert'; // For JSON encoding and decoding
// For Timer

class ForgotPasswordOTPPage extends StatefulWidget {
  final String email; // Accept the email as a parameter

  ForgotPasswordOTPPage({required this.email});

  @override
  _ForgotPasswordOTPPageState createState() => _ForgotPasswordOTPPageState();
}

class _ForgotPasswordOTPPageState extends State<ForgotPasswordOTPPage> {
  final _otpControllers = List.generate(
      6, (_) => TextEditingController()); // 6 OTP input controllers
  final _otpFocusNodes =
      List.generate(6, (_) => FocusNode()); // 6 focus nodes for the OTP fields
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Function to submit OTP using API
  void _submitOTP() async {
    String enteredOTP =
        _otpControllers.map((controller) => controller.text).join();

    if (enteredOTP.length != 6) {
      // Ensure all 6 digits are entered
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter all 6 digits of the OTP')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    String email = Uri.encodeComponent(widget.email.trim());
    String otpCode = enteredOTP.trim();

    String url =
        'https://www.backend.amddas.net/auth/verify-password-reset-otp?email=$email&otp=$otpCode';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          // Add any other required headers here
        },
      );

      // Debug: Print response status and body
      print('OTP Verification Response Status: ${response.statusCode}');
      print('OTP Verification Response Body: ${response.body}');

      if (response.statusCode == 200) {
        // OTP verified successfully
        // Show success alert with green GIF
        QuickAlert.show(
          context: context,
          type: QuickAlertType.success,
          text: 'OTP Verified!',
          confirmBtnText: 'OK',
          confirmBtnColor: Colors.green, // Green OK button
          confirmBtnTextStyle:
              TextStyle(color: Colors.white), // White text on OK button
          onConfirmBtnTap: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ResetPasswordPage(
                  email: widget.email,
                  otp: otpCode, // Pass the OTP to the ResetPasswordPage
                ),
              ),
            );
          },
          animType: QuickAlertAnimType.slideInDown, // Slide-in animation
          customAsset: 'gif/sucess.gif', // Success GIF
        );
      } else {
        // Handle error
        String errorMessage = 'Incorrect OTP!';
        // Optionally, parse error message from response
        if (response.body.isNotEmpty) {
          try {
            var errorData = json.decode(response.body);
            errorMessage = errorData['message'] ?? errorMessage;
          } catch (e) {
            // If response is not JSON, keep the default error message
          }
        }

        // Show error alert with red GIF
        QuickAlert.show(
          context: context,
          type: QuickAlertType.error,
          text: errorMessage,
          confirmBtnText: 'Try Again',
          confirmBtnColor: Colors.red, // Red Try Again button
          confirmBtnTextStyle:
              TextStyle(color: Colors.white), // White text on Try Again button
          animType: QuickAlertAnimType.slideInDown, // Slide-in animation
          customAsset: 'gif/failed.gif', // Error GIF
        );
      }
    } catch (e) {
      print('Error during OTP verification: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred. Please try again.')),
      );
    } finally {
      setState(() {
        _isLoading = false; // Stop loading
      });
    }
  }

  // Handle OTP input and move to next or previous field
  void _handleOTPInput(String value, int index) {
    if (value.isNotEmpty && index < 5) {
      FocusScope.of(context).nextFocus(); // Move to the next input field
    } else if (value.isEmpty && index > 0) {
      FocusScope.of(context)
          .previousFocus(); // Move to the previous input field when cleared
    }
  }

  @override
  void dispose() {
    // Dispose controllers and focus nodes
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var focusNode in _otpFocusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text('Enter OTP', style: GoogleFonts.pacifico(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Color(
            0xFFEA4335), // Set the AppBar background color to Pumpkin #FC8019
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Display GIF before OTP fields
                Image.asset(
                  'gif/otp.gif', // Path to your OTP GIF
                  height: 250, // Adjust height as needed
                ),
                SizedBox(height: 20.0), // Space between GIF and OTP fields

                // OTP Input Fields Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(6, (index) {
                    return SizedBox(
                      width: 45,
                      child: TextFormField(
                        controller: _otpControllers[index],
                        focusNode: _otpFocusNodes[index],
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color:
                                Colors.black), // Black text color for OTP input
                        cursorColor: Color(0xFFFC8019), // Pumpkin color cursor
                        decoration: InputDecoration(
                          counterText: "", // Hide the character count
                          border: OutlineInputBorder(
                            borderSide: BorderSide(
                                color:
                                    Color(0xFFFC8019)), // Pumpkin color border
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Color(0xFFFC8019),
                                width: 2), // Pumpkin color border when focused
                          ),
                        ),
                        onChanged: (value) {
                          _handleOTPInput(
                              value, index); // Handle auto jump between fields
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return ' ';
                          }
                          return null;
                        },
                      ),
                    );
                  }),
                ),
                SizedBox(
                    height: 20.0), // Space between OTP fields and submit button

                // Submit OTP Button
                _isLoading
                    ? CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _submitOTP,
                        child: Text('Submit OTP',
                            style:
                                TextStyle(color: Colors.white)), // White text
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
      ),
    );
  }
}
