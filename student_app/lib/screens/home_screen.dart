import 'package:flutter/material.dart';
import 'package:flutter_carousel_widget/flutter_carousel_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/drive_service.dart';
import '../services/profile_service.dart';
import '../widgets/custom_drawer.dart';
import '../screens/DrivesDetailsScreen.dart'; // Import the DriveDetailsScreen (not provided)

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
    } catch (e) {
      // Silent error handling as per current code
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
      print('DEBUG: Upcoming drives: $_upcomingDrives');
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
      print('DEBUG: Error fetching placement data: $e');
    }
  }

  Widget _buildStayTunedMessage({bool isCarousel = false}) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: isCarousel ? 5.0 : 16.0, vertical: 16.0),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.indigo, Colors.blueAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.rocket_launch,
            color: Colors.white,
            size: 30,
          ),
          const SizedBox(width: 10),
          Flexible(
            child: AnimatedOpacity(
              opacity: 1.0,
              duration: const Duration(seconds: 1),
              child: const Text(
                'Stay Tuned! Exciting Drives Coming Soon!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      blurRadius: 4.0,
                      color: Colors.black45,
                      offset: Offset(2.0, 2.0),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCarousel() {
    final placements = _upcomingDrives.isNotEmpty ? _upcomingDrives : _ongoingDrives;
    return FlutterCarousel(
      options: CarouselOptions(
        height: 200.0,
        autoPlay: true,
        autoPlayInterval: const Duration(seconds: 3),
        enlargeCenterPage: true,
        viewportFraction: 0.9,
      ),
      items: placements.isNotEmpty
          ? placements.map((placement) {
              final companyName = (placement['company'] ?? 'unknown').toString().toLowerCase();
              print('DEBUG: Carousel placement - Company: ${placement['company']}, Banner: ${placement['bannerImage']}');
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
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CachedNetworkImage(
                            imageUrl: placement['bannerImage']?.isNotEmpty == true
                                ? placement['bannerImage']
                                : 'http://192.168.1.101:3000/uploads/placement_banners/$companyName.jpg',
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                            errorWidget: (context, url, error) {
                              return const Icon(Icons.error);
                            },
                            imageBuilder: (context, imageProvider) {
                              return Image(image: imageProvider, fit: BoxFit.cover);
                            },
                          ),
                          Positioned(
                            bottom: 10,
                            left: 10,
                            child: Text(
                              placement['company'] ?? 'Unknown Company',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                shadows: [
                                  Shadow(
                                    blurRadius: 4.0,
                                    color: Colors.black,
                                    offset: Offset(2.0, 2.0),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }).toList()
          : [_buildStayTunedMessage(isCarousel: true)],
    );
  }

  Widget _buildCompanyCard(Map<String, dynamic> company) {
    final companyName = (company['company'] ?? 'unknown').toString().toLowerCase();
    print('DEBUG: Company card - Company: ${company['company']}, Logo: ${company['logo']}');
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        leading: CachedNetworkImage(
          imageUrl: company['logo']?.isNotEmpty == true
              ? company['logo']
              : 'http://192.168.1.101:3000/uploads/logos/$companyName.png',
          width: 50,
          height: 50,
          placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
          errorWidget: (context, url, error) {
            return const Icon(Icons.business);
          },
          imageBuilder: (context, imageProvider) {
            return Image(image: imageProvider, width: 50, height: 50);
          },
        ),
        title: Text(
          company['company'] ?? 'Unknown Company',
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
          print('DEBUG: Tapped company: ${company['company']}');
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DriveDetailsScreen(drive: company),
            ),
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
            : _buildStayTunedMessage(),
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