// home_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'appnavigator.dart'; // Import AppNavigator

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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

  Widget _buildHomeCard({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    required Color startColor,
    required Color endColor,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 120,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [startColor, endColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(2, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 20),
            Icon(
              icon,
              size: 40,
              color: Colors.white,
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('images/fodwal.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                      ),
                      SizedBox(width: 50),
                    ],
                  ),
                ),
              ),
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
                ),
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(top: 20, bottom: 5),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 30),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: const [
                          Text(
                            'HOME',
                            style: TextStyle(
                              fontSize: 34,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 60),
                    _buildHomeCard(
                      title: 'Token Booking',
                      icon: Icons.calendar_today,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AppNavigator(initialIndex: 0),
                          ),
                        );
                      },
                      startColor: const Color.fromARGB(232, 85, 138, 0),
                      endColor: const Color.fromARGB(218, 107, 194, 7),
                    ),
                    const SizedBox(height: 40),
                    _buildHomeCard(
                      title: 'Your Tokens',
                      icon: Icons.confirmation_num_outlined,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AppNavigator(initialIndex: 1),
                          ),
                        );
                      },
                      startColor: const Color.fromARGB(232, 85, 138, 0),
                      endColor: const Color.fromARGB(218, 107, 194, 7),
                    ),
                    const SizedBox(height: 40),
                    _buildHomeCard(
                      title: 'Manage Profile',
                      icon: Icons.person_outline,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AppNavigator(initialIndex: 2),
                          ),
                        );
                      },
                      startColor: const Color.fromARGB(232, 85, 138, 0),
                      endColor: const Color.fromARGB(218, 107, 194, 7),
                    ),
                    const SizedBox(height: 110),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child: Text(
                        'Fuel Your Workday with Love and Great Food ❤️',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          color: const Color.fromARGB(172, 0, 0, 0),
                          fontWeight: FontWeight.w500,
                          shadows: [
                            Shadow(
                              offset: Offset(1, 1),
                              blurRadius: 2,
                              color: Colors.black45,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
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
