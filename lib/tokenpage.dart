import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'dart:convert';

import 'login_page.dart';

class TokenPage extends StatefulWidget {
  const TokenPage({Key? key}) : super(key: key);

  @override
  _TokenPageState createState() => _TokenPageState();
}

class TokenData {
  final String tokenNumber;
  final String status;
  final String displayDate;
  final Color color;
  final DateTime originalDate;

  TokenData({
    required this.tokenNumber,
    required this.status,
    required this.displayDate,
    required this.color,
    DateTime? providedDate, // Make it optional
  }) : originalDate = providedDate ??
            DateTime(2000, 1, 1); // Default to past date if null
}

class _TokenPageState extends State<TokenPage> {
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  String? _jwtToken;
  String? _userId;
  bool _isLoading = true;
  String? _error;
  List<TokenData> _tokens = [];
  bool _isTodaySunday = DateTime.now().weekday == DateTime.sunday;
  bool _isGenerateButtonDisabled = false;

  @override
  void initState() {
    super.initState();
    _initializeAndFetchTokens();
  }

  Future<void> _initializeAndFetchTokens() async {
    await _initialize();
    if (_jwtToken != null && _userId != null) {
      await _fetchLatestOrderId();
    }
  }

  Future<void> _initialize() async {
    try {
      String? token = await _secureStorage.read(key: 'jwt_token');
      String? userId = await _secureStorage.read(key: 'user_id');

      if (token == null || userId == null) {
        setState(() {
          _error = 'Authentication details not found. Please log in again.';
          _isLoading = false;
        });
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
        );
        return;
      }

      setState(() {
        _jwtToken = token;
        _userId = userId;
      });
    } catch (e) {
      setState(() {
        _error = 'An error occurred during initialization.';
        _isLoading = false;
      });
      print('Initialization Error: $e');
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
        String fetchedOrderId = data['orderId']?.toString() ?? '';

        if (fetchedOrderId.isEmpty) {
          setState(() {
            _error = 'No recent orders found.';
            _isLoading = false;
          });
          return;
        }

        setState(() {
          _error = null;
        });
        await _fetchOrderDetails(fetchedOrderId);
      } else if (response.statusCode == 403) {
        setState(() {
          _error = 'Session expired. Please log in again.';
          _isLoading = false;
        });
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
        );
      } else {
        setState(() {
          _error = 'No recent orders found.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to fetch order data. Please try again.';
        _isLoading = false;
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
        var jsonData = json.decode(response.body);

        if (jsonData is! List) {
          setState(() {
            _error = 'Invalid data format received.';
            _isLoading = false;
          });
          return;
        }

        List<dynamic> data = jsonData;
        DateTime now = DateTime.now();

        List<TokenData> formattedTokens = [];

        for (var detail in data) {
          if (detail is! Map<String, dynamic>) {
            continue;
          }

          // Only process tokens where isActive = 1
          if (detail['isActive'] != 1) {
            continue;
          }

          // Safely parse the date with a fallback
          DateTime deliveryDate;
          try {
            deliveryDate =
                DateTime.parse(detail['deliveryDate'] ?? '').toLocal();
          } catch (e) {
            deliveryDate = DateTime(2000, 1, 1);
          }

          // Skip if date has passed or is the default date
          if (deliveryDate.isBefore(DateTime(now.year, now.month, now.day)) ||
              deliveryDate == DateTime(2000, 1, 1)) {
            continue;
          }

          // Calculate status and color based on date
          String status;
          Color color;

          if (isSameDay(deliveryDate, now)) {
            status = 'Active';
            color = Colors.green;
          } else {
            Duration difference = deliveryDate.difference(now);
            if (difference.inDays > 3) {
              status = 'Waiting';
              color = Colors.orange;
            } else {
              status = 'Upcoming';
              color = Colors.blue;
            }
          }

          formattedTokens.add(TokenData(
            tokenNumber: detail['token']?.toString() ?? 'Unknown',
            status: status,
            displayDate: formatDate(deliveryDate),
            color: color,
            providedDate: deliveryDate,
          ));
        }

        // Sort tokens by date
        formattedTokens
            .sort((a, b) => a.originalDate.compareTo(b.originalDate));

        setState(() {
          _tokens = formattedTokens;
          _isLoading = false;
          _error = null;
        });
      } else if (response.statusCode == 403) {
        setState(() {
          _error = 'Session expired. Please log in again.';
          _isLoading = false;
        });
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
        );
      } else {
        setState(() {
          _error = 'Failed to fetch order details.';
          _tokens = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'An error occurred while fetching order details.';
        _tokens = [];
        _isLoading = false;
      });
      print('Error fetching order details: $e');
    }
  }

  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  String formatDate(DateTime date) {
    DateTime now = DateTime.now();

    // If it's the default date, return an appropriate message
    if (date == DateTime(2000, 1, 1)) {
      return 'Date not available';
    }

    if (isSameDay(date, now)) {
      return 'Today';
    }

    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Future<void> _refreshTokens() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _tokens = [];
    });
    await _fetchLatestOrderId();
  }

  Future<void> _cancelToken(
    String token,
  ) async {
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
          _tokens.removeWhere((t) => t.tokenNumber == token);
          _isGenerateButtonDisabled = _tokens.isNotEmpty;
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

  void _showCancelConfirmationDialog(
    String token,
  ) {
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
                _cancelToken(
                  token,
                );
              },
            ),
            TextButton(
              child: Text('No'),
              onPressed: () {
                Navigator.of(context).pop();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Stack(
        children: [
          // Main Content Positioned below the header
          Positioned.fill(
            child: Column(
              children: [
                // Header with custom clip
                ClipPath(
                  clipper: HeaderClipper(),
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color.fromARGB(255, 41, 110, 61),
                          Color.fromARGB(255, 58, 190, 96)
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 40),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // User Info on the Left
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Welcome, User!',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Here are your tokens',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                              width:
                                  50), // Adds space between the text and avatar
                        ],
                      ),
                    ),
                  ),
                ),
                // Spacer to push content below the header
                SizedBox(height: 20),
                // Expanded to fill the remaining space
                Expanded(
                  child: _isLoading
                      ? Center(
                          child: CircularProgressIndicator(
                            color: Colors.green,
                          ),
                        )
                      : _error != null
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(
                                  _error!,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 18,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _refreshTokens,
                              child: _tokens.isEmpty
                                  ? SingleChildScrollView(
                                      physics:
                                          const AlwaysScrollableScrollPhysics(),
                                      child: Container(
                                        height:
                                            MediaQuery.of(context).size.height -
                                                280, // Adjusted height
                                        alignment: Alignment.center,
                                        child: const Text(
                                          'No tokens available.',
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 18,
                                          ),
                                        ),
                                      ),
                                    )
                                  : ListView.builder(
                                      physics: const BouncingScrollPhysics(),
                                      padding: const EdgeInsets.all(16.0),
                                      itemCount: _tokens.length,
                                      itemBuilder: (context, index) {
                                        final token = _tokens[index];
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                              bottom: 16.0),
                                          child: TokenCard(
                                            tokenNumber: token.tokenNumber,
                                            status: token.status,
                                            displayDate: token.displayDate,
                                            color: token.color,
                                            onDelete: () =>
                                                _showCancelConfirmationDialog(
                                              token.tokenNumber,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                            ),
                ),
              ],
            ),
          ),
          // Positioned Image
          Positioned(
            top: 50, // Adjust to position the avatar halfway outside the header
            right: 20,
            child: Container(
              padding: EdgeInsets.all(4), // Border thickness
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Color.fromARGB(255, 36, 163, 72),
                    Color.fromARGB(255, 58, 190, 96)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ), // Dark green border color
              ),
              child: CircleAvatar(
                radius: 50,
                backgroundImage: AssetImage(
                    'images/amd.png'), // Replace with actual image path
                backgroundColor: Colors.transparent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TokenCard extends StatelessWidget {
  final String tokenNumber;
  final String status;
  final String displayDate;
  final Color color;
  final VoidCallback? onDelete;

  const TokenCard({
    Key? key,
    required this.tokenNumber,
    required this.status,
    required this.displayDate,
    required this.color,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 140),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 15,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Token Number',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  tokenNumber,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 20,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          displayDate,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: onDelete,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Custom Clipper for the header's curved shape
class HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
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
