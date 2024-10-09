import 'package:flutter/material.dart';
import 'login_page.dart'; // Import login page for redirecting after successful verification
import 'package:http/http.dart' as http; // Import the http package
import 'dart:convert'; // For JSON encoding and decoding
import 'dart:async'; // For Timer

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

  void _resendOTP() async {
    // Send request to resend OTP
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
          // Add any other required headers here
        },
      );

      // Debug: Print response status and body
      print('Resend OTP Response Status: ${response.statusCode}');
      print('Resend OTP Response Body: ${response.body}');

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('OTP has been resent to your email.')),
        );
      } else {
        // Handle error
        String errorMessage = 'Failed to resend OTP. Please try again later.';
        // Try to parse error message from response if available
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
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
          // Add any other required headers here
        },
      );

      // Debug: Print response status and body
      print('OTP Verification Response Status: ${response.statusCode}');
      print('OTP Verification Response Body: ${response.body}');

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
        // Handle successful OTP verification
        if (isJson) {
          var responseData = json.decode(response.body);
          print('OTP Verification Successful: $responseData');
        } else {
          print('OTP Verification Successful: ${response.body}');
        }

        // Show success dialog with auto-redirect
        showDialog(
          context: context,
          barrierDismissible:
              false, // User cannot dismiss the dialog by tapping outside
          builder: (context) => WillPopScope(
            onWillPop: () async => false, // Prevent back button
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

        // After 3 seconds, navigate to LoginPage
        Future.delayed(Duration(seconds: 3), () {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => LoginPage()),
            (Route<dynamic> route) => false, // Remove all previous routes
          );
        });
      } else {
        // Handle different status codes accordingly
        String errorMessage = 'OTP verification failed. Please try again.';
        if (isJson) {
          var errorData = json.decode(response.body);
          errorMessage = errorData['message'] ?? errorMessage;
        } else {
          errorMessage =
              response.body.isNotEmpty ? response.body : errorMessage;
        }

        // Show error message
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
        _isLoading = false; // Stop loading
      });
    }
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

  @override
  void dispose() {
    // Dispose controllers when not needed
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    _resendOTPTimer?.cancel(); // Cancel the timer
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Verify OTP'),
        centerTitle: true,
        backgroundColor:
            Color(0xFFEA4335), // Pumpkin color to maintain consistency
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Add the GIF image here
              Image.asset(
                'gif/otp.gif', // Ensure you have this GIF in your assets
                height: 150, // Adjust the height as needed
              ),
              SizedBox(height: 20.0),
              Text(
                'Enter the 6-digit OTP sent to your email',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20.0),

              // OTP Input Fields Row
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
                        counterText: "", // Hide the character count
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        _handleOTPInput(
                            value, index); // Auto-move to next/previous field
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

              // Resend OTP Button
              TextButton(
                onPressed: _isResendButtonEnabled ? _resendOTP : null,
                child: Text(
                  _isResendButtonEnabled
                      ? 'Resend OTP'
                      : 'Resend OTP in $_resendOTPCountdown seconds',
                  style: TextStyle(
                    color: _isResendButtonEnabled ? Colors.blue : Colors.grey,
                  ),
                ),
              ),

              SizedBox(height: 20.0),

              // Submit Button
              _isLoading
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _submitOTP,
                      child: Text(
                        'Submit OTP',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFEA4335), // Pumpkin color
                        padding:
                            EdgeInsets.symmetric(horizontal: 80, vertical: 15),
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
