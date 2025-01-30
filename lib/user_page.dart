import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'login_page.dart';
import 'menu_page.dart';
import 'package:url_launcher/url_launcher.dart';

class UserPage extends StatefulWidget {
  @override
  _UserPageState createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  int _currentIndex = 1;
  String userEmail = "Loading...";
  bool _isLoading = true;
  String? _userId;
  bool _isManageProfileExpanded = false;
  bool _isManageProfileExpand = false;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      String? email = await _secureStorage.read(key: 'user_email');
      String? userId = await _secureStorage.read(key: 'user_id');

      if (email != null && userId != null) {
        setState(() {
          userEmail = email;
          _userId = userId;
          _isLoading = false;
        });
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

  // Back Button Handler
  Future<bool> _onWillPop() async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Exit App!'),
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

  Future<void> _logout() async {
    try {
      await _secureStorage.deleteAll();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred during logout. Please try again.'),
        ),
      );
    }
  }

  // Function to show logout confirmation dialog
  void _showLogoutConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Logout Confirmation'),
          content: Text('Are you sure you want to logout?'),
          actions: <Widget>[
            TextButton(
              child: Text('No'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
            TextButton(
              child: Text('Yes', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                _logout(); // Call the logout function
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteAccount() async {
    try {
      setState(() => _isLoading = true);

      String? token = await _secureStorage.read(key: 'jwt_token');
      String? email = await _secureStorage.read(key: 'user_email');

      if (token == null || email == null) {
        throw Exception('Required authentication data not found');
      }

      var request = http.Request(
        'POST',
        Uri.parse('https://www.backend.amddas.net/delete-account?email=$email'),
      );

      request.headers.addAll({
        'Authorization': 'Bearer $token',
      });

      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Account Deletion Scheduled'),
              content: Text(
                  'Your account is set for deletion within 48 hours. For questions, reach out to info@amddas.net. Log out?'),
              actions: <Widget>[
                TextButton(
                  child: Text('No'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text('Yes'),
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await _logout();
                  },
                ),
              ],
            );
          },
        );
      } else {
        String errorMessage = response.reasonPhrase ?? 'Unknown error occurred';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete account: $errorMessage'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred while deleting your account.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

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
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteAccount();
              },
            ),
          ],
        );
      },
    );
  }

  // // Function to launch the phone dialer
  // void _callUs() async {
  //   final Uri phoneUri = Uri(scheme: 'tel', path: '09632764963');
  //   if (await canLaunchUrl(phoneUri)) {
  //     await launchUrl(phoneUri);
  //   } else {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Could not launch the phone dialer')),
  //     );
  //   }
  // }

  // // Function to open email client
  // void _mailUs() async {
  //   final Uri emailUri = Uri(
  //     scheme: 'mailto',
  //     path: 'info@amddas.net',
  //     query: 'subject=Customer%20Inquiry',
  //   );
  //   if (await canLaunchUrl(emailUri)) {
  //     await launchUrl(emailUri);
  //   } else {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Could not launch the email app')),
  //     );
  //   }
  // }

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

  void _launchPrivacyPolicy() async {
    final Uri url = Uri.parse('https://www.amddas.net/privacy-policy');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      // Show error if URL can't be launched
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch Privacy Policy')),
      );
    }
  }

  void _handleNavigation(int index) {
    if (index == _currentIndex) return;

    if (index == 0) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation1, animation2) => MenuPage(),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Custom Header with Curved Shape and Gradient
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // User Info on the Left
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Hello Foodie',
                          style: TextStyle(
                            fontSize: 24,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          userEmail,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                        width: 50), // Adds space between the text and avatar
                  ],
                ),
              ),
            ),
          ),
          // Positioned CircleAvatar to show half-outside the header section
          // Positioned CircleAvatar with Outer Dark Green Border
          Positioned(
            top: 60, // Adjust to position the avatar halfway outside the header
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
              ),
            ),
          ),
          // Main content below the header
          Padding(
            padding: const EdgeInsets.only(top: 250.0),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              children: [
                // Section Title "My Account"
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: Text(
                    "My Account",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                UserInfoTile(
                  icon: Icons.person_outline,
                  title: 'Manage Profile',
                  onTap: () {
                    setState(() {
                      _isManageProfileExpanded = !_isManageProfileExpanded;
                    });
                  },
                ),
                // Show "Delete Account" if _isManageProfileExpanded is true
                if (_isManageProfileExpanded)
                  UserInfoTile(
                    icon: Icons.delete_forever,
                    title: 'Delete Account',
                    onTap: () => _showDeleteConfirmationDialog(context),
                    titleColor: Colors.red,
                  ),
                Divider(),

                SizedBox(height: 30),

                // Section Title "Others"
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: Text(
                    "Others",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                UserInfoTile(
                  icon: Icons.notifications_outlined,
                  title: 'Notification',
                  onTap: _showBookingInfo,
                ),
                Divider(),
                UserInfoTile(
                  icon: Icons.book,
                  title: 'Privacy Policy',
                  onTap: _launchPrivacyPolicy,
                ),
                Divider(),
                UserInfoTile(
                    icon: Icons.contact_page,
                    title: 'Contact-Us',
                    onTap: () {
                      setState(() {
                        _isManageProfileExpand = !_isManageProfileExpand;
                      });
                    }),
                if (_isManageProfileExpand)
                  UserInfoTile(
                    icon: Icons.phone_android_outlined,
                    title: 'Call Us - 09632764963 ',
                    // onTap: _callUs, // Launch phone dialer
                  ),
                if (_isManageProfileExpand)
                  UserInfoTile(
                    icon: Icons.mail,
                    title: 'Mail us - info@amddas.net',
                    // onTap: _mailUs, // Launch email app
                  ),

                Divider(),
                UserInfoTile(
                  icon: Icons.logout,
                  title: 'Logout',
                  onTap: _showLogoutConfirmationDialog,
                  titleColor: Colors.red,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Custom Clipper for Header
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
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class UserInfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;
  final Color? titleColor;

  UserInfoTile({
    required this.icon,
    required this.title,
    this.onTap,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: InkWell(
        onTap: onTap, // This should be set correctly to trigger the callback
        borderRadius:
            BorderRadius.circular(12), // Make InkWell match container shape
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon,
                  color: titleColor ?? Color.fromARGB(255, 35, 58, 9),
                  size: 24), // Icon color as per design
              SizedBox(width: 16), // Space between icon and text
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  color: titleColor ?? Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
