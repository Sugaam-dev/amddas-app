import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter_datetime_picker_plus/flutter_datetime_picker_plus.dart'; // Updated Date Picker

import 'user_page.dart'; // Navigation to User Page
import 'login_page.dart'; // Navigation to Login Page

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
  bool _isTokenGenerated = false;

  bool _isWednesday = false; // New state variable for Wednesday
  String? _selectedMenuId;
  String? _orderId;
  Map<String, dynamic>? _orderDetails;
  bool _isLoading = false;
  List<dynamic> _tokens = []; // List of tokens for the carousel
  DateTime? _selectedDate; // Updated to DateTime type

  // Animation Controller for vibration effect
  late AnimationController _controller;
  late Animation<double> _animation;

  // Secure Storage
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  // JWT Token, User ID, and Email
  String? _jwtToken;
  String? _userId;
  String? _email;

  // Initialization flag
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimation();
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
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: -5, end: 5).animate(_controller);
  }

  // Initialize Menu and Booking Day
  Future<void> _initializeMenu() async {
    String? token = await _secureStorage.read(key: 'jwt_token');
    String? email = await _secureStorage.read(key: 'user_email');
    String? userId = await _secureStorage.read(key: 'user_id');

    if (token != null && email != null && userId != null) {
      setState(() {
        _jwtToken = token;
        _email = email;
        _userId = userId;
      });

      print('Retrieved JWT Token: $_jwtToken');
      print('Retrieved Email: $_email');
      print('Retrieved User ID: $_userId');

      _determineBookingDay();
      await _fetchMenuData();
    } else {
      String missingData = '';
      if (token == null) missingData += 'JWT Token, ';
      if (email == null) missingData += 'Email, ';
      if (userId == null) missingData += 'User ID, ';

      if (missingData.isNotEmpty) {
        missingData = missingData.substring(0, missingData.length - 2);
      }

      setState(() {
        _error = 'Missing required data: $missingData.';
      });

      print('Error: Missing required data: $missingData');

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
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

  // Fetch Order Details using orderId
  Future<void> _fetchOrderDetails(String orderId) async {
    final String apiUrl =
        'https://www.backend.amddas.net/api/order-details/user?userId=$_userId';

    setState(() {
      _isLoading = true;
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
        List<dynamic> data = json.decode(response.body);
        List<dynamic> activeTokens =
            data.where((detail) => detail['isActive'] == 1).toList();

        List<dynamic> formattedTokens = activeTokens.map((detail) {
          return {
            'token': detail['token'],
            'validFor': _formatDate(detail['deliveryDate']),
          };
        }).toList();

        setState(() {
          _orderDetails = data.isNotEmpty ? data[0] : null;
          _tokenn = _orderDetails?['token']?.toString();
          _formattedDate = _formatDate(_orderDetails?['deliveryDate']);
          _error = null;
          _tokens = formattedTokens;
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
        _isLoading = false;
      });
    }
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

    return DateFormat('yyyy-MM-dd').format(date);
  }

  // Filtering Function using Dropdown
  void _filterItems(String category) {
    setState(() {
      _activeFilter = category;
    });

    if (_menuData.isEmpty) {
      print('Menu data is empty.');
      setState(() {
        _error = 'No menu data available.';
        _filteredItems = [];
        _selectedMenuId = null;
      });
      return;
    }

    print('Filtering items for category: $category');
    print('Menu Data: $_menuData');

    List<dynamic> filtered = [];
    String? menuId;

    try {
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

      if (filtered.isEmpty) {
        setState(() {
          _error = 'No items found for $category on $_bookingDay.';
          _filteredItems = [];
          _selectedMenuId = null;
        });
      } else {
        setState(() {
          _filteredItems = filtered;
          _selectedMenuId = menuId;
          _error = null;
        });
      }

      // Debug Statements
      print('Filtered Items: $filtered');
      print('Selected Menu ID: $menuId');
    } catch (e) {
      setState(() {
        _error = 'An error occurred while filtering menu items.';
        _filteredItems = [];
        _selectedMenuId = null;
      });
      print('Error in _filterItems: $e');
    }
  }

  // Handle Date Selection using Date Picker Plus
  void _selectDate() {
    DatePicker.showDatePicker(
      context,
      showTitleActions: true,
      onConfirm: (date) {
        setState(() {
          _selectedDate = date;
          _bookingDay = DateFormat('EEEE').format(date);
          _isSunday = date.weekday == DateTime.sunday;

          _isWednesday = date.weekday == DateTime.wednesday; // Set Wednesday
          _error = null;
        });
        _fetchMenuData(date: date);

        // Debug Statements
        print('Selected Booking Day: $_bookingDay');
        print('Is Sunday: $_isSunday');

        print('Is Wednesday: $_isWednesday');
      },
      currentTime: DateTime.now(),
      locale: LocaleType.en,
      minTime: DateTime.now().add(Duration(days: 1)), // Start from tomorrow
      maxTime: _calculateMaxDate(), // Next week's Friday
      // Additional constraints can be set here if necessary
    );
  }

  /**
   * Calculates the maximum selectable date as next week's Friday.
   *
   * @returns {DateTime} - The date representing next week's Friday.
   */
  DateTime _calculateMaxDate() {
    final DateTime today = DateTime.now();
    final DateTime nextWeekFriday = today.add(Duration(
        days: ((5 - today.weekday) + 7) % 7 + 1)); // Next week's Friday
    print(
        'Max selectable date: ${DateFormat('yyyy-MM-dd').format(nextWeekFriday)}');
    return nextWeekFriday;
  }

  /**
   * Passes the selected date to the parent component.
   */
  useEffect() {
    // Note: 'useEffect' is not used in Flutter. This function can be removed.
    // The date passing is already handled in the onConfirm callback.
  }

  /**
   * Passes the selected date to the parent component.
   */
  // Removed the unused useEffect

  // Helper: Determine Booking Day based on current date
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

      _isWednesday =
          bookedDayDate.weekday == DateTime.wednesday; // Set Wednesday
    });

    // Debug Statements
    print('Booking Day: $_bookingDay');
    print('Is Sunday: $_isSunday');

    print('Is Wednesday: $_isWednesday');
  }

  // Fetch Menu Data from API
  Future<void> _fetchMenuData({DateTime? date}) async {
    if (_jwtToken == null || _bookingDay.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    // Format day to match backend expectations (e.g., lowercase)
    String dayToFetch = date != null
        ? DateFormat('EEEE').format(date).toLowerCase()
        : _bookingDay.toLowerCase();

    // Debug Statement
    print('Fetching menu for: $dayToFetch');

    final String apiUrl =
        'https://www.backend.amddas.net/api/menus/menu/$dayToFetch';

    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $_jwtToken',
          'Content-Type': 'application/json',
        },
      );

      // Debug Statements
      print('API Response Status: ${response.statusCode}');
      print('API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        setState(() {
          _menuData = data;
          _filterItems(_activeFilter);
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
          _error = 'Failed to fetch menu data. Please try again.';
          _filteredItems = [];
          _selectedMenuId = null;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'An error occurred while fetching menu data.';
        _filteredItems = [];
        _selectedMenuId = null;
      });
      print('Error fetching menu data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Handle OTP/Token Generation
  Future<void> _generateToken() async {
    if (_jwtToken == null || _selectedMenuId == null) {
      setState(() {
        _error = 'Invalid menu selection or authentication.';
      });
      return;
    }

    if (_selectedDate == null) {
      setState(() {
        _error = 'Please select a delivery date.';
      });
      return;
    }

    // Check if within allowed time
    if (!_isWithinAllowedTime()) {
      setState(() {
        _error = 'Token generation is only allowed between 12 PM to 8 PM.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final String formattedDate =
        DateFormat('yyyy-MM-dd').format(_selectedDate!);
    // Ensure dayToFetch is lowercase if backend expects it
    final String apiUrl =
        'https://www.backend.amddas.net/api/orders/submit?menuIds=$_selectedMenuId&quantities=1&deliveryDate=$formattedDate';

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
        Map<String, dynamic> responseData = json.decode(response.body);

        String tokenId = responseData['token']?.toString() ?? '';
        String dateTimeToken = responseData['deliveryDate']?.toString() ?? '';

        String formattedBookingDate = _formatDate(dateTimeToken);

        setState(() {
          _orderResponse = 'Order submitted successfully.';
          _otpTokenId = tokenId;
          _tokenn = tokenId;
          _formattedDate = formattedBookingDate;
          _isTokenGenerated = true;
          _error = null;
          _tokens.add({
            'token': tokenId,
            'validFor': formattedBookingDate,
          });
        });

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

  // Handle Token Cancellation
  Future<void> _cancelToken(String token, String deliveryDate) async {
    if (_isSunday) {
      setState(() {
        _error = 'Token cancellation is not allowed on Sundays.';
      });
      return;
    }

    if (!_isWithinAllowedTime()) {
      setState(() {
        _error = 'Token cancellation is only allowed between 12 PM to 8 PM.';
      });
      return;
    }

    final String apiUrl =
        'https://www.backend.amddas.net/api/order-details/cancel';

    try {
      final response = await http.put(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $_jwtToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({'token': token}),
      );

      if (response.statusCode == 200) {
        setState(() {
          _tokens.removeWhere((t) => t['token'] == token);
          _orderResponse = 'Your order has been cancelled successfully.';
          _error = null;
        });

        if (_orderId != null) {
          await _fetchOrderDetails(_orderId!);
        }
      } else {
        setState(() {
          _error = 'Failed to cancel order. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'An error occurred while cancelling the order.';
      });
      print('Error cancelling order: $e');
    }
  }

  // Helper function to show confirmation dialog before cancelling token
  void _showCancelConfirmationDialog(String token, String deliveryDate) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Cancel Token'),
          content: Text('Do you really want to cancel the token ID: $token?'),
          actions: <Widget>[
            TextButton(
              child: Text('Yes'),
              onPressed: () {
                Navigator.of(context).pop();
                _cancelToken(token, deliveryDate);
              },
            ),
            TextButton(
              child: Text('No'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }

  // Helper: Determine if within allowed time (12 PM to 8 PM)
  bool _isWithinAllowedTime() {
    final now = DateTime.now();
    final hour = now.hour;
    return hour >= 12 && hour < 20; // 12 PM to 8 PM
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      // Show loading indicator until initialization is complete
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'MENU',
            style: GoogleFonts.josefinSans(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 32),
          ),
          centerTitle: true,
          backgroundColor: Color.fromARGB(255, 41, 110, 61),
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'MENU',
          style: GoogleFonts.josefinSans(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 32),
        ),
        centerTitle: true,
        backgroundColor:
            Color.fromARGB(255, 41, 110, 61), // Set the AppBar background color
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
                  // User Information Card
                  Card(
                    color: Colors.white.withOpacity(0.8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: Icon(Icons.person, color: Colors.black),
                      title: Text(
                        'Email: $_email',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'User ID: $_userId',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ),

                  SizedBox(height: 20),

                  // Token Details Carousel
                  if (_tokens.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Tokens:',
                          style: GoogleFonts.josefinSans(
                              fontSize: 20,
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 10),
                        CarouselSlider.builder(
                          itemCount: _tokens.length,
                          itemBuilder:
                              (BuildContext context, int index, int realIdx) {
                            var token = _tokens[index];
                            return Card(
                              color: Colors.white.withOpacity(0.8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Token ID: ${token['token']}',
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    SizedBox(height: 10),
                                    Text(
                                      'Valid For: ${token['validFor']}',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    SizedBox(height: 20),
                                    // Disable the cancel button if today is Sunday
                                    if (!_isSunday)
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          _showCancelConfirmationDialog(
                                              token['token'],
                                              token['validFor']);
                                        },
                                        icon: Icon(Icons.delete),
                                        label: Text('Cancel Token'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                        ),
                                      )
                                    else
                                      Text(
                                        'Token cannot be cancelled on Sundays',
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontStyle: FontStyle.italic,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                          options: CarouselOptions(
                            height: 200.0,
                            enlargeCenterPage: true,
                            autoPlay: true,
                            aspectRatio: 16 / 9,
                            autoPlayCurve: Curves.fastOutSlowIn,
                            enableInfiniteScroll: true,
                            autoPlayAnimationDuration:
                                Duration(milliseconds: 1500),
                            viewportFraction: 0.8,
                          ),
                        ),
                      ],
                    ),

                  SizedBox(height: 20),

                  // Date Picker Section using flutter_datetime_picker_plus
                  Card(
                    color: Colors.white.withOpacity(0.8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          ListTile(
                            leading: Icon(Icons.calendar_today),
                            title: Text(
                              _selectedDate == null
                                  ? 'Select Delivery Date'
                                  : 'Delivery Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate!)}',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            subtitle: _selectedDate != null
                                ? Text(
                                    'Day: ${DateFormat('EEEE').format(_selectedDate!)}',
                                    style: TextStyle(
                                        fontSize: 14, color: Colors.grey[700]),
                                  )
                                : null,
                            trailing: Icon(Icons.arrow_forward_ios),
                            onTap: _selectDate,
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 20),

                  // Menu Title
                  Text(
                    'Booking for $_bookingDay Menu',
                    style: GoogleFonts.josefinSans(
                        fontSize: 24, color: Colors.white),
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
                            _error =
                                'Vegetarian menu is not available on Sundays.';
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
                                var itemName = menuItem['item']?['itemName'] ??
                                    'Unnamed Item';
                                var categoryName = menuItem['item']?['category']
                                        ?['categoryName'] ??
                                    'Uncategorized';

                                // Debug Statement
                                print('Displaying Menu Item: $itemName');

                                return Card(
                                  color: Colors.white.withOpacity(0.8),
                                  margin: EdgeInsets.symmetric(vertical: 5),
                                  child: ListTile(
                                    title: Text(
                                      itemName,
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Text(
                                      'Category: $categoryName',
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

                  // Generate Token Button
                  ElevatedButton(
                    onPressed: (_isSunday ||
                            (_selectedDate != null &&
                                _tokens.any((t) =>
                                    t['validFor'] ==
                                    DateFormat('yyyy-MM-dd')
                                        .format(_selectedDate!))) ||
                            !_isWithinAllowedTime())
                        ? null
                        : _generateToken,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: (_isSunday ||
                              (_selectedDate != null &&
                                  _tokens.any((t) =>
                                      t['validFor'] ==
                                      DateFormat('yyyy-MM-dd')
                                          .format(_selectedDate!))) ||
                              !_isWithinAllowedTime())
                          ? Colors.grey
                          : Color(0xFFFC8019),
                      padding:
                          EdgeInsets.symmetric(horizontal: 80, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      (_selectedDate != null &&
                              _tokens.any((t) =>
                                  t['validFor'] ==
                                  DateFormat('yyyy-MM-dd')
                                      .format(_selectedDate!)))
                          ? 'Token Already Generated'
                          : _isSunday
                              ? 'Booking Not Allowed Today'
                              : !_isWithinAllowedTime()
                                  ? 'Generate Token (Unavailable)'
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
            'Booking is allowed from 12 PM to 8 PM.\n'
            'Check the menu after 7:30 PM.\n'
            'Please check the local holidays before booking.',
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

  // Helper: Determine if Veg filter is available
  bool _isVegAvailable() {
    // Veg is available unless it's Sunday
    return !_isSunday;
  }

  // Helper: Determine if Egg filter is available
  bool _isEggAvailable() {
    // Egg is available on Tuesday and Wednesday
    return _isWednesday;
  }

  // Helper: Determine if Non-Veg filter is available
  bool _isNonVegAvailable() {
    // Non-Veg is available on Tuesday and Wednesday
    return _isWednesday;
  }
}
