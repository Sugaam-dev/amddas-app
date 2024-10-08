import 'package:flutter/material.dart';
import 'login_page.dart'; // Redirect for logout
import 'reset_password_page.dart'; // Redirect for change password

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0; // Track the selected tab (0 = Menu, 1 = Profile)
  String _selectedCategory = 'Veg'; // Track the selected menu category
  String _generatedToken = ''; // Store generated token

  // Dummy menu items based on categories
  final Map<String, List<Map<String, String>>> _menuItems = {
    'Veg': [
      {'name': 'Paneer Butter Masala', 'category': 'Veg'},
      {'name': 'Aloo Gobi', 'category': 'Veg'},
    ],
    'Egg': [
      {'name': 'Egg Curry', 'category': 'Egg'},
      {'name': 'Egg Biryani', 'category': 'Egg'},
    ],
    'Non-Veg': [
      {'name': 'Chicken Biryani', 'category': 'Non-Veg'},
      {'name': 'Mutton Curry', 'category': 'Non-Veg'},
    ],
  };

  // Simulate generating a token
  void _generateToken() {
    setState(() {
      _generatedToken = 'TKN${DateTime.now().millisecondsSinceEpoch}';
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Token generated: $_generatedToken'),
    ));
  }

  // Handle tab changes (Menu/Profile)
  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Show a confirmation dialog before deleting the account
  void _confirmDeleteAccount() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Account'),
        content: Text(
            'Are you sure you want to delete your account? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Account deletion in progress...'),
              ));
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // Logout function
  void _logout() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  // Build the Menu Tab
  Widget _buildMenuTab() {
    return Column(
      children: [
        // Drop-down menu to select category
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: DropdownButton<String>(
            value: _selectedCategory,
            items: [
              DropdownMenuItem(value: 'Veg', child: Text('Veg')),
              DropdownMenuItem(
                  value: 'Egg',
                  child: Text('Egg', style: TextStyle(color: Colors.orange))),
              DropdownMenuItem(
                  value: 'Non-Veg',
                  child: Text('Non-Veg', style: TextStyle(color: Colors.red))),
            ],
            onChanged: (value) {
              setState(() {
                _selectedCategory = value!;
              });
            },
          ),
        ),

        // Display menu items based on selected category
        Expanded(
          child: ListView.builder(
            itemCount: _menuItems[_selectedCategory]!.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(_menuItems[_selectedCategory]![index]['name']!),
                subtitle: Text(
                    'Category: ${_menuItems[_selectedCategory]![index]['category']}'),
              );
            },
          ),
        ),

        // Generate Token Button
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: _generateToken,
            child: Text('Generate Token'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 80, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),

        // Display generated token if any
        if (_generatedToken.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Text('Generated Token: $_generatedToken'),
          ),
      ],
    );
  }

  // Build the Profile Tab
  Widget _buildProfileTab() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Change Password Button
        ElevatedButton(
          onPressed: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => ResetPasswordPage()));
          },
          child: Text('Change Password'),
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 60, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        SizedBox(height: 20.0),

        // Delete Account Button
        ElevatedButton(
          onPressed: _confirmDeleteAccount,
          child: Text('Delete Account', style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red, // Red button for delete action
            padding: EdgeInsets.symmetric(horizontal: 60, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        SizedBox(height: 20.0),

        // Logout Button
        ElevatedButton(
          onPressed: _logout,
          child: Text('Logout'),
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 60, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AMDDAS Foods'),
        centerTitle: true,
      ),
      body: _selectedIndex == 0
          ? _buildMenuTab()
          : _buildProfileTab(), // Switch between tabs
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onTabTapped,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.menu), label: 'Menu'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
