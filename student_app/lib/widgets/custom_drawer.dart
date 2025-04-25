import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/auth_service.dart';

class CustomDrawer extends StatelessWidget {
  final String fullName;
  final String usn;

  const CustomDrawer({
    super.key,
    required this.fullName,
    required this.usn,
  });

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help'),
        content: const Text('For assistance, contact support at support@campusconnect.com or call +1-800-123-4567.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              print('DEBUG: Help dialog closed');
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
    print('DEBUG: Help dialog opened');
  }

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Colors.indigo,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CachedNetworkImage(
                  imageUrl: 'http://192.168.1.100:3000/uploads/profile_pics/$usn.jpg',
                  width: 60,
                  height: 60,
                  placeholder: (context, url) => const CircularProgressIndicator(),
                  errorWidget: (context, url, error) => const Icon(Icons.person, size: 60, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  fullName.isEmpty ? 'Student Name' : fullName,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  usn.isEmpty ? 'Unknown USN' : usn,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () {
              Navigator.pop(context);
              print('DEBUG: Drawer - Home tapped');
            },
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/profile');
              print('DEBUG: Drawer - Profile tapped');
            },
          ),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('Resume Builder'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/resume_builder');
              print('DEBUG: Drawer - Resume Builder tapped');
            },
          ),
          ListTile(
            leading: const Icon(Icons.question_answer),
            title: const Text('Question Banks'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/question_banks');
              print('DEBUG: Drawer - Question Banks tapped');
            },
          ),
          ListTile(
            leading: const Icon(Icons.live_tv),
            title: const Text('Livestream'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/livestream');
              print('DEBUG: Drawer - Livestream tapped');
            },
          ),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Notifications'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/notifications');
              print('DEBUG: Drawer - Notifications tapped');
            },
          ),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('Help'),
            onTap: () {
              Navigator.pop(context);
              _showHelpDialog(context);
              print('DEBUG: Drawer - Help tapped');
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () async {
              print('DEBUG: Drawer - Logout initiated');
              await authService.logout();
              print('DEBUG: Session cleared, navigating to LoginScreen');
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
    );
  }
}