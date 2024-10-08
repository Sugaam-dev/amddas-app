import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'user_page.dart'; // Import for User Page navigation
import 'package:google_fonts/google_fonts.dart';

class MenuPage extends StatefulWidget {
  @override
  _MenuPageState createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage>
    with SingleTickerProviderStateMixin {
  String? _selectedCategory;
  bool _isTokenGenerated = false;
  String _generatedToken = '';
  int _currentIndex = 0; // To track the active tab (Menu or User)
  late AnimationController _controller; // For vibration effect
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    // Initialize the AnimationController for vibration effect
    _controller = AnimationController(
      duration:
          const Duration(seconds: 1), // Shorter duration for quick vibration
      vsync: this,
    )..repeat(reverse: true); // Animation will repeat (vibration effect)

    _animation = Tween<double>(begin: -5, end: 5).animate(_controller);

    // Stop the vibration after 5 seconds
    Future.delayed(Duration(seconds: 5), () {
      _controller.stop();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Show dialog with booking information
  void _showBookingInfo() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Booking Information'),
          content: Text(
            'Booking starts from 12 PM to 12 AM.\n'
            'Check the menu after 7:30 PM.\n'
            'Please check the geological calendar for holidays before booking.',
          ),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'MENU',
          style: GoogleFonts.pacifico(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Color(0xFFEA4335), // Pumpkin color AppBar
      ),
      body: Stack(
        children: [
          // Background image with gray overlay
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('images/food.jpg'), // Your background image
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.5),
                    BlendMode.darken), // Gray overlay effect
              ),
            ),
          ),

          // Menu content
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: <Widget>[
                // Dropdown for selecting category (Veg, Egg, Non-Veg)
                SizedBox(height: 20), // Move dropdown a bit down from the top
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  hint: Text(
                    'Select Category',
                    style: GoogleFonts.pacifico(
                        color: Colors
                            .white), // Using Pacifico font from Google Fonts
                  ),
                  icon: Icon(Icons.arrow_drop_down, color: Colors.white),
                  dropdownColor: Colors.black87,
                  style: GoogleFonts.pacifico(color: Colors.white),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white
                        .withOpacity(0.3), // Dropdown field background
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white),
                    ),
                  ),
                  items: ['Veg', 'Egg', 'Non-Veg']
                      .map((category) => DropdownMenuItem<String>(
                            value: category,
                            child: Text(category),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value;
                    });
                  },
                ),
                SizedBox(height: 20),

                // Display List of Items based on selected category
                if (_selectedCategory != null)
                  Expanded(
                    child: ListView.builder(
                      itemCount: _menuItems[_selectedCategory]!.length,
                      itemBuilder: (context, index) {
                        return Card(
                          color: Colors.white.withOpacity(0.8),
                          margin: EdgeInsets.symmetric(vertical: 5),
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Text(
                              _menuItems[_selectedCategory]![index],
                              style: GoogleFonts.pacifico(
                                  fontSize: 18, color: Colors.black),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                SizedBox(height: 20),

                // Token Generation Button
                ElevatedButton(
                  onPressed: _generateToken,
                  child: Text('Generate Token',
                      style: GoogleFonts.pacifico(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFFC8019), // Pumpkin color
                    padding: EdgeInsets.symmetric(horizontal: 80, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),

                SizedBox(height: 20),

                // Display generated token if available
                if (_isTokenGenerated)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Token: $_generatedToken',
                          style: GoogleFonts.pacifico(
                              fontSize: 18, color: Colors.black),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Date: ${DateFormat('yyyy-MM-dd').format(DateTime.now())}', // Display the current date
                          style: GoogleFonts.pacifico(
                              fontSize: 16, color: Colors.black),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Red speaker icon floating above the bottom navigation bar
          Positioned(
            bottom: 80, // Above the bottom navbar
            right: 20,
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _animation.value), // Simulate vibration
                  child: GestureDetector(
                    onTap: _showBookingInfo, // Show popup when pressed
                    child: Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.notifications_active,
                          color: Colors.red, size: 30),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
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
            if (index == 1) {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => UserPage()), // Navigate to User Page
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

  // Sample menu items based on selected category
  final Map<String, List<String>> _menuItems = {
    'Veg': ['Paneer Butter Masala', 'Dal Tadka', 'Mixed Veg'],
    'Egg': ['Egg Curry', 'Egg Bhurji'],
    'Non-Veg': ['Chicken Biryani', 'Mutton Rogan Josh'],
  };

  // Generate token logic
  void _generateToken() {
    setState(() {
      _isTokenGenerated = true;
      _generatedToken =
          'TKN-${DateTime.now().millisecondsSinceEpoch}'; // Example token
    });
  }
}
