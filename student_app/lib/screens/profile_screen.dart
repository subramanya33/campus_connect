import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../services/profile_service.dart';
import '../widgets/custom_drawer.dart';
//import './edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profile;
  bool _isLoading = true;
  String _errorMessage = '';
  String _fullName = '';
  String _usn = '';
  double _opacity = 0.0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    print('DEBUG: ProfileScreen initialized');
    _fetchProfile();
    // Trigger fade-in animation
    Future.delayed(const Duration(milliseconds: 100), () {
      setState(() {
        _opacity = 1.0;
      });
    });
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
        _fullName = profile['fullName'] ?? '';
        _usn = profile['usn'] ?? '';
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
      key: _scaffoldKey,
      drawer: CustomDrawer(fullName: _fullName, usn: _usn),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.indigo))
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.red, fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : CustomScrollView(
                  slivers: [
                    // Profile Header
                    SliverAppBar(
                      expandedHeight: 250.0,
                      floating: false,
                      pinned: true,
                      backgroundColor: Colors.indigo,
                      flexibleSpace: FlexibleSpaceBar(
                        background: Stack(
                          fit: StackFit.expand,
                          children: [
                            Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.indigo, Colors.blueAccent],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircleAvatar(
                                  radius: 60,
                                  backgroundColor: Colors.white,
                                  child: ClipOval(
                                    child: CachedNetworkImage(
                                      imageUrl:
                                          'http://192.168.1.100:3000/uploads/profile_pics/${_profile!['usn']}.jpg',
                                      width: 110,
                                      height: 110,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => const CircularProgressIndicator(),
                                      errorWidget: (context, url, error) =>
                                          const Icon(Icons.person, size: 60, color: Colors.grey),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _profile!['fullName'] ?? 'Unknown',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  _profile!['usn'] ?? 'Unknown',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      leading: IconButton(
                        icon: const Icon(Icons.menu, color: Colors.white, size: 28),
                        onPressed: () {
                          _scaffoldKey.currentState?.openDrawer();
                          print('DEBUG: Hamburger menu tapped');
                        },
                      ),
                    ),
                    // Profile Details
                    SliverToBoxAdapter(
                      child: AnimatedOpacity(
                        opacity: _opacity,
                        duration: const Duration(milliseconds: 500),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Personal Info
                              Card(
                                elevation: 2,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                child: ExpansionTile(
                                  title: const Text(
                                    'Personal Information',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.indigo,
                                    ),
                                  ),
                                  leading: const Icon(Icons.person, color: Colors.indigo),
                                  childrenPadding: const EdgeInsets.all(16.0),
                                  children: [
                                    _buildInfoRow('Student ID', _profile!['studentId'] ?? 'Unknown'),
                                    _buildInfoRow('Email', _profile!['email'] ?? 'Unknown'),
                                    _buildInfoRow('Phone', _profile!['phone'] ?? 'Unknown'),
                                    _buildInfoRow('Address', _profile!['address'] ?? 'Unknown'),
                                    _buildInfoRow('DOB', _formatDate(_profile!['dob'])),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Academic Details
                              Card(
                                elevation: 2,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                child: ExpansionTile(
                                  title: const Text(
                                    'Academic Details',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.indigo,
                                    ),
                                  ),
                                  leading: const Icon(Icons.school, color: Colors.indigo),
                                  childrenPadding: const EdgeInsets.all(16.0),
                                  children: [
                                    _buildInfoRow(
                                        '10th Percentage', '${_profile!['tenthPercentage']?.toString() ?? 'N/A'}%'),
                                    _buildInfoRow(
                                        '12th Percentage', '${_profile!['twelfthPercentage']?.toString() ?? 'N/A'}%'),
                                    _buildInfoRow(
                                        'Diploma Percentage', '${_profile!['diplomaPercentage']?.toString() ?? 'N/A'}%'),
                                    _buildInfoRow(
                                        'Current CGPA', _profile!['currentCgpa']?.toString() ?? 'N/A'),
                                    _buildInfoRow(
                                        'No. of Backlogs', _profile!['noOfBacklogs']?.toString() ?? 'N/A'),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Placement Status
                              Card(
                                elevation: 2,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                child: ExpansionTile(
                                  title: const Text(
                                    'Placement Status',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.indigo,
                                    ),
                                  ),
                                  leading: const Icon(Icons.work, color: Colors.indigo),
                                  childrenPadding: const EdgeInsets.all(16.0),
                                  children: [
                                    _buildInfoRow(
                                        'Placed', _profile!['placedStatus'] == true ? 'Yes' : 'No'),
                                    _buildInfoRow(
                                        'Applied Placements', _profile!['placements']?.length.toString() ?? '0'),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              // Edit Profile Button
                              Center(
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                   
                                  
                                   
                                  },
                                  icon: const Icon(Icons.edit, size: 20),
                                  label: const Text('Edit Profile'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.indigo,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    elevation: 2,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}