import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/drive_service.dart';

class DriveDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> drive;

  const DriveDetailsScreen({super.key, required this.drive});

  @override
  _DriveDetailsScreenState createState() => _DriveDetailsScreenState();
}

class _DriveDetailsScreenState extends State<DriveDetailsScreen> {
  bool _isLoading = false;
  String _errorMessage = '';
  Map<String, dynamic>? _roundStatus; // For ongoing drives
  bool _hasApplied = false; // For upcoming drives
  List<dynamic>? _shortlistResults; // For completed drives

  @override
  void initState() {
    super.initState();
    _fetchDriveDetails();
  }

  Future<void> _fetchDriveDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final status = widget.drive['status'] ?? 'Unknown';
      if (status == 'Ongoing') {
        _roundStatus = await DrivesService.fetchRoundStatus(widget.drive['_id']);
      } else if (status == 'Upcoming') {
        _hasApplied = await DrivesService.checkApplicationStatus(widget.drive['_id']);
      } else if (status == 'Completed') {
        _shortlistResults = await DrivesService.fetchShortlistResults(widget.drive['_id']);
      }
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _applyForDrive() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      await DrivesService.applyForDrive(widget.drive['_id']);
      setState(() {
        _hasApplied = true;
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Successfully applied for the drive!')),
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final drive = widget.drive;
    final companyName = (drive['company'] ?? 'Unknown').toString().toLowerCase();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.indigo,
        title: Text(drive['company'] ?? 'Company Details', style: const TextStyle(color: Colors.white)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Company Banner
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: drive['bannerImage']?.isNotEmpty == true
                          ? drive['bannerImage']
                          : 'http://192.168.1.101:3000/uploads/placement_banners/$companyName.jpg',
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                      errorWidget: (context, url, error) => const Icon(Icons.error),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Company Info
                  Text(
                    drive['company'] ?? 'Unknown Company',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.indigo),
                  ),
                  const SizedBox(height: 8),
                  Text('Sector: ${drive['sector'] ?? 'N/A'}'),
                  Text('Location: ${drive['location'] ?? 'N/A'}'),
                  Text('Job Profile: ${drive['jobProfile'] ?? 'N/A'}'),
                  Text('Package: ${drive['package'] ?? 'N/A'} LPA'),
                  Text('Required CGPA: ${drive['requiredCgpa'] ?? 'N/A'}'),
                  Text('Skills: ${(drive['skills'] as List<dynamic>?)?.join(', ') ?? 'N/A'}'),
                  Text('Drive Date: ${drive['driveDate'] ?? 'TBD'}'),
                  const SizedBox(height: 16),
                  // Status-specific Content
                  if (_errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text(_errorMessage, style: const TextStyle(color: Colors.red)),
                    ),
                  if (drive['status'] == 'Ongoing' && _roundStatus != null) ...[
                    const Text(
                      'Round Status',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo),
                    ),
                    const SizedBox(height: 8),
                    Text('Current Round: ${_roundStatus!['currentRound'] ?? 'N/A'}'),
                    Text('Shortlist Status: ${_roundStatus!['isShortlisted'] ? 'Shortlisted' : 'Not Shortlisted'}'),
                  ],
                  if (drive['status'] == 'Upcoming') ...[
                    const Text(
                      'Application Status',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo),
                    ),
                    const SizedBox(height: 8),
                    _hasApplied
                        ? const Text('You have already applied for this drive.', style: TextStyle(color: Colors.green))
                        : ElevatedButton(
                            onPressed: _applyForDrive,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Apply Now'),
                          ),
                  ],
                  if (drive['status'] == 'Completed' && _shortlistResults != null) ...[
                    const Text(
                      'Shortlist Results',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo),
                    ),
                    const SizedBox(height: 8),
                    _shortlistResults!.isNotEmpty
                        ? ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _shortlistResults!.length,
                            itemBuilder: (context, index) {
                              final student = _shortlistResults![index];
                              return ListTile(
                                title: Text(student['fullName'] ?? 'Unknown Student'),
                                subtitle: Text('USN: ${student['usn'] ?? 'N/A'}'),
                              );
                            },
                          )
                        : const Text('No students shortlisted for this drive.'),
                  ],
                ],
              ),
            ),
    );
  }
}