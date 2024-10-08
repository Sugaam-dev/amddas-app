import 'package:flutter/material.dart';
import 'login_page.dart'; // Import login page for redirecting after OTP

class OTPPage extends StatefulWidget {
  @override
  _OTPPageState createState() => _OTPPageState();
}

class _OTPPageState extends State<OTPPage> {
  final _otpControllers = List.generate(
      6, (_) => TextEditingController()); // 6 OTP input controllers
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String _correctOTP = "123456"; // Dummy OTP for testing

  // Function to simulate OTP submission
  void _submitOTP() {
    String enteredOTP =
        _otpControllers.map((controller) => controller.text).join();

    if (enteredOTP == _correctOTP) {
      setState(() {
        _isLoading = true;
      });

      // Simulate OTP verification delay
      Future.delayed(Duration(seconds: 2), () {
        setState(() {
          _isLoading = false;
        });

        // Show success dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Success'),
            content: Text('OTP Verified Successfully!'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            LoginPage()), // Redirect to Login Page
                  );
                },
                child: Text('Go to Login'),
              ),
            ],
          ),
        );
      });
    } else {
      // Show error if OTP is incorrect
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Incorrect OTP')));
    }
  }

  // Function to handle OTP auto-jump to the next field
  void _handleOTPInput(String value, int index) {
    if (value.length == 1 && index < 5) {
      FocusScope.of(context).nextFocus(); // Move to next input field
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Verify OTP'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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
                            value, index); // Auto-move to next field
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

              // Submit Button
              _isLoading
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _submitOTP,
                      child: Text('Submit OTP'),
                      style: ElevatedButton.styleFrom(
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
