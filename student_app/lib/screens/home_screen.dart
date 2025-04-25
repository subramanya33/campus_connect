import 'package:flutter/material.dart';
import 'package:flutter_carousel_widget/flutter_carousel_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/drive_service.dart';
import '../services/profile_service.dart';
import '../widgets/custom_drawer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _featuredPlacements = [];
  List<Map<String, dynamic>> _ongoingDrives = [];
  List<Map<String, dynamic>> _upcomingDrives = [];
  List<Map<String, dynamic>> _completedDrives = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String _fullName = '';
  String _usn = '';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    print('DEBUG: HomeScreen initialized');
    _fetchPlacementData();
    _fetchStudentProfile();
  }

  Future<void> _fetchStudentProfile() async {
    try {
      final profile = await ProfileService.fetchStudentProfile();
      setState(() {
        _fullName = profile['fullName'] ?? '';
        _usn = profile['usn'] ?? '';
      });
      print('DEBUG: Student profile loaded - Full Name: $_fullName, USN: $_usn');
    } catch (e) {
      print('DEBUG: Error fetching student profile: $e');
    }
  }

  Future<void> _fetchPlacementData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final results = await Future.wait([
        DrivesService.fetchFeaturedPlacements(),
        DrivesService.fetchOngoingDrives(),
        DrivesService.fetchUpcomingDrives(),
        DrivesService.fetchCompletedDrives(),
      ]);

      setState(() {
        _featuredPlacements = results[0];
        _ongoingDrives = results[1];
        _upcomingDrives = results[2];
        _completedDrives = results[3];
        _isLoading = false;
      });
      print('DEBUG: Placement data loaded - Featured: ${_featuredPlacements.length}, Ongoing: ${_ongoingDrives.length}, Upcoming: ${_upcomingDrives.length}, Completed: ${_completedDrives.length}');
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
      print('DEBUG: Error fetching placement data: $e');
    }
  }

  Widget _buildCarousel() {
    return FlutterCarousel(
      options: CarouselOptions(
        height: 200.0,
        autoPlay: true,
        autoPlayInterval: const Duration(seconds: 3),
        enlargeCenterPage: true,
        viewportFraction: 0.9,
      ),
      items: _featuredPlacements.isNotEmpty
          ? _featuredPlacements.map((placement) {
              return Builder(
                builder: (BuildContext context) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 5.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: placement['bannerImage'] ?? 'http://192.168.1.100:3000/uploads/placement_banners/default.jpg',
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                        errorWidget: (context, url, error) => const Icon(Icons.error),
                      ),
                    ),
                  );
                },
              );
            }).toList()
          : [
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 5.0),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(child: Text('No new placements')),
              ),
            ],
    );
  }

  Widget _buildCompanyCard(Map<String, dynamic> company) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        leading: CachedNetworkImage(
          imageUrl: company['logo'] ?? 'http://192.168.1.100:3000/uploads/logos/default.png',
          width: 50,
          height: 50,
          placeholder: (context, url) => const CircularProgressIndicator(),
          errorWidget: (context, url, error) => const Icon(Icons.business),
        ),
        title: Text(
          company['name'] ?? 'Unknown Company',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text('Drive Date: ${company['driveDate'] ?? 'TBD'}'),
        trailing: Chip(
          label: Text(company['status'] ?? 'Unknown'),
          backgroundColor: company['status'] == 'Ongoing'
              ? Colors.green[100]
              : company['status'] == 'Upcoming'
                  ? Colors.blue[100]
                  : Colors.grey[300],
        ),
        onTap: () {
          print('DEBUG: Tapped company: ${company['name']}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Details for ${company['name']} coming soon!')),
          );
        },
      ),
    );
  }

  Widget _buildDriveSection(String title, List<Map<String, dynamic>> drives) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.indigo,
            ),
          ),
        ),
        drives.isNotEmpty
            ? ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: drives.length,
                itemBuilder: (context, index) => _buildCompanyCard(drives[index]),
              )
            : const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('No drives available'),
              ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: Colors.indigo,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
            print('DEBUG: Hamburger menu tapped');
          },
        ),
        title: const Text('Campus Connect', style: TextStyle(color: Colors.white)),
      ),
      drawer: CustomDrawer(fullName: _fullName, usn: _usn),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchPlacementData,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildCarousel(),
                    if (_errorMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          _errorMessage,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    _buildDriveSection('Ongoing Drives', _ongoingDrives),
                    _buildDriveSection('Upcoming Drives', _upcomingDrives),
                    _buildDriveSection('Completed Drives', _completedDrives),
                  ],
                ),
              ),
            ),
    );
  }
}