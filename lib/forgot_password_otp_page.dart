import 'package:flutter/material.dart';
import 'package:quickalert/quickalert.dart'; // Import QuickAlert for the alerts
import 'reset_password_page.dart'; // Import for navigating to reset password page
import 'package:google_fonts/google_fonts.dart';

class ForgotPasswordOTPPage extends StatefulWidget {
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
  String _correctOTP = "123456"; // Dummy OTP for testing

  // Function to simulate OTP submission
  void _submitOTP() {
    String enteredOTP =
        _otpControllers.map((controller) => controller.text).join();

    if (enteredOTP == _correctOTP) {
      // Show success alert with green GIF if OTP is correct
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
                builder: (context) =>
                    ResetPasswordPage()), // Redirect to Reset Password Page
          );
        },
        animType: QuickAlertAnimType.slideInDown, // Slide-in animation
        customAsset: 'gif/sucess.gif', // Success GIF
      );
    } else {
      // Show error alert with red GIF if OTP is incorrect
      QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        text: 'Incorrect OTP!',
        confirmBtnText: 'Try Again',
        confirmBtnColor: Colors.red, // Red Try Again button
        confirmBtnTextStyle:
            TextStyle(color: Colors.white), // White text on Try Again button
        animType: QuickAlertAnimType.slideInDown, // Slide-in animation
        customAsset: 'gif/failed.gif', // Error GIF
      );
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
