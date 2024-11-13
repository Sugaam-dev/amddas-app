import 'package:flutter/material.dart';
import 'package:quickalert/quickalert.dart';
import 'reset_password_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';

class ForgotPasswordOTPPage extends StatefulWidget {
  final String email;

  ForgotPasswordOTPPage({required this.email});

  @override
  _ForgotPasswordOTPPageState createState() => _ForgotPasswordOTPPageState();
}

class _ForgotPasswordOTPPageState extends State<ForgotPasswordOTPPage> {
  final _otpControllers = List.generate(6, (_) => TextEditingController());
  final _otpFocusNodes = List.generate(6, (_) => FocusNode());
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  void _submitOTP() async {
    String enteredOTP =
        _otpControllers.map((controller) => controller.text).join();

    if (enteredOTP.length != 6) {
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
        },
      );

      print('OTP Verification Response Status: ${response.statusCode}');
      print('OTP Verification Response Body: ${response.body}');

      // Check both status code and exact response message
      if (response.statusCode == 200 &&
          response.body.trim() ==
              "OTP verified. You can now reset your password.") {
        QuickAlert.show(
          context: context,
          type: QuickAlertType.success,
          text: 'OTP Verified Successfully!',
          confirmBtnText: 'OK',
          confirmBtnColor: Colors.green,
          confirmBtnTextStyle: TextStyle(color: Colors.white),
          onConfirmBtnTap: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => ResetPasswordPage(
                  email: widget.email,
                  otp: otpCode,
                ),
              ),
              (Route<dynamic> route) => false,
            );
          },
          animType: QuickAlertAnimType.slideInDown,
          customAsset: 'gif/sucess.gif',
        );
      } else {
        // Show error QuickAlert for any other response
        QuickAlert.show(
          context: context,
          type: QuickAlertType.error,
          text: 'Incorrect OTP! Please try again.',
          confirmBtnText: 'Try Again',
          confirmBtnColor: Colors.red,
          confirmBtnTextStyle: TextStyle(color: Colors.white),
          animType: QuickAlertAnimType.slideInDown,
          customAsset: 'gif/failed.gif',
        );
      }
    } catch (e) {
      print('Error during OTP verification: $e');
      QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        text: 'An error occurred. Please try again.',
        confirmBtnText: 'OK',
        confirmBtnColor: Colors.red,
        confirmBtnTextStyle: TextStyle(color: Colors.white),
        animType: QuickAlertAnimType.slideInDown,
        customAsset: 'gif/failed.gif',
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleOTPInput(String value, int index) {
    if (value.isNotEmpty && index < 5) {
      FocusScope.of(context).nextFocus();
    } else if (value.isEmpty && index > 0) {
      FocusScope.of(context).previousFocus();
    }
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

  @override
  void dispose() {
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
    return WillPopScope(
      onWillPop: _onWillPop, // Back button handler
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
                          'Enter OTP',
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
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: 20.0),
                      Image.asset(
                        'gif/otp.gif',
                        height: 150,
                      ),
                      SizedBox(height: 20.0),
                      Text(
                        'Enter the 6-digit OTP sent to your email',
                        style: TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 20.0),
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
                              style: TextStyle(color: Colors.black),
                              cursorColor: Color.fromARGB(255, 41, 110, 61),
                              decoration: InputDecoration(
                                counterText: "",
                                border: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Color.fromARGB(255, 41, 110, 61)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Color.fromARGB(255, 41, 110, 61),
                                      width: 2),
                                ),
                              ),
                              onChanged: (value) {
                                _handleOTPInput(value, index);
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
                      SizedBox(height: 20.0),
                      // Message about locating the code
                      Text(
                        "Can't locate the code? Please check your spam folder or request a new code.",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 20.0),

                      // Submit Button
                      _isLoading
                          ? CircularProgressIndicator()
                          : ElevatedButton(
                              onPressed: _submitOTP,
                              child: Text('Submit OTP',
                                  style: TextStyle(color: Colors.white)),
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
