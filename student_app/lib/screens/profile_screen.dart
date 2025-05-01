import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../services/profile_service.dart';
import '../services/resume_service.dart';
import '../widgets/custom_drawer.dart';
import 'package:file_picker/file_picker.dart';
import 'package:crypto/crypto.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>> _resumes = [];
  bool _isLoading = true;
  bool _isResumeLoading = true;
  String _errorMessage = '';
  String _resumeErrorMessage = '';
  String _fullName = '';
  String _usn = '';
  double _opacity = 0.0;
  String? _selectedResume;
  String? _pdfPath;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    print('DEBUG: ProfileScreen initialized');
    _fetchProfile();
    _fetchResumes();
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

  Future<void> _fetchResumes() async {
    setState(() {
      _isResumeLoading = true;
      _resumeErrorMessage = '';
    });

    try {
      final resumes = await ProfileService.fetchResumes();
      setState(() {
        _resumes = resumes.where((resume) => resume['filePath'] != null).toList();
        _isResumeLoading = false;
        if (_resumes.isNotEmpty) {
          _selectedResume = _resumes[0]['filePath']; // Ensure latest resume is selected
          _pdfPath = null;
          print('DEBUG: Selected resume: $_selectedResume');
        } else {
          _selectedResume = null;
        }
      });
      print('DEBUG: Resumes loaded: ${_resumes.length}');
    } catch (e) {
      setState(() {
        _resumeErrorMessage = e.toString().replaceFirst('Exception: ', '');
        _isResumeLoading = false;
      });
      print('DEBUG: Error fetching resumes: $e');
    }
  }

  Future<void> _downloadAndPreviewPDF(String url) async {
    try {
      final dio = Dio();
      dio.options.headers['Cache-Control'] = 'no-cache, no-store, must-revalidate';
      dio.options.headers['Pragma'] = 'no-cache';
      dio.options.headers['Expires'] = '0';

      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/resume_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final cacheBustUrl = '${dotenv.env['API_URL']}$url?ts=${DateTime.now().millisecondsSinceEpoch}&nocache=${DateTime.now().millisecondsSinceEpoch}';
      print('DEBUG: Downloading PDF from: $cacheBustUrl');

      // Clear any existing file at the path
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        print('DEBUG: Cleared existing file at $path');
      }

      // Clear previous pdfPath if it exists
      if (_pdfPath != null && await File(_pdfPath!).exists()) {
        await File(_pdfPath!).delete();
        print('DEBUG: Cleared previous pdfPath: $_pdfPath');
      }

      await dio.download(cacheBustUrl, path);
      print('DEBUG: PDF downloaded to $path');

      // Verify downloaded file
      final bytes = await file.readAsBytes();
      final fileHash = md5.convert(bytes).toString();
      print('DEBUG: Downloaded file hash: $fileHash');

      setState(() {
        _pdfPath = path;
      });

      if (_pdfPath != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PDFPreviewScreen(
              pdfPath: _pdfPath!,
              key: ValueKey(_pdfPath),
            ),
          ),
        );
      }
    } catch (e) {
      print('DEBUG: Error downloading PDF: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load PDF: $e')),
      );
    }
  }

  Future<void> _uploadResume() async {
    try {
      await FilePicker.platform.clearTemporaryFiles().catchError((e) {
        print('DEBUG: clearTemporaryFiles not implemented: $e');
      });

      FilePickerResult? result;
      int attempts = 0;
      const maxAttempts = 3;
      while (result == null && attempts < maxAttempts) {
        print('DEBUG: FilePicker attempt ${attempts + 1}');
        result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf'],
          allowMultiple: false,
          withData: true,
          dialogTitle: 'Select a PDF Resume',
        );
        attempts++;
        if (result == null) {
          print('DEBUG: FilePicker returned null, retrying...');
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        if (!file.path.toLowerCase().endsWith('.pdf')) {
          throw Exception('Please select a PDF file');
        }

        final fileSize = await file.length();
        print('DEBUG: Selected file: ${file.path}, Size: ${fileSize / (1024 * 1024)} MB');

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Uploading resume...'),
              ],
            ),
          ),
        );

        try {
          await ResumeService.uploadCustomResume(
            usn: _usn,
            pdfFile: file,
          );
          Navigator.pop(context);
          await _fetchResumes();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Resume uploaded successfully')),
          );
        } catch (e) {
          Navigator.pop(context);
          throw e;
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No file selected after $maxAttempts attempts')),
        );
      }
    } catch (e) {
      setState(() {
        _isResumeLoading = false;
      });
      print('DEBUG: Error uploading resume: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  String _formatDate(String? date) {
    if (date == null) return 'N/A';
    try {
      final parsedDate = DateTime.parse(date);
      return DateFormat('dd MMM yyyy').format(parsedDate.toLocal());
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
                                          '${dotenv.env['API_URL']}/uploads/profile_pics/${_profile!['usn']}.jpg',
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
                    SliverToBoxAdapter(
                      child: AnimatedOpacity(
                        opacity: _opacity,
                        duration: const Duration(milliseconds: 500),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
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
                              const SizedBox(height: 16),
                              Card(
                                elevation: 2,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                child: ExpansionTile(
                                  title: const Text(
                                    'Resumes',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.indigo,
                                    ),
                                  ),
                                  leading: const Icon(Icons.description, color: Colors.indigo),
                                  childrenPadding: const EdgeInsets.all(16.0),
                                  children: [
                                    _isResumeLoading
                                        ? const Center(child: CircularProgressIndicator())
                                        : _resumeErrorMessage.isNotEmpty
                                            ? Text(
                                                _resumeErrorMessage,
                                                style: const TextStyle(color: Colors.red),
                                              )
                                            : _resumes.isEmpty
                                                ? const Text('No resumes found')
                                                : Column(
                                                    children: [
                                                      DropdownButton<String>(
                                                        value: _selectedResume,
                                                        hint: const Text('Select a resume'),
                                                        isExpanded: true,
                                                        items: _resumes.map((resume) {
                                                          final fileName = resume['filePath']?.split('/').last ?? 'Untitled Resume';
                                                          return DropdownMenuItem<String>(
                                                            value: resume['filePath'],
                                                            child: Text('$fileName (${resume['format']})'),
                                                          );
                                                        }).toList(),
                                                        onChanged: (value) {
                                                          setState(() {
                                                            _selectedResume = value;
                                                            _pdfPath = null;
                                                            print('DEBUG: Dropdown selected: $value');
                                                          });
                                                        },
                                                        key: ValueKey(_resumes.length), // Force dropdown refresh
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Row(
                                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                        children: [
                                                          ElevatedButton(
                                                            onPressed: _selectedResume != null
                                                                ? () => _downloadAndPreviewPDF(_selectedResume!)
                                                                : null,
                                                            style: ElevatedButton.styleFrom(
                                                              backgroundColor: Colors.indigo,
                                                              foregroundColor: Colors.white,
                                                            ),
                                                            child: const Text('Preview PDF'),
                                                          ),
                                                          ElevatedButton(
                                                            onPressed: _uploadResume,
                                                            style: ElevatedButton.styleFrom(
                                                              backgroundColor: Colors.green,
                                                              foregroundColor: Colors.white,
                                                            ),
                                                            child: const Text('Upload Resume'),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              Center(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    // Navigate to edit profile screen
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

class PDFPreviewScreen extends StatelessWidget {
  final String pdfPath;
  final Key key;

  const PDFPreviewScreen({required this.pdfPath, required this.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resume Preview'),
        backgroundColor: Colors.indigo,
      ),
      body: PDFView(
        key: key,
        filePath: pdfPath,
        enableSwipe: true,
        swipeHorizontal: true,
        autoSpacing: true,
        pageFling: true,
        onError: (error) {
          print('DEBUG: PDFView error: $error');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading PDF: $error')),
          );
        },
      ),
    );
  }
}