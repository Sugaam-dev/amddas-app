import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'login_page.dart';
import 'menu_page.dart';

class UserPage extends StatefulWidget {
  @override
  _UserPageState createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  int _currentIndex = 1; // User page is the active tab
  String userEmail = "Loading..."; // Initial placeholder while fetching email
  bool _isLoading = true; // Loading state
  String? _userId; // To store User ID if needed

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  /// Fetch user email and user ID directly from secure storage
  Future<void> _fetchUserData() async {
    try {
      String? email = await _secureStorage.read(key: 'user_email');
      String? userId = await _secureStorage.read(key: 'user_id');

      if (email != null && userId != null) {
        setState(() {
          userEmail = email;
          _userId = userId;
          _isLoading = false;
        });

        // Print to debug console
        print('Retrieved Email: $userEmail');
        print('Retrieved User ID: $_userId');
      } else {
        String missingData = '';
        if (email == null) missingData += 'Email, ';
        if (userId == null) missingData += 'User ID, ';

        // Remove trailing comma and space
        if (missingData.isNotEmpty) {
          missingData = missingData.substring(0, missingData.length - 2);
        }

        setState(() {
          userEmail = "Data not found";
          _isLoading = false;
        });

        // Print to debug console
        print('Error: Missing required data: $missingData');

        // Navigate to LoginPage if any data is missing
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
        );
      }
    } catch (e) {
      print("Error fetching user data: $e");
      setState(() {
        userEmail = "Error fetching data";
        _isLoading = false;
      });

      // Optionally, navigate to LoginPage on error
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    }
  }

  /// Navigate to LoginPage and remove all previous routes
  void _navigateToLogin() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
      (Route<dynamic> route) => false,
    );
  }

  /// Logout function: Deletes all secure storage data and navigates to LoginPage
  Future<void> _logout() async {
    try {
      // Delete all data from secure storage
      await _secureStorage.deleteAll();

      print('All stored data cleared successfully');

      // Navigate to the LoginPage and remove all previous routes
      _navigateToLogin();
    } catch (e) {
      print('Error during logout: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred during logout. Please try again.'),
        ),
      );
    }
  }

  /// Show confirmation dialog before deleting account
  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Account'),
          content: Text(
              'Are you sure you want to delete your account? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
            TextButton(
              child: Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                _deleteAccount();
              },
            ),
          ],
        );
      },
    );
  }

  /// Delete account logic (to be implemented as per your backend requirements)
  Future<void> _deleteAccount() async {
    // TODO: Implement your account deletion logic here
    // This might involve making an API call to your backend service

    // For demonstration, we'll just logout the user
    await _logout();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'User Settings',
          style: GoogleFonts.josefinSans(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 32),
        ),
        centerTitle: true,
        backgroundColor: Color.fromARGB(255, 41, 110, 61),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : Column(
                children: <Widget>[
                  SizedBox(height: 20.0),
                  Image.asset(
                    'gif/user.gif',
                    height: 150,
                  ),
                  SizedBox(height: 20.0),
                  Text(
                    'Hello, $userEmail!',
                    style: GoogleFonts.josefinSans(
                        fontSize: 24, color: Colors.black),
                  ),
                  SizedBox(height: 40.0),
                  ListTile(
                    title: Text('Delete Account',
                        style: TextStyle(color: Colors.red, fontSize: 16)),
                    onTap: () => _showDeleteConfirmationDialog(context),
                  ),
                  Divider(),
                  ListTile(
                    title: Text('Logout',
                        style: TextStyle(color: Colors.black, fontSize: 16)),
                    onTap: _logout,
                  ),
                  Divider(),
                ],
              ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5), // Transparent background
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent, // Transparent background
          elevation: 0,
          currentIndex: _currentIndex,
          selectedItemColor: Color(0xFFFC8019), // Pumpkin color for active tab
          unselectedItemColor: Colors.white, // White color for inactive tab
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
            if (index == 0) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => MenuPage()),
              );
            }
          },
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.restaurant_menu),
              label: 'Menu',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'User',
            ),
          ],
          type: BottomNavigationBarType.fixed,
        ),
      ),
    );
  }
}
