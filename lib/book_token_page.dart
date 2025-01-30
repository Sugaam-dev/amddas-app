import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:flip_card/flip_card.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'appnavigator.dart';
import 'tokenpage.dart';

class BookTokenPage extends StatefulWidget {
  final String selectedDate; // e.g., "2025-01-15"
  final String selectedDay; // e.g., "Wednesday"

  const BookTokenPage({
    Key? key,
    required this.selectedDate,
    required this.selectedDay,
  }) : super(key: key);

  @override
  State<BookTokenPage> createState() => _BookTokenPageState();
}

enum ThaliType { veg, egg, nonVeg }

class _BookTokenPageState extends State<BookTokenPage> {
  // Flip-card style: fixed height
  final double _cardHeight = 300.0;
  // Add variables to track which card is flipped
  String? _selectedThaliContents;

  // Flutter Secure Storage to read the JWT, userId, etc.
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  String? _jwtToken;
  String? _userId;
  String? _email;

  // Quantity notifiers (for each card type)
  final ValueNotifier<int> _vegQuantityNotifier = ValueNotifier<int>(0);
  final ValueNotifier<int> _eggQuantityNotifier = ValueNotifier<int>(0);
  final ValueNotifier<int> _nonVegQuantityNotifier = ValueNotifier<int>(0);

  List<String> _getItemsForThali() {
    switch (_selectedThaliContents) {
      case 'veg':
        return _vegItems;
      case 'egg':
        return _eggItems;
      case 'nonveg':
        return _nonVegItems;
      default:
        return [];
    }
  }

  Color _getColorForThali() {
    switch (_selectedThaliContents) {
      case 'veg':
        return Colors.green;
      case 'egg':
        return Colors.orange;
      case 'nonveg':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Thali items loaded from API
  List<String> _vegItems = [];
  List<String> _eggItems = [];
  List<String> _nonVegItems = [];

  // We also store the actual menuIds to generate tokens
  int? _vegMenuId;
  int? _eggMenuId;
  int? _nonVegMenuId;

  bool _isLoading = false;
  String? _error;

  // To track selected thali on Wednesday
  ThaliType? _selectedThali;
  bool _isAnyQuantitySelected() {
    return _vegQuantityNotifier.value > 0 ||
        _eggQuantityNotifier.value > 0 ||
        _nonVegQuantityNotifier.value > 0;
  }

  @override
  void initState() {
    super.initState();
    _initUserData();
    // Add listeners to the quantity notifiers to trigger UI updates
    _vegQuantityNotifier.addListener(_onQuantityChanged);
    _eggQuantityNotifier.addListener(_onQuantityChanged);
    _nonVegQuantityNotifier.addListener(_onQuantityChanged);
  }

  @override
  void dispose() {
    _vegQuantityNotifier.removeListener(_onQuantityChanged);
    _eggQuantityNotifier.removeListener(_onQuantityChanged);
    _nonVegQuantityNotifier.removeListener(_onQuantityChanged);
    _vegQuantityNotifier.dispose();
    _eggQuantityNotifier.dispose();
    _nonVegQuantityNotifier.dispose();
    super.dispose();
  }

// Listener to handle quantity changes
  void _onQuantityChanged() {
    setState(() {
      // This will rebuild the UI to show/hide the confirm button
    });
  }

  // Method to handle card flip

  /// 1) Read token, userId, email from Secure Storage
  /// 2) If found, call _fetchMenuData().
  Future<void> _initUserData() async {
    final jwt = await _secureStorage.read(key: 'jwt_token');
    print('JWT Token: $jwt');
    final uid = await _secureStorage.read(key: 'user_id');
    final mail = await _secureStorage.read(key: 'user_email');

    if (jwt == null || uid == null || mail == null) {
      setState(() {
        _error = 'Missing credentials. Please log in again.';
      });
      return;
    }

    setState(() {
      _jwtToken = jwt;
      _userId = uid;
      _email = mail;
    });

    // Now fetch the menu data for the selected day
    _fetchMenuData();
  }

  /// Fetch the menu data for the selected day from your API, using the JWT token.
  /// Then parse out the Veg/Egg/Non-Veg lists (like in your original MenuPage).
  Future<void> _fetchMenuData() async {
    if (_jwtToken == null) {
      setState(() {
        _error = 'No valid token found. Please log in again.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final String dayToFetch = widget.selectedDay; // e.g., "Wednesday"
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
        final List<dynamic> data = json.decode(response.body);

        // For Veg (isVeg=1), Egg (isVeg=2), Non-Veg (isVeg=0)
        final vegMenu =
            data.firstWhere((m) => m['isVeg'] == 1, orElse: () => null);
        final eggMenu =
            data.firstWhere((m) => m['isVeg'] == 2, orElse: () => null);
        final nonVegMenu =
            data.firstWhere((m) => m['isVeg'] == 0, orElse: () => null);

        setState(() {
          // Extract menu ID
          _vegMenuId = vegMenu?['menuId'];
          _eggMenuId = eggMenu?['menuId'];
          _nonVegMenuId = nonVegMenu?['menuId'];

          // Convert each to a List<String> of item names
          _vegItems = (vegMenu != null && vegMenu['menuItems'] != null)
              ? (vegMenu['menuItems'] as List)
                  .map((item) => item['item']['itemName'] as String)
                  .toList()
              : [];

          _eggItems = (eggMenu != null && eggMenu['menuItems'] != null)
              ? (eggMenu['menuItems'] as List)
                  .map((item) => item['item']['itemName'] as String)
                  .toList()
              : [];

          _nonVegItems = (nonVegMenu != null && nonVegMenu['menuItems'] != null)
              ? (nonVegMenu['menuItems'] as List)
                  .map((item) => item['item']['itemName'] as String)
                  .toList()
              : [];
        });
      } else if (response.statusCode == 403) {
        setState(() {
          _error = 'Session expired. Please log in again.';
        });
      } else {
        setState(() {
          _error =
              'Failed to fetch menu data. Status code: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'An error occurred: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// The "Confirm Booking" logic which mimics your "Generate Token" logic.
  /// 1) Build a comma-separated list of menuIds where quantity > 0
  /// 2) Build a corresponding list of quantities
  /// 3) Call the API to generate tokens
  /// 4) If success => navigate to TokenPage
  Future<void> _confirmBooking() async {
    // Check if the current time is within allowed booking hours
    if (!_isWithinAllowedTime()) {
      setState(() {
        _error = 'Bookings are only allowed between 12 PM and 8 PM.';
      });
      return; // Exit early since booking is not allowed
    }
    // Gather selected menu IDs & quantities
    final List<int> selectedMenuIds = [];
    final List<int> selectedQuantities = [];

    // Veg
    if (_vegMenuId != null && _vegQuantityNotifier.value > 0) {
      selectedMenuIds.add(_vegMenuId!);
      selectedQuantities.add(_vegQuantityNotifier.value);
    }
    // Egg and Non-Veg only on Wednesday
    if (widget.selectedDay.toLowerCase() == 'wednesday') {
      if (_eggMenuId != null && _eggQuantityNotifier.value > 0) {
        selectedMenuIds.add(_eggMenuId!);
        selectedQuantities.add(_eggQuantityNotifier.value);
      }
      if (_nonVegMenuId != null && _nonVegQuantityNotifier.value > 0) {
        selectedMenuIds.add(_nonVegMenuId!);
        selectedQuantities.add(_nonVegQuantityNotifier.value);
      }
    }

    // If no items selected
    if (selectedMenuIds.isEmpty) {
      // Trigger a visual highlight for quantity selectors
      setState(() {
        _vegQuantityNotifier.value = _vegQuantityNotifier.value;
        _eggQuantityNotifier.value = _eggQuantityNotifier.value;
        _nonVegQuantityNotifier.value = _nonVegQuantityNotifier.value;
      });

      setState(() {
        _error = 'Please select at least one thali quantity.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Build the URL
      // E.g. /api/orders/submit?menuIds=1,2&quantities=1,2&deliveryDate=2025-01-15
      final String menuIdsParam = selectedMenuIds.join(',');
      final String quantitiesParam = selectedQuantities.join(',');
      final String formattedDate =
          widget.selectedDate; // Already in yyyy-MM-dd?

      final String apiUrl =
          'https://www.backend.amddas.net/api/orders/submit?menuIds=$menuIdsParam&quantities=$quantitiesParam&deliveryDate=$formattedDate';

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $_jwtToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Successfully created token
        // Optionally parse the response if you want to show a success message
        // Then navigate to TokenPage
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const AppNavigator(initialIndex: 1),
          ),
        );
      } else if (response.statusCode == 403) {
        setState(() {
          _error = 'Session expired. Please log in again.';
        });
      } else {
        setState(() {
          _error =
              'Failed to generate token. Status code: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error generating token: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// (Optional) For time-based restrictions
  bool _isWithinAllowedTime() {
    final now = DateTime.now();
    final hour = now.hour;
    return hour >= 12 && hour < 20; // 12 PM to 8 PM
  }

  /// Handle thali selection for Wednesday
  void _handleThaliSelection(ThaliType type, int value) {
    if (widget.selectedDay.toLowerCase() == 'wednesday') {
      setState(() {
        if (value == 1) {
          _selectedThali = type;
          // Set the selected quantity to 1 and others to 0
          switch (type) {
            case ThaliType.veg:
              _vegQuantityNotifier.value = 1;
              _eggQuantityNotifier.value = 0;
              _nonVegQuantityNotifier.value = 0;
              break;
            case ThaliType.egg:
              _vegQuantityNotifier.value = 0;
              _eggQuantityNotifier.value = 1;
              _nonVegQuantityNotifier.value = 0;
              break;
            case ThaliType.nonVeg:
              _vegQuantityNotifier.value = 0;
              _eggQuantityNotifier.value = 0;
              _nonVegQuantityNotifier.value = 1;
              break;
          }
        } else if (value == 0) {
          _selectedThali = null;
          switch (type) {
            case ThaliType.veg:
              _vegQuantityNotifier.value = 0;
              break;
            case ThaliType.egg:
              _eggQuantityNotifier.value = 0;
              break;
            case ThaliType.nonVeg:
              _nonVegQuantityNotifier.value = 0;
              break;
          }
        }
      });
    }
  }

  /// Build the front side of the FlipCard
  Widget _buildFrontCard({
    required String title,
    required ValueNotifier<int> quantityNotifier,
    required Color borderColor,
    required ThaliType type,
    required String description,
    required String imagePath,
  }) {
    bool isWednesday = widget.selectedDay.toLowerCase() == 'wednesday';
    bool isDisabled = false;

    if (isWednesday && _selectedThali != null && _selectedThali != type) {
      isDisabled = true;
    }

    // Determine min and max based on the day
    int minQuantity = 0;
    int maxQuantity = 1;

    return SizedBox(
      height: _cardHeight,
      child: Opacity(
        opacity: isDisabled ? 0.5 : 1.0,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.symmetric(
              horizontal: BorderSide(color: Colors.grey[300]!),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                spreadRadius: 2,
                blurRadius: 5,
                offset: const Offset(0, 3), // changes position of shadow
              ),
            ],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    imagePath,
                    height: 100,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 12),
                // Title + (Veg/Egg/NonVeg) indicator
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        border: Border.all(color: borderColor),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(
                        Icons.circle,
                        color: borderColor,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Description
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
                const Spacer(),
                // Quantity Selector
                _buildQuantitySelector(
                  quantityNotifier: quantityNotifier,
                  isDisabled: isDisabled,
                  minQuantity: minQuantity,
                  maxQuantity: maxQuantity,
                  onChanged: (value) {
                    if (isWednesday) {
                      _handleThaliSelection(type, value);
                    } else {
                      setState(() {
                        quantityNotifier.value = value;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Quantity selector with +/- icons
  Widget _buildQuantitySelector({
    required ValueNotifier<int> quantityNotifier,
    required bool isDisabled,
    required int minQuantity,
    required int maxQuantity,
    required Function(int) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDisabled ? Colors.grey : Colors.blueAccent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ValueListenableBuilder<int>(
            valueListenable: quantityNotifier,
            builder: (context, quantity, _) {
              return Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    color: Colors.white,
                    onPressed: (quantity > minQuantity && !isDisabled)
                        ? () {
                            onChanged(quantity - 1);
                          }
                        : null,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      quantity.toString(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    color: Colors.white,
                    onPressed: (quantity < maxQuantity && !isDisabled)
                        ? () {
                            onChanged(quantity + 1);
                          }
                        : null,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // Build the main thali card
  Widget _buildThaliCard({
    required String title,
    required ValueNotifier<int> quantityNotifier,
    required Color borderColor,
    required ThaliType type,
    required String description,
    required String imagePath,
    required VoidCallback onViewContents,
    bool isDisabled = false,
  }) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: SingleChildScrollView(
                child: _buildContentsCard(
                  title: title,
                  items: _getThaliItems(type),
                  borderColor: borderColor,
                ),
              ),
            );
          },
        );
      },
      child: Container(
        height: _cardHeight,
        child: Opacity(
          opacity: isDisabled ? 0.5 : 1.0,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      imagePath,
                      height: 100,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          border: Border.all(color: borderColor),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Icon(Icons.circle, color: borderColor, size: 16),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return Dialog(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: SingleChildScrollView(
                                        child: _buildContentsCard(
                                          title: title,
                                          items: _getThaliItems(type),
                                          borderColor: borderColor,
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                              child: Text(
                                'View Contents',
                                style: TextStyle(color: borderColor),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  _buildQuantitySelector(
                    quantityNotifier: quantityNotifier,
                    isDisabled: isDisabled,
                    minQuantity: 0,
                    maxQuantity: 1,
                    onChanged: (value) {
                      if (widget.selectedDay.toLowerCase() == 'wednesday') {
                        _handleThaliSelection(type, value);
                      } else {
                        quantityNotifier.value = value;
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Add this method to the _BookTokenPageState class
  List<String> _getThaliItems(ThaliType type) {
    switch (type) {
      case ThaliType.veg:
        return _vegItems;
      case ThaliType.egg:
        return _eggItems;
      case ThaliType.nonVeg:
        return _nonVegItems;
    }
  }

  // Build the contents card
  Widget _buildContentsCard({
    required String title,
    required List<String> items,
    required Color borderColor,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$title Contents',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 16),
            itemBuilder: (context, index) {
              return Row(
                children: [
                  Icon(
                    Icons.restaurant_menu,
                    color: borderColor,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      items[index],
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWednesday = widget.selectedDay.toLowerCase() == 'wednesday';

    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              // Header
              ClipPath(
                clipper: HeaderClipper(),
                child: Container(
                  height: 180,
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 40),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Menu  for Booking',
                              style: TextStyle(
                                fontSize: 24,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              widget.selectedDate,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(width: 50),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? Center(
                            child: Text(
                              _error!,
                              style: const TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                          )
                        : Column(
                            children: [
                              // Content Area
                              Expanded(
                                child: ListView(
                                  padding: const EdgeInsets.all(16),
                                  children: [
                                    // Date and Day info
                                    Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.grey.withOpacity(0.2),
                                              spreadRadius: 1,
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.calendar_today,
                                              color: Theme.of(context)
                                                  .primaryColor,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              widget.selectedDate,
                                              style: GoogleFonts.sourceSans3(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Container(
                                              width: 1,
                                              height: 20,
                                              color: Colors.grey[300],
                                            ),
                                            const SizedBox(width: 16),
                                            Icon(
                                              Icons.watch_later_outlined,
                                              color: Theme.of(context)
                                                  .primaryColor,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              widget.selectedDay,
                                              style: GoogleFonts.sourceSans3(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    // Veg Thali
                                    _buildThaliCard(
                                      title: 'Veg Thali',
                                      quantityNotifier: _vegQuantityNotifier,
                                      borderColor: Colors.green,
                                      type: ThaliType.veg,
                                      description:
                                          'A wholesome vegetarian thali with a variety of dishes.',
                                      imagePath: 'images/thali.jpg',
                                      onViewContents: () => setState(
                                          () => _selectedThaliContents = 'veg'),
                                      isDisabled: isWednesday &&
                                          _selectedThali != null &&
                                          _selectedThali != ThaliType.veg,
                                    ),
                                    if (_selectedThaliContents == 'veg')
                                      _buildContentsCard(
                                        title: 'Veg Thali',
                                        items: _vegItems,
                                        borderColor: Colors.green,
                                      ),
                                    if (isWednesday) ...[
                                      const SizedBox(height: 20),
                                      // Egg Thali
                                      _buildThaliCard(
                                        title: 'Egg Thali',
                                        quantityNotifier: _eggQuantityNotifier,
                                        borderColor: Colors.orange,
                                        type: ThaliType.egg,
                                        description:
                                            'A delicious egg-based thali with rich flavors.',
                                        imagePath: 'images/thali.jpg',
                                        onViewContents: () => setState(() =>
                                            _selectedThaliContents = 'egg'),
                                        isDisabled: _selectedThali != null &&
                                            _selectedThali != ThaliType.egg,
                                      ),
                                      if (_selectedThaliContents == 'egg')
                                        _buildContentsCard(
                                          title: 'Egg Thali',
                                          items: _eggItems,
                                          borderColor: Colors.orange,
                                        ),
                                      const SizedBox(height: 20),
                                      // Non-Veg Thali
                                      _buildThaliCard(
                                        title: 'Non-Veg Thali',
                                        quantityNotifier:
                                            _nonVegQuantityNotifier,
                                        borderColor: Colors.red,
                                        type: ThaliType.nonVeg,
                                        description:
                                            'A hearty non-vegetarian thali with a variety of meats.',
                                        imagePath: 'images/thali.jpg',
                                        onViewContents: () => setState(() =>
                                            _selectedThaliContents = 'nonveg'),
                                        isDisabled: _selectedThali != null &&
                                            _selectedThali != ThaliType.nonVeg,
                                      ),
                                      if (_selectedThaliContents == 'nonveg')
                                        _buildContentsCard(
                                          title: 'Non-Veg Thali',
                                          items: _nonVegItems,
                                          borderColor: Colors.red,
                                        ),
                                    ],
                                    const SizedBox(
                                        height: 80), // Space for button
                                  ],
                                ),
                              ),
                            ],
                          ),
              ),
            ],
          ),
          Positioned(
            top: 60,
            right: 20,
            child: Container(
              padding: EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
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
        ],
      ),
      // Floating action button style confirm button
      floatingActionButton: _isAnyQuantitySelected()
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ElevatedButton(
                onPressed: _confirmBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text(
                  'Confirm Booking',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )
          : null,
    );
  }
}

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


// it worked now some changes like when we click on view contents i want the show the *buildcontentscard as a popup  so the user can  see the *_buildcontentcard only
