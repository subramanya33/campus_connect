import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';
import '../services/profile_service.dart';
import '../services/resume_service.dart';
import '../services/session_service.dart';
import '../widgets/custom_drawer.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_file/open_file.dart';

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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final SessionService _sessionService = SessionService();

  @override
  void initState() {
    super.initState();
    print('DEBUG: ProfileScreen initialized');
    _fetchProfile();
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
        _fullName = profile['fullName'] ?? '${profile['firstName'] ?? ''} ${profile['lastName'] ?? ''}'.trim();
        _usn = profile['usn']?.toString() ?? '';
        _isLoading = false;
      });
      print('DEBUG: Profile loaded: $_fullName');
      await _fetchResumes();
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
      final resumes = await ResumeService.fetchResumes();
      print('DEBUG: Raw API response: $resumes');
      setState(() {
        _resumes = resumes.toList()
          ..sort((a, b) => DateTime.parse(b['updatedAt']).compareTo(DateTime.parse(a['updatedAt'])));
        _isResumeLoading = false;
        if (_resumes.isNotEmpty) {
          _selectedResume = _resumes.firstWhere(
            (r) => r['isActive'] == true,
            orElse: () => _resumes[0],
          )['filePath'] ?? _resumes[0]['_id'];
          print('DEBUG: Selected resume: $_selectedResume');
        } else {
          _selectedResume = null;
        }
        print('DEBUG: Resumes loaded: ${_resumes.length}, Items: ${_resumes.map((r) => r['originalFileName'] ?? r['filePath']?.split('/').last ?? 'Resume_${r['_id']}').toList()}');
      });
    } catch (e) {
      setState(() {
        _resumeErrorMessage = e.toString().replaceFirst('Exception: ', '');
        _isResumeLoading = false;
      });
      print('DEBUG: Error fetching resumes: $e');
    }
  }

  Future<void> _downloadAndPreviewPDF(String filePath, String fileName) async {
    try {
      final dio = Dio();
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/$fileName');

      final url = '${dotenv.env['API_URL']}$filePath';
      print('DEBUG: Downloading PDF from: $url');

      final session = await _sessionService.getSession();
      final token = session['token'];
      if (token == null) {
        throw Exception('Not logged in');
      }

      await dio.download(
        url,
        tempFile.path,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          validateStatus: (status) => status != null && status < 500,
        ),
        onReceiveProgress: (received, total) {
          if (total != -1) {
            print('DEBUG: Download progress: ${(received / total * 100).toStringAsFixed(0)}%');
          }
        },
      );

      if (!(await tempFile.exists())) {
        throw Exception('Downloaded file not found');
      }

      print('DEBUG: Opening PDF: ${tempFile.path}');
      final result = await OpenFile.open(tempFile.path);
      if (result.type != ResultType.done) {
        throw Exception('Failed to open PDF: ${result.message}');
      }
    } catch (e) {
      print('DEBUG: Error downloading/previewing PDF: $e');
      String errorMessage = 'Failed to preview resume';
      if (e is DioException && e.response?.statusCode == 404) {
        errorMessage = 'Resume file not found on server';
      } else if (e.toString().contains('Not logged in')) {
        errorMessage = 'Session expired. Please log in again.';
      }
      _showStyledSnackBar(
        context,
        message: errorMessage,
        isError: true,
      );
    }
  }

  Future<void> _uploadResume() async {
    try {
      print('DEBUG: Current resume count: ${_resumes.length}');
      if (_resumes.length >= 3) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Resume Limit Reached'),
            content: const Text('You have reached the limit of 3 resumes. Please delete an existing resume to upload a new one.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.indigo,
                  shape: const StadiumBorder(),
                ),
              ),
            ],
          ),
        );
        return;
      }

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

      if (result != null && result.files.single.path != null && result.files.single.name != null) {
        final file = File(result.files.single.path!);
        final pickedFileName = result.files.single.name;
        if (!pickedFileName.toLowerCase().endsWith('.pdf')) {
          throw Exception('Please select a PDF file');
        }

        final fileSize = await file.length();
        if (fileSize > 7.5 * 1024 * 1024) {
          throw Exception('File size exceeds 7.5MB limit');
        }
        print('DEBUG: Selected file: ${file.path}, Size: ${fileSize / (1024 * 1024)} MB');

        final TextEditingController nameController = TextEditingController(
          text: _fullName.isNotEmpty ? '${_fullName.replaceAll(' ', '_')}_Resume' : pickedFileName.replaceAll('.pdf', ''),
        );
        bool? confirmed;
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Resume Name'),
            content: TextFormField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Enter resume name (e.g., Subramanya_Poojary_Resume)',
                hintText: 'Leave blank for default',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.indigo,
                  shape: const StadiumBorder(),
                ),
              ),
              TextButton(
                onPressed: () {
                  confirmed = true;
                  Navigator.pop(context);
                },
                child: const Text('Confirm'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.indigo,
                  shape: const StadiumBorder(),
                ),
              ),
            ],
          ),
        );

        if (confirmed != true) {
          nameController.dispose();
          return;
        }

        final resumeName = nameController.text.trim();
        nameController.dispose();
        if (resumeName.isEmpty) {
          throw Exception('Resume name cannot be empty');
        }

        final originalFileName = resumeName.endsWith('.pdf')
            ? resumeName
            : '$resumeName.pdf';
        print('DEBUG: Original filename: $originalFileName');

        bool? confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Upload Resume'),
            content: Text('Upload $originalFileName?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.indigo,
                  shape: const StadiumBorder(),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Upload'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.indigo,
                  shape: const StadiumBorder(),
                ),
              ),
            ],
          ),
        );
        if (confirm != true) return;

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
          final bytes = await file.readAsBytes();
          final pdfData = 'data:application/pdf;base64,${base64Encode(bytes)}';
          print('DEBUG: pdfData length: ${pdfData.length}');
          final response = await ResumeService.uploadCustomResume(
            usn: _usn,
            pdfData: pdfData,
            originalFileName: originalFileName,
          );
          Navigator.pop(context);

          await ResumeService.setActiveResume(response['resume']['_id']);
          await _fetchResumes();
          _showStyledSnackBar(
            context,
            message: 'Resume uploaded and set as active: $originalFileName',
            isError: false,
          );
        } catch (e) {
          Navigator.pop(context);
          print('DEBUG: Upload error: $e');
          _showStyledSnackBar(
            context,
            message: e.toString().contains('Resume limit reached')
                ? 'Resume limit reached (3). Please delete an existing resume.'
                : e.toString().contains('This resume content has already been uploaded')
                    ? 'This resume has already been uploaded. Please upload a different file.'
                    : 'Failed to upload resume: ${e.toString().replaceFirst('Exception: ', '')}',
            isError: true,
          );
        }
      } else {
        _showStyledSnackBar(
          context,
          message: 'No file selected after $maxAttempts attempts',
          isError: true,
        );
      }
    } catch (e) {
      setState(() {
        _isResumeLoading = false;
      });
      print('DEBUG: Error uploading resume: $e');
      _showStyledSnackBar(
        context,
        message: 'Error uploading resume: ${e.toString().replaceFirst('Exception: ', '')}',
        isError: true,
      );
    }
  }

  Future<void> _deleteResume(String id) async {
    try {
      final resume = _resumes.firstWhere((r) => r['_id'] == id);
      final fileName = resume['originalFileName'] ?? resume['filePath']?.split('/').last ?? 'Resume_${resume['_id']}';
      bool? confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Resume'),
          content: Text('Are you sure you want to delete $fileName?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.indigo,
                shape: const StadiumBorder(),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
                shape: const StadiumBorder(),
              ),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Deleting resume...'),
            ],
          ),
        ),
      );

      await ResumeService.deleteResume(id);
      Navigator.pop(context);
      await _fetchResumes();
      _showStyledSnackBar(
        context,
        message: 'Resume deleted: $fileName',
        isError: false,
      );
    } catch (e) {
      Navigator.pop(context);
      print('DEBUG: Error deleting resume: $e');
      _showStyledSnackBar(
        context,
        message: 'Failed to delete resume: $e',
        isError: true,
      );
    }
  }

  void _showStyledSnackBar(BuildContext context, {required String message, required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isError
                  ? [Colors.redAccent, Colors.red]
                  : [Colors.green, Colors.teal],
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
            children: [
              Icon(
                isError ? Icons.error : Icons.check_circle,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.transparent,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 8,
        action: isError
            ? SnackBarAction(
                label: 'Retry',
                textColor: Colors.yellowAccent,
                onPressed: () => _uploadResume(),
              )
            : null,
      ),
    );
  }

  String _formatDate(String? date) {
    if (date == null) return 'N/A';
    try {
      final parsedDate = DateTime.parse(date);
      return DateFormat('dd MMM yyyy HH:mm').format(parsedDate.toLocal());
    } catch (e) {
      return 'N/A';
    }
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
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                          shape: const StadiumBorder(),
                          elevation: 4,
                          shadowColor: Colors.indigo.withOpacity(0.5),
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
                                          '${dotenv.env['API_URL']}${_profile?['profilePic'] ?? '/uploads/profile_pics/${_profile?['usn'] ?? 'unknown'}.jpg'}',
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
                                  _fullName,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  _profile?['usn']?.toString() ?? 'Unknown',
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
                                    'Manage Resumes',
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
                                            : Column(
                                                children: [
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      ElevatedButton.icon(
                                                        onPressed: _uploadResume,
                                                        icon: const Icon(Icons.cloud_upload),
                                                        label: const Text('Upload New Resume'),
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor: Colors.green,
                                                          foregroundColor: Colors.white,
                                                          padding: const EdgeInsets.symmetric(
                                                              vertical: 12, horizontal: 24),
                                                          shape: const StadiumBorder(),
                                                          elevation: 4,
                                                          shadowColor: Colors.green.withOpacity(0.5),
                                                        ),
                                                      ),
                                                      IconButton(
                                                        icon: const Icon(Icons.refresh, color: Colors.indigo),
                                                        onPressed: _fetchResumes,
                                                        tooltip: 'Refresh Resumes',
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 12),
                                                  _resumes.isEmpty
                                                      ? const Text('No resumes found. Upload a resume to get started.')
                                                      : Column(
                                                          children: [
                                                            DropdownButton<String>(
                                                              value: _selectedResume,
                                                              hint: const Text('Select a resume'),
                                                              isExpanded: true,
                                                              items: _resumes.map((resume) {
                                                                final fileName = resume['originalFileName'] ??
                                                                    resume['filePath']?.split('/').last ??
                                                                    'Resume_${resume['_id']}';
                                                                final updatedAt = _formatDate(resume['updatedAt']);
                                                                final isActive = resume['isActive'] == true;
                                                                return DropdownMenuItem<String>(
                                                                  value: resume['filePath'] ?? resume['_id'],
                                                                  child: Row(
                                                                    children: [
                                                                      const Icon(Icons.picture_as_pdf,
                                                                          color: Colors.indigo, size: 20),
                                                                      const SizedBox(width: 8),
                                                                      Expanded(
                                                                        child: Text(
                                                                          '$fileName (${resume['format'] ?? 'custom'}, $updatedAt)${isActive ? ' [Active]' : ''}',
                                                                          overflow: TextOverflow.ellipsis,
                                                                        ),
                                                                      ),
                                                                      IconButton(
                                                                        icon: Icon(
                                                                          isActive ? Icons.star : Icons.star_border,
                                                                          color: isActive ? Colors.amber : Colors.grey,
                                                                          size: 20,
                                                                        ),
                                                                        onPressed: isActive
                                                                            ? null
                                                                            : () async {
                                                                                try {
                                                                                  await ResumeService.setActiveResume(
                                                                                      resume['_id']);
                                                                                  await _fetchResumes();
                                                                                  _showStyledSnackBar(
                                                                                    context,
                                                                                    message:
                                                                                        'Resume set as active: $fileName',
                                                                                    isError: false,
                                                                                  );
                                                                                } catch (e) {
                                                                                  print('DEBUG: Error setting active resume: $e');
                                                                                  _showStyledSnackBar(
                                                                                    context,
                                                                                    message:
                                                                                        'Failed to set active resume: $e',
                                                                                    isError: true,
                                                                                  );
                                                                                }
                                                                              },
                                                                      ),
                                                                      IconButton(
                                                                        icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                                                        onPressed: () => _deleteResume(resume['_id']),
                                                                      ),
                                                                      IconButton(
                                                                        icon: const Icon(Icons.preview, color: Colors.blue, size: 20),
                                                                        onPressed: () => _downloadAndPreviewPDF(
                                                                          resume['filePath'] ?? '',
                                                                          fileName,
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                );
                                                              }).toList(),
                                                              onChanged: (value) {
                                                                setState(() {
                                                                  _selectedResume = value;
                                                                  print('DEBUG: Dropdown selected: $value');
                                                                });
                                                              },
                                                              key: UniqueKey(),
                                                            ),
                                                          ],
                                                        ),
                                                ],
                                              ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
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
                                    _buildInfoRow('Student ID', _profile?['studentId']?.toString() ?? 'Unknown'),
                                    _buildInfoRow('Email', _profile?['email']?.toString() ?? 'Unknown'),
                                    _buildInfoRow('Phone', _profile?['phone']?.toString() ?? 'Unknown'),
                                    _buildInfoRow('Address', _profile?['address']?.toString() ?? 'Unknown'),
                                    _buildInfoRow('DOB', _formatDate(_profile?['dob'])),
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
                                        '10th Percentage', '${_profile?['tenthPercentage']?.toString() ?? 'N/A'}%'),
                                    _buildInfoRow(
                                        '12th Percentage', '${_profile?['twelfthPercentage']?.toString() ?? 'N/A'}%'),
                                    _buildInfoRow(
                                        'Diploma Percentage', '${_profile?['diplomaPercentage']?.toString() ?? 'N/A'}%'),
                                    _buildInfoRow('Current CGPA', _profile?['currentCgpa']?.toString() ?? 'N/A'),
                                    _buildInfoRow('No. of Backlogs', _profile?['noOfBacklogs']?.toString() ?? 'N/A'),
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
                                    _buildInfoRow('Placed', _profile?['placedStatus'] == true ? 'Yes' : 'No'),
                                    _buildInfoRow(
                                        'Applied Placements', _profile?['placements']?.length.toString() ?? '0'),
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
                                    shape: const StadiumBorder(),
                                    elevation: 4,
                                    shadowColor: Colors.indigo.withOpacity(0.5),
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
}