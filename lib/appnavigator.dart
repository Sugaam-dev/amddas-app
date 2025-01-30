// appnavigator.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'date_picker_page.dart';
import 'tokenpage.dart';
import 'user_page.dart';

class AppNavigator extends StatefulWidget {
  final int initialIndex;

  const AppNavigator({Key? key, this.initialIndex = 0}) : super(key: key);

  @override
  State<AppNavigator> createState() => _AppNavigatorState();
}

class _AppNavigatorState extends State<AppNavigator> {
  late int _selectedIndex;
  bool _isVisible = true; // Controls visibility of the BottomNavigationBar
  Timer? _hideTimer; // Timer to auto-hide the BottomNavigationBar
  double _lastScrollOffset = 0.0; // Tracks the last scroll offset

  // List of pages to display
  final List<Widget> _pages = [
    DatePickerPage(),
    TokenPage(),
    UserPage(),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _startHideTimer(); // Start the hide timer when the app initializes
  }

  @override
  void dispose() {
    _hideTimer?.cancel(); // Cancel the timer when disposing
    super.dispose();
  }

  // Handle tab selection
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _isVisible = true; // Show the navigation bar when a new tab is selected
    });
    _startHideTimer(); // Restart the hide timer
  }

  // Start or restart the hide timer
  void _startHideTimer() {
    _hideTimer?.cancel(); // Cancel any existing timer
    _hideTimer = Timer(Duration(seconds: 20), () {
      setState(() {
        _isVisible = false; // Hide the navigation bar after 20 seconds
      });
    });
  }

  // Show the navigation bar and restart the hide timer
  void _showNavBar() {
    if (!_isVisible) {
      setState(() {
        _isVisible = true;
      });
    }
    _startHideTimer(); // Restart the hide timer
  }

  // Handle scroll events and determine scroll direction
  bool _onScrollNotification(ScrollNotification notification) {
    // Only handle ScrollUpdateNotification to track scrolling
    if (notification is ScrollUpdateNotification) {
      double currentOffset = notification.metrics.pixels;
      if (currentOffset > _lastScrollOffset) {
        // Scrolling Down
        if (_isVisible) {
          setState(() {
            _isVisible = false; // Hide the navigation bar on scroll down
          });
        }
      } else if (currentOffset < _lastScrollOffset) {
        // Scrolling Up
        if (!_isVisible) {
          setState(() {
            _isVisible = true; // Show the navigation bar on scroll up
          });
          _startHideTimer(); // Restart the hide timer
        }
      }
      _lastScrollOffset = currentOffset; // Update the last scroll offset
    }
    return false; // Allow the notification to continue to be dispatched
  }

  // Custom BottomNavigationBar with rounded corners and animated visibility
  Widget _buildRoundedBottomNavigationBar() {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      height:
          _isVisible ? 80.0 : 0.0, // 60.0 for BottomNavigationBar + 20.0 margin
      curve: Curves.easeInOut,
      child: _isVisible
          ? Container(
              margin: const EdgeInsets.only(
                  bottom: 20,
                  left: 20,
                  right: 20), // Margin to move up and inward
              height: 60, // Height of the navigation bar
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 32, 32, 32),
                borderRadius: BorderRadius.all(Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.transparent,
                    blurRadius: 100,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(20)),
                child: BottomNavigationBar(
                  backgroundColor: const Color.fromARGB(201, 51, 50, 50),
                  currentIndex: _selectedIndex,
                  selectedItemColor: const Color(0xFFFC8019),
                  unselectedItemColor: Colors.white,
                  onTap: _onItemTapped,
                  items: const [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.calendar_today, size: 20), // Icon size
                      label: 'Book',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.confirmation_num_outlined,
                          size: 20), // Icon size
                      label: 'Tokens',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.person, size: 20), // Icon size
                      label: 'User',
                    ),
                  ],
                  type: BottomNavigationBarType.fixed,
                  elevation: 0,
                  selectedFontSize: 12, // Font size
                  unselectedFontSize: 12, // Font size
                  iconSize: 24, // Overall icon size
                ),
              ),
            )
          : SizedBox.shrink(), // Hide the navigation bar by rendering nothing
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Navigate back to HomePage
        Navigator.pop(context);
        return false; // Prevent the default back button behavior
      },
      child: Scaffold(
        extendBody: true,
        body: GestureDetector(
          onTap: _showNavBar, // Show the nav bar on any tap
          child: NotificationListener<ScrollNotification>(
            onNotification: _onScrollNotification,
            child: IndexedStack(
              index: _selectedIndex,
              children: _pages,
            ),
          ),
        ),
        bottomNavigationBar: _buildRoundedBottomNavigationBar(),
      ),
    );
  }
}
