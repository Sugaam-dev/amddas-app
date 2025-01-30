import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'glass_container.dart';
import 'book_token_page.dart';
import 'login_page.dart';

/// Define the OrderDetail model with additional fields
class OrderDetail {
  final String deliveryDate;
  final int quantity;
  final int isActive;
  final int orderQtyCount;
  final String token;

  OrderDetail({
    required this.deliveryDate,
    required this.quantity,
    required this.isActive,
    required this.orderQtyCount,
    required this.token,
  });

  factory OrderDetail.fromJson(Map<String, dynamic> json) {
    return OrderDetail(
      deliveryDate: json['deliveryDate'],
      quantity: json['quantity'],
      isActive: json['isActive'],
      orderQtyCount: json['orderQtyCount'],
      token: json['token'],
    );
  }
}

class DatePickerPage extends StatefulWidget {
  const DatePickerPage({Key? key}) : super(key: key);

  @override
  State<DatePickerPage> createState() => _DatePickerPageState();
}

class _DatePickerPageState extends State<DatePickerPage> {
  // Controller for showing the selected date in a TextField
  final TextEditingController _dateController = TextEditingController();

  // Define tomorrow and the last allowed date
  final DateTime _tomorrow = DateTime.now().add(const Duration(days: 1));

  // Map to store the total quantity per delivery date
  Map<String, int> _quantityMap = {};

  // List to store disabled dates
  List<DateTime> _disabledDates = [];

  // Loading and error states
  bool _isLoading = true;
  String? _errorMessage;
  String userEmail = "Loading...";

  // Flutter Secure Storage instance
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  // Variables to store fetched userId and JWT token
  String? _userId;
  String? _jwtToken;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  /// Initialize user data by fetching from secure storage
  Future<void> _fetchUserData() async {
    try {
      String? email = await _secureStorage.read(key: 'user_email');
      String? userId = await _secureStorage.read(key: 'user_id');
      String? jwtToken =
          await _secureStorage.read(key: 'jwt_token'); // Assuming you store JWT

      print(userId);

      if (email != null && userId != null && jwtToken != null) {
        setState(() {
          userEmail = email;
          _userId = userId;
          _jwtToken = jwtToken;
          _isLoading = false;
        });

        // Fetch disabled dates after successfully fetching user data
        await _fetchDisabledDates();
      } else {
        setState(() {
          userEmail = "Data not found";
          _isLoading = false;
        });

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
        );
      }
    } catch (e) {
      setState(() {
        userEmail = "Error fetching data";
        _isLoading = false;
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    }
  }

  /// Fetch existing orders from the API and populate _disabledDates
  Future<void> _fetchDisabledDates() async {
    final String apiUrl =
        'https://www.backend.amddas.net/api/order-details/user/future?userId=$_userId';

    try {
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $_jwtToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        // Directly decode as List instead of Map
        final List<dynamic> data = json.decode(response.body);

        // Parse the data into OrderDetail objects
        List<OrderDetail> orders =
            data.map((json) => OrderDetail.fromJson(json)).toList();

        // Rest of your code remains the same
        Map<String, int> tempQuantityMap = {};

        for (var order in orders) {
          String formattedDate = DateFormat('yyyy-MM-dd')
              .format(DateTime.parse(order.deliveryDate));

          if (order.isActive == 1) {
            if (!tempQuantityMap.containsKey(formattedDate)) {
              tempQuantityMap[formattedDate] = 0;
            }
            tempQuantityMap[formattedDate] = order.quantity;
          }
        }

        setState(() {
          _quantityMap = tempQuantityMap;
          _disabledDates = _quantityMap.entries
              .where((entry) => entry.value >= 1)
              .map((entry) => DateTime.parse(entry.key))
              .toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage =
              'Failed to load data. Status Code: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred while fetching data: $e';
        _isLoading = false;
      });
    }
  }

  /// Pick a date from tomorrow up to tomorrow + 9 days.
  /// Disable Saturdays (6), Sundays (7), and dates present in _disabledDates.
  Future<void> _pickDate() async {
    final DateTime lastAllowedDate = _tomorrow.add(const Duration(days: 9));

    // Find the first selectable date starting from _tomorrow
    DateTime initialDate = _findFirstSelectableDate(_tomorrow, lastAllowedDate);

    // If no selectable date is found, show an error
    if (initialDate.isAfter(lastAllowedDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No selectable dates available in the range.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: _tomorrow,
      lastDate: lastAllowedDate,
      // Disable weekends and dates in _disabledDates
      selectableDayPredicate: (date) {
        // Normalize the date by removing the time component
        DateTime normalizedDate = DateTime(date.year, date.month, date.day);
        return date.weekday < 6 && !_disabledDates.contains(normalizedDate);
      },
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: Colors.green.shade600,
            onPrimary: Colors.white,
            onSurface: Colors.black,
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              foregroundColor: Colors.green.shade600,
            ),
          ),
        ),
        child: child!,
      ),
    );

    if (selectedDate != null) {
      // Display the date in the TextField
      setState(() {
        _dateController.text = DateFormat('yyyy-MM-dd').format(selectedDate);
      });
    }
  }

  /// Finds the first selectable date starting from [startDate] up to [endDate].
  DateTime _findFirstSelectableDate(DateTime startDate, DateTime endDate) {
    DateTime date = startDate;
    while (date.isBefore(endDate.add(const Duration(days: 1)))) {
      if (_isSelectable(date)) {
        return date;
      }
      date = date.add(const Duration(days: 1));
    }
    return endDate
        .add(const Duration(days: 1)); // Return a date beyond the range
  }

  /// Determines if a given date is selectable (i.e., not Saturday, not Sunday, and not in _disabledDates).
  bool _isSelectable(DateTime date) {
    // Normalize the date by removing the time component
    DateTime normalizedDate = DateTime(date.year, date.month, date.day);
    return date.weekday < 6 && !_disabledDates.contains(normalizedDate);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          /// Curved Header
          ClipPath(
            clipper: HeaderClipper(),
            child: Container(
              height: 200,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color.fromARGB(255, 41, 110, 61),
                    Color.fromARGB(255, 58, 190, 96),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Row(
                  children: [
                    // User Information and Subtext
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Reserve a date!',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'book your token',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                    // You can add more widgets here if needed
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 50,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [
                    Color.fromARGB(255, 36, 163, 72),
                    Color.fromARGB(255, 58, 190, 96)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: CircleAvatar(
                radius: 50,
                backgroundImage: AssetImage('images/amd.png'),
                backgroundColor: Colors.transparent,
              ),
            ),
          ),

          /// Main content
          SafeArea(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : _errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 40),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [],
                            ),
                            const SizedBox(height: 120),

                            // Instruction Text
                            Text(
                              'Pick a date to book your token.\n'
                              'Date starts from tomorrow, up to 9 days ahead.\n'
                              'Weekends (Sat, Sun) and already booked dates are not allowed.',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.bold,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),

                            // Glass Container with Date TextField
                            GlassContainer(
                              opacity: 0.1,
                              borderRadius: BorderRadius.circular(16),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: _buildDateTextField(),
                              ),
                            ),

                            const SizedBox(height: 40),

                            // Proceed Button
                            ElevatedButton(
                              onPressed: () {
                                if (_dateController.text.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content:
                                          Text('Please select a date first.'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }

                                final DateTime parsedDate = DateTime.parse(
                                  _dateController.text,
                                );
                                final String selectedDay =
                                    DateFormat('EEEE').format(parsedDate);

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => BookTokenPage(
                                      selectedDate: _dateController.text,
                                      selectedDay: selectedDay,
                                    ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade600,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                  horizontal: 24,
                                ),
                              ),
                              child: Text(
                                'Proceed to Book Token',
                                style: GoogleFonts.sourceSans3(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTextField() {
    return TextField(
      controller: _dateController,
      onTap: _pickDate,
      readOnly: true,
      style: const TextStyle(fontSize: 16, color: Colors.black87),
      decoration: InputDecoration(
        hintText: 'YYYY-MM-DD',
        hintStyle: TextStyle(color: Colors.green.shade300),
        labelText: 'Delivery Date',
        labelStyle: const TextStyle(color: Colors.black87),
        suffixIcon: IconButton(
          icon: Icon(Icons.calendar_today, color: Colors.green.shade600),
          onPressed: _pickDate,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.green.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.green.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.green.shade600, width: 2),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.8),
      ),
    );
  }
}

/// Custom Clipper for the Header
class HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 60);
    path.quadraticBezierTo(
      size.width / 4,
      size.height,
      size.width / 2,
      size.height - 40,
    );
    path.lineTo(size.width, size.height - 120);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
