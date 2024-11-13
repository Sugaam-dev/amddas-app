// menu_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'login_page.dart';
import 'user_page.dart';

class MenuPage extends StatefulWidget {
  @override
  _MenuPageState createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage>
    with SingleTickerProviderStateMixin {
  // State variables
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  int _currentIndex = 0; // Current index for BottomNavigationBar

  // Menu and token data
  List<dynamic> _menuData = [];
  List<dynamic> _filteredItems = [];
  String? _activeFilter; // No default filter
  String _bookingDay = '';
  String? _jwtToken;
  String? _userId;
  String? _email;
  bool _isInitialized = false;
  bool _isLoading = false;
  String? _error;
  bool _isTodaySunday = false;
  bool _isWednesday = false;
  String? _selectedMenuId;
  String? _orderId;
  Map<String, dynamic>? _orderDetails;
  List<dynamic> _tokens = []; // List of tokens for the slider
  DateTime? _selectedDate;
  bool _isGenerateButtonDisabled = false;
  final PageController _pageController = PageController();
  int _currentPageIndex = 0;
  List<String> _menuTypes = ['Veg']; // Default to 'Veg' only

  // Animation Controller for notification icon
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _initializeAnimation();
    _initializeCurrentDay();
    _initializeMenu();
  }

  void _initializeAnimation() {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: -5, end: 5).animate(_controller);
  }

  void _initializeCurrentDay() {
    final DateTime today = DateTime.now();
    setState(() {
      _isTodaySunday = today.weekday == DateTime.sunday;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // Navigation Handler
  void _handleNavigation(int index) {
    if (index == _currentIndex) return;

    if (index == 1) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation1, animation2) => UserPage(),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
    }
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

      _determineBookingDay();
      await _fetchMenuData();
      await _fetchLatestOrderId();
      setState(() {
        _isInitialized = true;
      });
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    }
  }

  void _determineBookingDay() {
    final DateTime today = DateTime.now();
    final int currentDay = today.weekday; // 1 = Monday, 7 = Sunday
    DateTime bookedDayDate;

    if (currentDay >= 1 && currentDay <= 4) {
      // Monday to Thursday: Book for the next day
      bookedDayDate = today.add(Duration(days: 1));
    } else if (currentDay == 5) {
      // Friday: Book for Monday
      int daysToAdd = 3; // Friday +3 to get to Monday
      bookedDayDate = today.add(Duration(days: daysToAdd));
    } else if (currentDay == 6 || currentDay == 7) {
      // Saturday or Sunday: Book for Monday
      int daysToAdd = 8 - currentDay; // Saturday +2, Sunday +1
      bookedDayDate = today.add(Duration(days: daysToAdd));
    } else {
      // Default to next day
      bookedDayDate = today.add(Duration(days: 1));
    }

    String bookedDayName = DateFormat('EEEE').format(bookedDayDate);

    setState(() {
      _bookingDay = bookedDayName;
      _isWednesday = bookedDayDate.weekday == DateTime.wednesday;

      // Update menu types based on whether it's Wednesday
      if (_isWednesday) {
        _menuTypes = ['Veg', 'Egg', 'Non-Veg'];
      } else {
        _menuTypes = ['Veg'];
      }
      _activeFilter = null; // Reset active filter
    });
  }

  Future<void> _fetchMenuData({DateTime? date}) async {
    if (_jwtToken == null || _bookingDay.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    String dayToFetch =
        date != null ? DateFormat('EEEE').format(date) : _bookingDay;

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

  void _filterItems(String? category) {
    setState(() {
      _activeFilter = category;
    });

    if (category == null) {
      setState(() {
        _filteredItems = [];
        _selectedMenuId = null;
        _error = null; // Optionally clear any existing errors
      });
      return;
    }

    if (_menuData.isEmpty) {
      setState(() {
        _error = 'No menu data available.';
        _filteredItems = [];
        _selectedMenuId = null;
      });
      return;
    }

    List<dynamic> filtered = [];
    String? menuId;

    try {
      if (category == 'Veg') {
        dynamic vegMenu;
        try {
          vegMenu = _menuData.firstWhere((menu) => menu['isVeg'] == 1);
        } catch (e) {
          vegMenu = null;
        }
        if (vegMenu != null) {
          filtered = vegMenu['menuItems'];
          menuId = vegMenu['menuId'].toString();
        }
      } else if (category == 'Egg') {
        dynamic eggMenu;
        try {
          eggMenu = _menuData.firstWhere((menu) => menu['isVeg'] == 2);
        } catch (e) {
          eggMenu = null;
        }
        if (eggMenu != null) {
          filtered = eggMenu['menuItems'];
          menuId = eggMenu['menuId'].toString();
        }
      } else if (category == 'Non-Veg') {
        dynamic nonVegMenu;
        try {
          nonVegMenu = _menuData.firstWhere((menu) => menu['isVeg'] == 0);
        } catch (e) {
          nonVegMenu = null;
        }
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
    } catch (e) {
      setState(() {
        _error = 'An error occurred while filtering menu items.';
        _filteredItems = [];
        _selectedMenuId = null;
      });
      print('Error in _filterItems: $e');
    }
  }

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

  Future<void> _fetchOrderDetails(String orderId) async {
    final String apiUrl =
        'https://www.backend.amddas.net/api/order-details/user/future?userId=$_userId';

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

        // Format tokens
        List<dynamic> formattedTokens = activeTokens.map((detail) {
          return {
            'token': detail['token'],
            'validFor': _formatDate(detail['deliveryDate']),
          };
        }).toList();

        setState(() {
          _orderDetails = data.isNotEmpty ? data[0] : null;
          _tokens = formattedTokens;
          _isGenerateButtonDisabled = _tokens.isNotEmpty;
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
          _tokens = [];
          _isGenerateButtonDisabled = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'An error occurred while fetching order details.';
        _tokens = [];
        _isGenerateButtonDisabled = false;
      });
      print('Error fetching order details: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatDate(String? isoString) {
    if (isoString == null) return 'Invalid Date';

    DateTime date;
    try {
      date = DateTime.parse(isoString).toLocal();
    } catch (e) {
      return 'Invalid Date';
    }

    return DateFormat('yyyy-MM-dd').format(date);
  }

  void _selectDate(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select Delivery Date'),
          content: Container(
            height: 400,
            width: 300,
            child: SfDateRangePicker(
              onSelectionChanged: _onDateSelectionChanged,
              selectionMode: DateRangePickerSelectionMode.single,
              minDate:
                  DateTime.now().add(Duration(days: 1)), // Start from tomorrow
              maxDate: _calculateMaxDate(),
              enablePastDates: false,
              initialSelectedDate: null,
              // Disable Saturdays and Sundays
              monthViewSettings: DateRangePickerMonthViewSettings(
                blackoutDates: _getBlackoutDates(),
              ),
              monthCellStyle: DateRangePickerMonthCellStyle(
                blackoutDateTextStyle: TextStyle(
                  color: Colors.red,
                  decoration: TextDecoration.lineThrough,
                ),
                todayTextStyle:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                selectionTextStyle:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                disabledDatesDecoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              child: Text('OK'),
              onPressed: () async {
                Navigator.of(context).pop();
                if (_selectedDate != null) {
                  setState(() {
                    _bookingDay = DateFormat('EEEE').format(_selectedDate!);
                    _isWednesday = _selectedDate!.weekday == DateTime.wednesday;
                    _isGenerateButtonDisabled = false;

                    // Update menu types based on selected date
                    if (_isWednesday) {
                      _menuTypes = ['Veg', 'Egg', 'Non-Veg'];
                    } else {
                      _menuTypes = ['Veg'];
                    }
                    _activeFilter = null; // Reset active filter

                    _error = null;
                  });
                  await _fetchMenuData(date: _selectedDate);
                } else {
                  setState(() {
                    _error = 'Please select a delivery date.';
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Please select a delivery date.'),
                      backgroundColor: Colors.red,
                      duration: Duration(seconds: 3),
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _onDateSelectionChanged(DateRangePickerSelectionChangedArgs args) {
    if (args.value is DateTime) {
      DateTime selected = args.value;
      if (selected.weekday == DateTime.saturday ||
          selected.weekday == DateTime.sunday) {
        // Should not happen as weekends are disabled, but just in case
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Saturdays and Sundays are not allowed for bookings.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }
      setState(() {
        _selectedDate = selected;
      });
    }
  }

  DateTime _calculateMaxDate() {
    final DateTime today = DateTime.now();
    int daysToAdd = 13 - today.weekday; // Up to Friday of next week
    if (daysToAdd <= 0) {
      daysToAdd += 7;
    }
    final DateTime maxDate = today.add(Duration(days: daysToAdd));
    return maxDate;
  }

  List<DateTime> _getBlackoutDates() {
    List<DateTime> blackoutDates = [];
    DateTime startDate = DateTime.now();
    DateTime endDate = _calculateMaxDate();

    for (DateTime date = startDate;
        date.isBefore(endDate.add(Duration(days: 1)));
        date = date.add(Duration(days: 1))) {
      if (date.weekday == DateTime.saturday ||
          date.weekday == DateTime.sunday) {
        blackoutDates.add(date);
      }
    }
    return blackoutDates;
  }

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

    if (!_isWithinAllowedTime()) {
      setState(() {
        _error = 'Token generation is only allowed between 12 PM to 8 PM.';
      });
      return;
    }

    String formattedSelectedDate =
        DateFormat('yyyy-MM-dd').format(_selectedDate!);
    bool tokenExists =
        _tokens.any((t) => t['validFor'] == formattedSelectedDate);
    if (tokenExists) {
      setState(() {
        _error = 'You have already generated a token for the selected date.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Token already generated for this date.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() {
      _isGenerateButtonDisabled = true;
      _isLoading = true;
      _error = null;
    });

    final String formattedDate =
        DateFormat('yyyy-MM-dd').format(_selectedDate!);
    final String apiUrl =
        'https://www.backend.amddas.net/api/orders/submit?menuIds=$_selectedMenuId&quantities=1&deliveryDate=$formattedDate';

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $_jwtToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({}),
      );

      await _fetchLatestOrderId();

      setState(() {
        _isLoading = false;
        _isGenerateButtonDisabled = true;
        _error = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Token generated successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      print('Error generating token: $e');
      setState(() {
        _isLoading = false;
        _isGenerateButtonDisabled = false;
        _error = 'Failed to generate token. Please try again.';
      });
    }
  }

  Future<void> _cancelToken(String token, String deliveryDate) async {
    if (_isTodaySunday) {
      setState(() {
        _error = 'Token cancellation is not allowed on Sundays.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Token cancellation is not allowed on Sundays.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    if (!_isWithinAllowedTime()) {
      setState(() {
        _error = 'Token cancellation is only allowed between 12 PM to 8 PM.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Token cancellation is only allowed between 12 PM to 8 PM.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
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
          _isGenerateButtonDisabled = _tokens.isNotEmpty;

          if (_selectedDate != null &&
              DateFormat('yyyy-MM-dd').format(_selectedDate!) == deliveryDate) {
            _isGenerateButtonDisabled = false;
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Token cancelled successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        await _fetchLatestOrderId();
      } else {
        setState(() {
          _error = 'Failed to cancel order. Please try again.';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel order. Please try again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = 'An error occurred while cancelling the order.';
      });
      print('Error cancelling order: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred while cancelling the order.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

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

  bool _isWithinAllowedTime() {
    final now = DateTime.now();
    final hour = now.hour;
    return hour >= 12 && hour < 20; // 12 PM to 8 PM
  }

  Future<void> _refreshPage() async {
    await _fetchLatestOrderId();
    await _fetchMenuData();
  }

  void _showBookingInfo() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Booking Information'),
          content: Text(
            'Booking is allowed from:\n 12 PM to 8 PM.\n'
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

  List<DropdownMenuItem<String>> _getMenuDropdownItems() {
    return _menuTypes.map((String value) {
      return DropdownMenuItem<String>(
        value: value,
        child: Text(value),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: Stack(
          children: [
            // Background image covering entire screen
            Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('images/food.jpg'),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(0.6),
                    BlendMode.darken,
                  ),
                ),
              ),
            ),
            // Main content with curved header
            Column(
              children: [
                // Custom Curved Header
                Stack(
                  children: [
                    ClipPath(
                      clipper: HeaderClipper(),
                      child: Container(
                        height: 150,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color.fromARGB(255, 41, 110, 61).withOpacity(0.9),
                              Color.fromARGB(255, 58, 190, 96).withOpacity(0.9),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 40),
                      child: Align(
                        alignment:
                            Alignment.centerLeft, // Move to the start (left)
                        child: Text(
                          'MENU',
                          style: GoogleFonts.playfairDisplay(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 34,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                // Expandable content area
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _refreshPage,
                    child: SingleChildScrollView(
                      physics: AlwaysScrollableScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Token Details Section
                            if (_tokens.isNotEmpty)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Your Tokens',
                                    style: GoogleFonts.merriweather(
                                      fontSize: 24,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                      shadows: [
                                        Shadow(
                                          offset: Offset(1, 1),
                                          blurRadius: 3.0,
                                          color: Colors.black.withOpacity(0.5),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                  // Token Carousel
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.arrow_back,
                                            color: Colors.white),
                                        onPressed: () {
                                          if (_tokens.isNotEmpty) {
                                            if (_currentPageIndex > 0) {
                                              _currentPageIndex--;
                                            } else {
                                              _currentPageIndex =
                                                  _tokens.length - 1;
                                            }
                                            _pageController.animateToPage(
                                              _currentPageIndex,
                                              duration:
                                                  Duration(milliseconds: 300),
                                              curve: Curves.easeIn,
                                            );
                                          }
                                        },
                                      ),
                                      Expanded(
                                        child: SizedBox(
                                          height: 200,
                                          child: PageView.builder(
                                            controller: _pageController,
                                            itemCount: _tokens.length,
                                            onPageChanged: (index) {
                                              setState(() {
                                                _currentPageIndex = index;
                                              });
                                            },
                                            itemBuilder: (context, index) {
                                              var token = _tokens[index];
                                              return Card(
                                                color: Colors.white
                                                    .withOpacity(0.9),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(15),
                                                  side: BorderSide(
                                                    color: Colors.white
                                                        .withOpacity(0.2),
                                                    width: 1,
                                                  ),
                                                ),
                                                elevation: 4,
                                                child: Padding(
                                                  padding: const EdgeInsets.all(
                                                      16.0),
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Text(
                                                        'Token ID: ${token['token']}',
                                                        style: GoogleFonts
                                                            .sourceSans3(
                                                          fontSize: 20,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Color.fromARGB(
                                                              255, 41, 110, 61),
                                                        ),
                                                      ),
                                                      SizedBox(height: 10),
                                                      Text(
                                                        'Valid For: ${token['validFor']}',
                                                        style: GoogleFonts
                                                            .sourceSans3(
                                                          fontSize: 16,
                                                          color: Colors.black87,
                                                        ),
                                                      ),
                                                      SizedBox(height: 20),
                                                      if (!_isTodaySunday)
                                                        IconButton(
                                                          icon: Icon(
                                                              Icons.delete,
                                                              color: Colors
                                                                  .red[700]),
                                                          onPressed: () {
                                                            _showCancelConfirmationDialog(
                                                              token['token'],
                                                              token['validFor'],
                                                            );
                                                          },
                                                        )
                                                      else
                                                        Text(
                                                          'Token cannot be cancelled on Sundays',
                                                          style: GoogleFonts
                                                              .sourceSans3(
                                                            color:
                                                                Colors.red[700],
                                                            fontStyle: FontStyle
                                                                .italic,
                                                          ),
                                                          textAlign:
                                                              TextAlign.center,
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.arrow_forward,
                                            color: Colors.white),
                                        onPressed: () {
                                          if (_tokens.isNotEmpty) {
                                            if (_currentPageIndex <
                                                _tokens.length - 1) {
                                              _currentPageIndex++;
                                            } else {
                                              _currentPageIndex = 0;
                                            }
                                            _pageController.animateToPage(
                                              _currentPageIndex,
                                              duration:
                                                  Duration(milliseconds: 300),
                                              curve: Curves.easeIn,
                                            );
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),

                            SizedBox(height: 25),

                            // Date Picker Card
                            Card(
                              color: Colors.white.withOpacity(0.9),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                                side: BorderSide(
                                  color: Colors.white.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              elevation: 4,
                              child: ListTile(
                                leading: Icon(Icons.calendar_today,
                                    color: Color.fromARGB(255, 41, 110, 61)),
                                title: Text(
                                  _selectedDate == null
                                      ? 'Select Delivery Date'
                                      : 'Delivery Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate!)}',
                                  style: GoogleFonts.sourceSans3(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                                subtitle: _selectedDate != null
                                    ? Text(
                                        'Day: ${DateFormat('EEEE').format(_selectedDate!)}',
                                        style: GoogleFonts.sourceSans3(
                                            fontSize: 14,
                                            color: Colors.grey[700]),
                                      )
                                    : null,
                                trailing: Icon(Icons.arrow_forward_ios,
                                    color: Color.fromARGB(255, 41, 110, 61)),
                                onTap: () => _selectDate(context),
                              ),
                            ),

                            SizedBox(height: 25),

                            // Menu Title
                            Text(
                              'Booking for $_bookingDay Menu',
                              style: GoogleFonts.merriweather(
                                  fontSize: 26,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                  shadows: [
                                    Shadow(
                                      offset: Offset(1, 1),
                                      blurRadius: 3.0,
                                      color: Colors.black.withOpacity(0.5),
                                    ),
                                  ]),
                              textAlign: TextAlign.center,
                            ),

                            SizedBox(height: 20),

                            // Dropdown for Menu Types
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: DropdownButtonFormField<String>(
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.9),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(15),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 16),
                                ),
                                hint: Text('Select menu type'), // Added hint
                                value: _activeFilter,
                                items: _getMenuDropdownItems(),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    _activeFilter = newValue;
                                    _error = null;
                                    if (newValue != null) {
                                      _filterItems(newValue);
                                    } else {
                                      _filteredItems = [];
                                    }
                                  });
                                },
                                style: GoogleFonts.sourceSans3(
                                    color: Colors.black87,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500),
                              ),
                            ),

                            SizedBox(height: 20),

                            // Menu List
                            _isLoading
                                ? Center(
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Color.fromARGB(255, 41, 110, 61)),
                                    ),
                                  )
                                : _activeFilter == null
                                    ? Center(
                                        child: Text(
                                          'Please select a menu type to view items.',
                                          style: GoogleFonts.sourceSans3(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500),
                                        ),
                                      )
                                    : _filteredItems.isNotEmpty
                                        ? ListView.builder(
                                            shrinkWrap: true,
                                            physics:
                                                NeverScrollableScrollPhysics(),
                                            itemCount: _filteredItems.length,
                                            itemBuilder: (context, index) {
                                              var menuItem =
                                                  _filteredItems[index];
                                              var itemName = menuItem['item']
                                                      ?['itemName'] ??
                                                  'Unnamed Item';

                                              return Card(
                                                color: Colors.white
                                                    .withOpacity(0.9),
                                                margin: EdgeInsets.symmetric(
                                                    vertical: 6),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  side: BorderSide(
                                                    color: Colors.white
                                                        .withOpacity(0.2),
                                                    width: 1,
                                                  ),
                                                ),
                                                elevation: 3,
                                                child: ListTile(
                                                  title: Text(
                                                    itemName,
                                                    style:
                                                        GoogleFonts.sourceSans3(
                                                            fontSize: 18,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            color:
                                                                Colors.black87),
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
                                              style: GoogleFonts.sourceSans3(
                                                  color: Colors.red[300],
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w500),
                                            ),
                                          ),

                            SizedBox(height: 25),

                            // Generate Token Button
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: (_isTodaySunday ||
                                        _activeFilter ==
                                            null || // Ensure a filter is selected
                                        (_selectedDate != null &&
                                            _tokens.any((t) =>
                                                t['validFor'] ==
                                                DateFormat('yyyy-MM-dd')
                                                    .format(_selectedDate!))) ||
                                        !_isWithinAllowedTime() ||
                                        _isGenerateButtonDisabled)
                                    ? null
                                    : _generateToken,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: (_isTodaySunday ||
                                          _activeFilter ==
                                              null || // Ensure a filter is selected
                                          (_selectedDate != null &&
                                              _tokens.any((t) =>
                                                  t['validFor'] ==
                                                  DateFormat('yyyy-MM-dd')
                                                      .format(
                                                          _selectedDate!))) ||
                                          !_isWithinAllowedTime() ||
                                          _isGenerateButtonDisabled)
                                      ? Colors.grey[400]
                                      : Color.fromARGB(255, 41, 110, 61),
                                  disabledBackgroundColor: Colors.grey[400],
                                  disabledForegroundColor: Colors.grey[700],
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 80, vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  (_selectedDate != null &&
                                          _tokens.any((t) =>
                                              t['validFor'] ==
                                              DateFormat('yyyy-MM-dd')
                                                  .format(_selectedDate!)))
                                      ? 'Token Already Generated'
                                      : _isTodaySunday
                                          ? 'Booking Not Allowed Today'
                                          : !_isWithinAllowedTime()
                                              ? 'Generate Token (Unavailable)'
                                              : 'Generate Token',
                                  style: GoogleFonts.sourceSans3(
                                    color: (_isTodaySunday ||
                                            _activeFilter ==
                                                null || // Ensure a filter is selected
                                            (_selectedDate != null &&
                                                _tokens.any((t) =>
                                                    t['validFor'] ==
                                                    DateFormat('yyyy-MM-dd')
                                                        .format(
                                                            _selectedDate!))) ||
                                            !_isWithinAllowedTime() ||
                                            _isGenerateButtonDisabled)
                                        ? Colors.grey[700]
                                        : Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),

                            if (_isGenerateButtonDisabled)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                child: Text(
                                  'Please check your token section for the generated token.',
                                  style: GoogleFonts.sourceSans3(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500),
                                ),
                              ),

                            // Error Message
                            if (_error != null)
                              Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.8),
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.error, color: Colors.white),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        _error!,
                                        style: GoogleFonts.sourceSans3(
                                            color: Colors.white, fontSize: 16),
                                      ),
                                    )
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Floating Notification Icon
            Positioned(
              bottom: 80,
              right: 20,
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _animation.value),
                    child: GestureDetector(
                      onTap: _showBookingInfo,
                      child: Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.notifications_active,
                          color: Colors.red,
                          size: 30,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        bottomNavigationBar: _buildBottomNavigationBar(),
      ),
    );
  }

  // Build Bottom Navigation Bar
  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(0),
          topRight: Radius.circular(0),
        ),
      ),
      child: BottomNavigationBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        currentIndex: _currentIndex,
        selectedItemColor: Color(0xFFFC8019),
        unselectedItemColor: Colors.white,
        onTap: _handleNavigation,
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
    );
  }
}

/// Custom Clipper for Header
class HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    // Starting point
    path.lineTo(0, size.height - 60);
    // Single curve as in UserPage
    path.quadraticBezierTo(
      size.width / 4,
      size.height,
      size.width / 2,
      size.height - 40,
    );
    // Continuing to the top-right
    path.lineTo(size.width, size.height - 120);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
