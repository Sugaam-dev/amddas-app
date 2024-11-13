import 'package:flutter/material.dart';
import 'login_page.dart'; // Import login page for redirecting after successful verification
import 'package:http/http.dart' as http; // Import the http package
import 'dart:async'; // For Timer
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';

class OTPPage extends StatefulWidget {
  final String email; // Email passed from SignUpPage

  OTPPage({required this.email}); // Constructor to accept email

  @override
  _OTPPageState createState() => _OTPPageState();
}

class _OTPPageState extends State<OTPPage> {
  final List<TextEditingController> _otpControllers = List.generate(
      6, (_) => TextEditingController()); // 6 OTP input controllers
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Resend OTP variables
  int _resendOTPCountdown = 30;
  bool _isResendButtonEnabled = false;
  Timer? _resendOTPTimer;

  @override
  void initState() {
    super.initState();
    _startResendOTPTimer();
  }

  void _startResendOTPTimer() {
    setState(() {
      _resendOTPCountdown = 30;
      _isResendButtonEnabled = false;
    });

    _resendOTPTimer?.cancel(); // Cancel any existing timer

    _resendOTPTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_resendOTPCountdown > 0) {
          _resendOTPCountdown--;
        } else {
          _isResendButtonEnabled = true;
          _resendOTPTimer?.cancel();
        }
      });
    });
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

  // Function to handle OTP submission
  Future<void> _submitOTP() async {
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

    String email = widget.email.trim();
    String otpCode = enteredOTP.trim();

    String url =
        'https://www.backend.amddas.net/verify-account?email=$email&otp=$otpCode';

    try {
      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('OTP Verification Response Status: ${response.statusCode}');
      print('OTP Verification Response Body: ${response.body}');

      // Check the status and body of the response
      if (response.statusCode == 200 &&
          response.body.contains(
              "OTP verified. Your account is now active. You can log in.")) {
        // Handle successful OTP verification
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => WillPopScope(
            onWillPop: () async => false,
            child: AlertDialog(
              title: Column(
                children: [
                  Icon(Icons.check_circle_outline,
                      size: 60, color: Colors.green),
                  SizedBox(height: 10),
                  Text('Registration Successful'),
                ],
              ),
              content: Text('Redirecting to login page in 3 seconds...'),
            ),
          ),
        );

        Future.delayed(Duration(seconds: 3), () {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => LoginPage()),
            (Route<dynamic> route) => false,
          );
        });
      } else {
        // Handle OTP verification failure
        String errorMessage = 'OTP verification failed. Please try again.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      print('Error during OTP verification: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred. Please try again.')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Function to resend OTP
  Future<void> _resendOTP() async {
    String email = widget.email.trim();
    String url = 'https://www.backend.amddas.net/regenerate-otp?email=$email';

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      print('Resend OTP Response Status: ${response.statusCode}');
      print('Resend OTP Response Body: ${response.body}');

      // Check if OTP resend is successful
      if (response.statusCode == 200 &&
          response.body.contains("OTP has been resent to your email.")) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('OTP has been resent to your email.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to resend OTP. Please try again.')),
        );
      }
    } catch (e) {
      print('Error during resending OTP: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred. Please try again.')),
      );
    } finally {
      setState(() {
        _isLoading = false;
        _startResendOTPTimer(); // Restart the timer
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    _resendOTPTimer?.cancel();
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
                          'Verify OTP',
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
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
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
                              keyboardType: TextInputType.number,
                              maxLength: 1,
                              textAlign: TextAlign.center,
                              decoration: InputDecoration(
                                counterText: "",
                                border: OutlineInputBorder(),
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
                      Text(
                        "Can't locate the code? Please check your spam folder or request a new code.",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 20.0),
                      TextButton(
                        onPressed: _isResendButtonEnabled ? _resendOTP : null,
                        child: Text(
                          _isResendButtonEnabled
                              ? 'Resend OTP'
                              : 'Resend OTP in $_resendOTPCountdown seconds',
                          style: TextStyle(
                            color: _isResendButtonEnabled
                                ? Colors.blue
                                : Colors.grey,
                          ),
                        ),
                      ),
                      SizedBox(height: 20.0),
                      _isLoading
                          ? CircularProgressIndicator()
                          : ElevatedButton(
                              onPressed: _submitOTP,
                              child: Text(
                                'Submit OTP',
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

  // Function to handle OTP auto-jump to the next field
  void _handleOTPInput(String value, int index) {
    if (value.length == 1 && index < 5) {
      FocusScope.of(context).nextFocus(); // Move to next input field
    }
    if (value.length == 0 && index > 0) {
      FocusScope.of(context).previousFocus(); // Move to previous field if empty
    }
  }
}
