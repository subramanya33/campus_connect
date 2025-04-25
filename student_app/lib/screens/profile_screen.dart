import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../services/profile_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  Map<String, dynamic>? _profile;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    print('DEBUG: ProfileScreen initialized');
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final profile = await ProfileService.fetchStudentProfile();
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
      print('DEBUG: Profile loaded: ${profile['fullName']}');
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
      print('DEBUG: Error fetching profile: $e');
    }
  }

  String _formatDate(String? date) {
    if (date == null) return 'N/A';
    try {
      final parsedDate = DateTime.parse(date);
      return DateFormat('dd MMM yyyy').format(parsedDate);
    } catch (e) {
      return 'N/A';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.indigo,
        title: const Text('Profile', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
            print('DEBUG: Back button tapped');
          },
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.red)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Personal Info Card
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              CachedNetworkImage(
                                imageUrl: 'http://192.168.1.100:3000/uploads/profile_pics/${_profile!['usn']}.jpg',
                                width: 100,
                                height: 100,
                                placeholder: (context, url) => const CircularProgressIndicator(),
                                errorWidget: (context, url, error) => const Icon(Icons.person, size: 100, color: Colors.grey),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _profile!['fullName'] ?? 'Unknown',
                                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.indigo),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'USN: ${_profile!['usn'] ?? 'Unknown'}',
                                style: const TextStyle(fontSize: 16, color: Colors.grey),
                              ),
                              Text(
                                'Student ID: ${_profile!['studentId'] ?? 'Unknown'}',
                                style: const TextStyle(fontSize: 16, color: Colors.grey),
                              ),
                              Text(
                                'Email: ${_profile!['email'] ?? 'Unknown'}',
                                style: const TextStyle(fontSize: 16, color: Colors.grey),
                              ),
                              Text(
                                'Phone: ${_profile!['phone'] ?? 'Unknown'}',
                                style: const TextStyle(fontSize: 16, color: Colors.grey),
                              ),
                              Text(
                                'Address: ${_profile!['address'] ?? 'Unknown'}',
                                style: const TextStyle(fontSize: 16, color: Colors.grey),
                              ),
                              Text(
                                'DOB: ${_formatDate(_profile!['dob'])}',
                                style: const TextStyle(fontSize: 16, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Academic Details Card
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Academic Details',
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '10th Percentage: ${_profile!['tenthPercentage']?.toString() ?? 'N/A'}%',
                                style: const TextStyle(fontSize: 16, color: Colors.grey),
                              ),
                              Text(
                                '12th Percentage: ${_profile!['twelfthPercentage']?.toString() ?? 'N/A'}%',
                                style: const TextStyle(fontSize: 16, color: Colors.grey),
                              ),
                              Text(
                                'Diploma Percentage: ${_profile!['diplomaPercentage']?.toString() ?? 'N/A'}%',
                                style: const TextStyle(fontSize: 16, color: Colors.grey),
                              ),
                              Text(
                                'Current CGPA: ${_profile!['currentCgpa']?.toString() ?? 'N/A'}',
                                style: const TextStyle(fontSize: 16, color: Colors.grey),
                              ),
                              Text(
                                'No. of Backlogs: ${_profile!['noOfBacklogs']?.toString() ?? 'N/A'}',
                                style: const TextStyle(fontSize: 16, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Placement Status Card
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Placement Status',
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Placed: ${_profile!['placedStatus'] == true ? 'Yes' : 'No'}',
                                style: const TextStyle(fontSize: 16, color: Colors.grey),
                              ),
                              Text(
                                'Applied Placements: ${_profile!['placements']?.length ?? 0}',
                                style: const TextStyle(fontSize: 16, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Edit profile coming soon!')),
                          );
                          print('DEBUG: Edit profile tapped');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Edit Profile'),
                      ),
                    ],
                  ),
                ),
    );
  }
}