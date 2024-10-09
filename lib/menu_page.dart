import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// Removed 'jwt_decoder' package import

import 'user_page.dart'; // Import for User Page navigation
import 'login_page.dart'; // Import for Login Page navigation

class MenuPage extends StatefulWidget {
  @override
  _MenuPageState createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage>
    with SingleTickerProviderStateMixin {
  // State Variables
  List<dynamic> _menuData = [];
  List<dynamic> _filteredItems = [];
  String _activeFilter = 'Veg'; // Default filter
  String _bookingDay = '';
  String? _otpTokenId;
  String? _tokenn;
  String? _formattedDate;
  String? _orderResponse;
  String? _error;
  bool _isSunday = false;
  bool _isTuesday = false;
  String? _selectedMenuId;
  int? _quantity;
  String? _orderId;
  Map<String, dynamic>? _orderDetails;
  bool _isOrderDetailsLoading = false;
  bool _isLoading = false;
  bool _isTokenGenerated = false;

  // Animation Controller for vibration effect
  late AnimationController _controller;
  late Animation<double> _animation;

  // Secure Storage
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  // JWT Token, User ID, and Email
  String? _jwtToken;
  String? _userId;
  String? _email; // Added to store the email

  // Dropdown for Menu Types
  String? _selectedMenuType;

  // Initialization flag
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimation();

    // Chain initialization methods
    _initializeMenu().then((_) {
      _initializeOrder().then((_) {
        setState(() {
          _isInitialized = true;
        });
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Initialize Animation Controller
  void _initializeAnimation() {
    _controller = AnimationController(
      duration: const Duration(seconds: 1), // Quick vibration
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: -5, end: 5).animate(_controller);
  }

  // Initialize Menu and Booking Day
  Future<void> _initializeMenu() async {
    // Retrieve JWT Token from Secure Storage
    String? token = await _secureStorage.read(key: 'jwt_token');
    if (token != null) {
      setState(() {
        _jwtToken = token;
      });
      _decodeJwt(token);
      _determineBookingDay();
      await _fetchMenuData();
    } else {
      setState(() {
        _error = 'Authentication token is missing.';
      });
    }
  }

  // **Manual JWT Decoding**
  void _decodeJwt(String token) {
    try {
      Map<String, dynamic> decodedToken = _parseJwt(token);
      print('Decoded JWT: $decodedToken');

      setState(() {
        // Adjust these keys based on your token's payload
        _userId = decodedToken['userId']?.toString();
        _email =
            decodedToken['email']?.toString(); // Use the correct key for email
        print('User ID: $_userId');
        print('Email: $_email');
      });
    } catch (e) {
      setState(() {
        _error = 'Invalid authentication token.';
      });
      print('Error decoding JWT: $e');
    }
  }

  // **Helper Function to Manually Decode JWT**
  Map<String, dynamic> _parseJwt(String token) {
    final parts = token.split('.');
    if (parts.length != 3) {
      throw Exception('Invalid token');
    }

    final payload = _decodeBase64(parts[1]);
    final payloadMap = json.decode(payload);
    if (payloadMap is! Map<String, dynamic>) {
      throw Exception('Invalid payload');
    }

    return payloadMap;
  }

  String _decodeBase64(String str) {
    String output = str.replaceAll('-', '+').replaceAll('_', '/');

    switch (output.length % 4) {
      case 0:
        break; // No padding needed
      case 2:
        output += '=='; // Two padding chars
        break;
      case 3:
        output += '='; // One padding char
        break;
      default:
        throw Exception('Illegal base64url string!');
    }

    return utf8.decode(base64Url.decode(output));
  }

  // Determine Booking Day
  void _determineBookingDay() {
    final DateTime today = DateTime.now();
    final int currentDay = today.weekday; // 1 = Monday, 7 = Sunday
    DateTime bookedDayDate;

    if (currentDay >= 1 && currentDay <= 4) {
      // Monday to Thursday: Book for the next day
      bookedDayDate = today.add(Duration(days: 1));
    } else if (currentDay == 5 || currentDay == 6) {
      // Friday or Saturday: Book for Monday
      int daysToAdd = 8 - currentDay; // Friday +3, Saturday +2
      bookedDayDate = today.add(Duration(days: daysToAdd));
    } else {
      // Sunday: Book for Monday
      bookedDayDate = today.add(Duration(days: 1));
    }

    String bookedDayName = DateFormat('EEEE').format(bookedDayDate);

    setState(() {
      _bookingDay = bookedDayName;
      _isSunday = today.weekday == DateTime.sunday;
      _isTuesday = today.weekday == DateTime.tuesday;
    });
  }

  // Fetch Menu Data from API
  Future<void> _fetchMenuData() async {
    if (_jwtToken == null || _bookingDay.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    final String apiUrl =
        'https://www.backend.amddas.net/api/menus/menu/$_bookingDay';

    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $_jwtToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        setState(() {
          _menuData = data;
          _filterItems('Veg'); // Apply default filter
          _error = null;
        });
      } else if (response.statusCode == 403) {
        setState(() {
          _error = 'Session expired. Please log in again.';
        });
        // Navigate to LoginPage if session expired
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
        );
      } else {
        setState(() {
          _error = 'Failed to fetch menu data. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'An error occurred while fetching menu data.';
      });
      print('Error fetching menu data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Initialize Order (Fetch Latest Order ID and Details)
  Future<void> _initializeOrder() async {
    if (_jwtToken == null || _userId == null) return;

    await _fetchLatestOrderId();
  }

  // Fetch Latest Order ID using userId
  Future<void> _fetchLatestOrderId() async {
    final String apiUrl =
        'https://www.backend.amddas.net/api/orders/latest/$_userId';

    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $_jwtToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> data = json.decode(response.body);
        String fetchedOrderId = data['orderId'].toString();
        setState(() {
          _orderId = fetchedOrderId;
        });
        await _fetchOrderDetails(fetchedOrderId);
      } else if (response.statusCode == 403) {
        setState(() {
          _error = 'Session expired. Please log in again.';
        });
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
        );
      } else {
        setState(() {
          _error = 'No recent orders found.';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to fetch order data. Please try again.';
      });
      print('Error fetching latest order ID: $e');
    }
  }

  // Fetch Order Details
  Future<void> _fetchOrderDetails(String orderId) async {
    final String apiUrl =
        'https://www.backend.amddas.net/api/order-details/$orderId';

    setState(() {
      _isOrderDetailsLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $_jwtToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> data = json.decode(response.body);
        String menuId = data['menuId'].toString();
        String menuType = _getMenuTypeFromMenuId(menuId);

        setState(() {
          _orderDetails = data;
          _orderDetails?['menuType'] = menuType;
          _tokenn = data['token']?.toString();
          _formattedDate = _formatDate(data['dateTimeToken']);
          _quantity = data['quantity'] ?? 1;
          _error = null;
        });
      } else if (response.statusCode == 403) {
        setState(() {
          _error = 'Session expired. Please log in again.';
        });
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
        );
      } else {
        setState(() {
          _error = 'Failed to fetch order details.';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'An error occurred while fetching order details.';
      });
      print('Error fetching order details: $e');
    } finally {
      setState(() {
        _isOrderDetailsLoading = false;
      });
    }
  }

  // Helper: Map menuId to menuType
  String _getMenuTypeFromMenuId(String menuId) {
    // Define the menu mapping based on the booking day
    Map<String, Map<String, dynamic>> menuDataMap = {
      'Monday': {'veg': '1'},
      'Tuesday': {'veg': '2'},
      'Wednesday': {'veg': '3', 'nonVeg': '4', 'egg': '5'},
      'Thursday': {'veg': '6'},
      'Friday': {'veg': '7'},
      // Add more mappings if needed
    };

    for (var day in menuDataMap.keys) {
      for (var type in menuDataMap[day]!.keys) {
        if (menuDataMap[day]![type] == menuId) {
          return type;
        }
      }
    }

    return 'Unknown';
  }

  // Helper: Format Date
  String _formatDate(String? isoString) {
    if (isoString == null) return 'Invalid Date';

    DateTime date;
    try {
      date = DateTime.parse(isoString);
    } catch (e) {
      return 'Invalid Date';
    }

    int day = date.weekday; // 1 = Monday, 7 = Sunday

    if (day == DateTime.friday) {
      date = date.add(Duration(days: 3)); // Next Monday
    } else if (day == DateTime.saturday) {
      date = date.add(Duration(days: 2)); // Next Monday
    } else {
      date = date.add(Duration(days: 1)); // Next day
    }

    return DateFormat('yyyy-MM-dd').format(date);
  }

  // Filtering Function using Dropdown
  void _filterItems(String category) {
    setState(() {
      _activeFilter = category;
    });

    if (_menuData.isEmpty) return;

    List<dynamic> filtered = [];
    String? menuId;

    if (category == 'Veg') {
      var vegMenu = _menuData.firstWhere((menu) => menu['isVeg'] == 1,
          orElse: () => null);
      if (vegMenu != null) {
        filtered = vegMenu['menuItems'];
        menuId = vegMenu['menuId'].toString();
      }
    } else if (category == 'Egg') {
      var eggMenu = _menuData.firstWhere((menu) => menu['isVeg'] == 2,
          orElse: () => null);
      if (eggMenu != null) {
        filtered = eggMenu['menuItems'];
        menuId = eggMenu['menuId'].toString();
      }
    } else if (category == 'Non-Veg') {
      var nonVegMenu = _menuData.firstWhere((menu) => menu['isVeg'] == 0,
          orElse: () => null);
      if (nonVegMenu != null) {
        filtered = nonVegMenu['menuItems'];
        menuId = nonVegMenu['menuId'].toString();
      }
    }

    setState(() {
      _filteredItems = filtered;
      _selectedMenuId = menuId;
    });
  }

  // Handle OTP/Token Generation
  Future<void> _generateToken() async {
    if (_jwtToken == null || _selectedMenuId == null) {
      setState(() {
        _error = 'Invalid menu selection or authentication.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final String apiUrl =
        'https://www.backend.amddas.net/api/orders/submit?menuIds=$_selectedMenuId&quantities=1';

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $_jwtToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({}), // Assuming no body needed
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Assuming the response contains tokenId and usage info
        Map<String, dynamic> responseData = json.decode(response.body);

        // Adjust the keys based on your actual API response
        String tokenId = responseData['token']?.toString() ?? '';
        String dateTimeToken = responseData['dateTimeToken']?.toString() ?? '';

        String formattedBookingDate = _formatDate(dateTimeToken);

        setState(() {
          _orderResponse = 'Order submitted successfully.';
          _otpTokenId = tokenId;
          _tokenn = tokenId;
          _formattedDate = formattedBookingDate;
          _isTokenGenerated = true;
          _error = null;
        });

        // Fetch the latest order details after OTP generation
        await _fetchLatestOrderId();
      } else if (response.statusCode == 403) {
        setState(() {
          _error = 'Session expired. Please log in again.';
        });
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
        );
      } else {
        setState(() {
          _error = 'Failed to generate Token. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'An error occurred while generating the Token.';
      });
      print('Error generating OTP: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Helper: Determine if filter options should be enabled/disabled
  bool _isVegAvailable() {
    // Veg is available unless it's Sunday
    return !_isSunday;
  }

  bool _isEggAvailable() {
    // Egg is available only on Tuesday
    return _isTuesday;
  }

  bool _isNonVegAvailable() {
    // Non-Veg is available only on Tuesday
    return _isTuesday;
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      // Show loading indicator until initialization is complete
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'MENU',
            style: GoogleFonts.pacifico(color: Colors.white),
          ),
          centerTitle: true,
          backgroundColor: Color(0xFFEA4335),
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'MENU',
          style: GoogleFonts.pacifico(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor:
            Color(0xFFEA4335), // Set the AppBar background color to orange
      ),
      body: Stack(
        children: [
          // Background image with gray overlay
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('images/food.jpg'), // Your background image
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(0.5), BlendMode.darken),
              ),
            ),
          ),

          // Main Content
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Remove the scrolling text widget here

                  SizedBox(height: 20),

                  // Display User ID and Email
                  Card(
                    color: Colors.white.withOpacity(0.8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'User ID: ${_userId ?? 'N/A'}',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Email: ${_email ?? 'N/A'}',
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 20),

                  // OTP Details Card
                  if (_tokenn != null && _formattedDate != null)
                    Card(
                      color: Colors.white.withOpacity(0.8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            // Token ID
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Token ID:',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
                                ),
                                Text(
                                  _tokenn!,
                                  style: TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                            SizedBox(height: 10),
                            // Valid For
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Valid For:',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
                                ),
                                Text(
                                  _formattedDate!,
                                  style: TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                  SizedBox(height: 20),

                  // Menu Title
                  Text(
                    'Booking for $_bookingDay Menu',
                    style:
                        GoogleFonts.pacifico(fontSize: 24, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: 20),

                  // Dropdown for Menu Types
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    value: _activeFilter,
                    items:
                        <String>['Veg', 'Egg', 'Non-Veg'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        // Check availability before applying filter
                        if (newValue == 'Veg' && !_isVegAvailable()) {
                          setState(() {
                            _error = 'Vegetarian menu is not available today.';
                          });
                          return;
                        }
                        if (newValue == 'Egg' && !_isEggAvailable()) {
                          setState(() {
                            _error = 'Eggetarian menu is not available today.';
                          });
                          return;
                        }
                        if (newValue == 'Non-Veg' && !_isNonVegAvailable()) {
                          setState(() {
                            _error =
                                'Non-Vegetarian menu is not available today.';
                          });
                          return;
                        }
                        _filterItems(newValue);
                        setState(() {
                          _error = null; // Clear previous errors
                        });
                      }
                    },
                  ),

                  SizedBox(height: 20),

                  // Menu List
                  _isLoading
                      ? Center(child: CircularProgressIndicator())
                      : _filteredItems.isNotEmpty
                          ? ListView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              itemCount: _filteredItems.length,
                              itemBuilder: (context, index) {
                                var menuItem = _filteredItems[index];
                                return Card(
                                  color: Colors.white.withOpacity(0.8),
                                  margin: EdgeInsets.symmetric(vertical: 5),
                                  child: ListTile(
                                    title: Text(
                                      menuItem['item']['itemName'],
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Text(
                                      'Category: ${menuItem['item']['category']['categoryName']}',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ),
                                );
                              },
                            )
                          : Center(
                              child: Text(
                                _error != null
                                    ? _error!
                                    : 'No items found for $_activeFilter.',
                                style:
                                    TextStyle(color: Colors.red, fontSize: 16),
                              ),
                            ),

                  SizedBox(height: 20),

                  // Generate OTP Button
                  ElevatedButton(
                    onPressed:
                        (_isSunday || _quantity == 1) ? null : _generateToken,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: (_isSunday || _quantity == 1)
                          ? Colors.grey
                          : Color(0xFFFC8019),
                      padding:
                          EdgeInsets.symmetric(horizontal: 80, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      _quantity == 1
                          ? 'Token Already Generated'
                          : _isSunday
                              ? 'Booking Not Allowed Today'
                              : 'Generate Token',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                  ),

                  SizedBox(height: 20),

                  // Order Response
                  if (_orderResponse != null)
                    Card(
                      color: Colors.white.withOpacity(0.8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Text(
                              _orderResponse!,
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 10),
                            Text('Token ID: $_tokenn'),
                            Text('Valid For: $_formattedDate'),
                          ],
                        ),
                      ),
                    ),

                  // Error Message
                  if (_error != null)
                    Container(
                      padding: EdgeInsets.all(10),
                      color: Colors.red.withOpacity(0.7),
                      child: Row(
                        children: [
                          Icon(Icons.error, color: Colors.white),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _error!,
                              style:
                                  TextStyle(color: Colors.white, fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                    ),

                  SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Positioned Floating Notification Icon
          Positioned(
            bottom: 80, // Above the bottom navbar
            right: 20,
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _animation.value),
                  child: GestureDetector(
                    onTap: _showBookingInfo,
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
          color: Colors.black.withOpacity(0.5), // Transparent background
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent, // Transparent background
          elevation: 0,
          currentIndex: 0, // Menu page is active
          selectedItemColor: Color(0xFFFC8019), // Pumpkin color for active tab
          unselectedItemColor: Colors.white, // White color for inactive tab
          onTap: (index) {
            if (index == 1) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => UserPage()),
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

  // Show Booking Information Dialog
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
}
