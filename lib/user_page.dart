import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'menu_page.dart'; // For Menu Page navigation
import 'login_page.dart'; // For Logout navigation
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // Import flutter_secure_storage

class UserPage extends StatefulWidget {
  @override
  _UserPageState createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  final FlutterSecureStorage _secureStorage =
      FlutterSecureStorage(); // Initialize secure storage
  int _currentIndex = 1; // User page is the active tab
  String userEmail =
      "user@borgwarner.com"; // Placeholder for now; can be replaced with dynamic data

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'User Settings',
          style: GoogleFonts.pacifico(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Color(0xFFEA4335), // Pumpkin color AppBar
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          children: <Widget>[
            // GIF at the top
            SizedBox(height: 20.0),
            Image.asset(
              'gif/user.gif', // Replace with your actual GIF path
              height: 150, // Adjust height as needed
            ),
            SizedBox(height: 20.0),

            // Display the logged-in user's email
            Text(
              'Hello, $userEmail!',
              style: GoogleFonts.pacifico(fontSize: 24, color: Colors.black),
            ),
            SizedBox(height: 40.0),

            // Delete Account option styled like a list item with red text
            ListTile(
              title: Text('Delete Account',
                  style: TextStyle(color: Colors.red, fontSize: 16)),
              onTap: () {
                _showDeleteConfirmationDialog(
                    context); // Show confirmation dialog before deleting
              },
            ),
            Divider(), // Divider below Delete Account

            // Logout option styled like a list item
            ListTile(
              title: Text('Logout',
                  style: TextStyle(color: Colors.black, fontSize: 16)),
              onTap: () {
                _logout(); // Call the logout function
              },
            ),
            Divider(), // Divider below Logout
          ],
        ),
      ),

      // Bottom Navigation Bar
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.black
              .withOpacity(0.5), // Transparent background for the navbar
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
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => MenuPage()), // Navigate to Menu Page
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

  // Logout Function
  Future<void> _logout() async {
    // Delete the JWT token from secure storage
    await _secureStorage.delete(key: 'jwt_token');

    // Optionally, delete other stored user data if any
    // await _secureStorage.deleteAll();

    // Navigate to the LoginPage and remove all previous routes
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
      (Route<dynamic> route) => false, // Remove all routes
    );
  }

  // Confirmation dialog for deleting account
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
                Navigator.of(context).pop();
                // Handle account deletion logic here
              },
            ),
          ],
        );
      },
    );
  }
}
