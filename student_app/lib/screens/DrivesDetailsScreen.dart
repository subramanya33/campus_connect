import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/drive_service.dart';
import '../services/resume_service.dart';
import '../services/profile_service.dart';

class DriveDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> drive;

  const DriveDetailsScreen({super.key, required this.drive});

  @override
  _DriveDetailsScreenState createState() => _DriveDetailsScreenState();
}

class _DriveDetailsScreenState extends State<DriveDetailsScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  bool _isApplying = false;
  String _errorMessage = '';
  Map<String, dynamic>? _roundStatus;
  bool _hasApplied = false;
  bool _isEligible = false;
  List<dynamic>? _shortlistResults;
  bool _isShortlisted = false;
  String? _currentUsn;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  Map<String, dynamic>? _studentProfile;
  List<String> _resumeSkills = [];

  @override
  void initState() {
    super.initState();
    print('DEBUG: DriveDetailsScreen initialized for ${widget.drive['company']}');
    _hasApplied = widget.drive['hasApplied'] ?? false;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _fetchDriveDetails();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchDriveDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final futures = <Future>[];
      futures.add(DrivesService.sessionService.getSession().then((session) {
        _currentUsn = session['usn'];
        print('DEBUG: Current USN: $_currentUsn');
      }));
      futures.add(ProfileService.fetchStudentProfile().then((profile) {
        _studentProfile = profile;
        print('DEBUG: Student profile fetched: CGPA=${profile['currentCgpa']}, Tenth=${profile['tenthPercentage']}');
      }));
      futures.add(ProfileService.fetchResumeSkills().then((skills) {
        _resumeSkills = skills;
        print('DEBUG: Resume skills fetched: ${_resumeSkills.join(', ')}');
      }));

      final status = widget.drive['status']?.toLowerCase() ?? 'unknown';
      print('DEBUG: Drive status: $status, hasApplied: $_hasApplied');

      if (status == 'ongoing') {
        futures.add(DrivesService.fetchRoundStatus(widget.drive['_id']).then((status) {
          _roundStatus = status;
          print('DEBUG: Round status fetched: $_roundStatus');
        }));
      } else if (status == 'upcoming') {
        futures.add(DrivesService.checkApplicationStatus(widget.drive['_id']).then((hasApplied) {
          _hasApplied = hasApplied;
          print('DEBUG: Application status checked: hasApplied = $_hasApplied');
        }));
      } else if (status == 'completed') {
        futures.add(DrivesService.fetchShortlistResults(widget.drive['_id']).then((results) {
          _shortlistResults = results;
          _isShortlisted = results.any((student) => student['usn'] == _currentUsn);
          print('DEBUG: Shortlist results fetched: ${_shortlistResults?.length} students, isShortlisted: $_isShortlisted');
        }));
      }

      await Future.wait(futures);
      _isEligible = _checkEligibility();
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
      print('DEBUG: Error fetching drive details: $_errorMessage');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _errorMessage,
            style: GoogleFonts.roboto(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  bool _checkEligibility() {
    if (_studentProfile == null) {
      print('DEBUG: Student profile is null; not eligible');
      return false;
    }
    final drive = widget.drive;
    final cgpa = _studentProfile!['currentCgpa']?.toDouble() ?? 0.0;
    final tenthPercentage = _studentProfile!['tenthPercentage']?.toDouble() ?? 0.0;
    final requiredCgpa = (drive['requiredCgpa'] as num?)?.toDouble() ?? 0.0;
    final requiredPercentage = (drive['requiredPercentage'] as num?)?.toDouble() ?? 80.0;
    final requiredSkills = List<String>.from(drive['skills'] ?? []);
    final matchedSkills = requiredSkills.where((skill) => _resumeSkills.contains(skill.toLowerCase())).length;
    final skillMatchPercentage = requiredSkills.isEmpty ? 100.0 : (matchedSkills / requiredSkills.length) * 100;
    final skillsEligible = skillMatchPercentage >= 80.0;

    print('DEBUG: Eligibility check - CGPA: $cgpa/$requiredCgpa, Tenth: $tenthPercentage/$requiredPercentage, Skills: $skillMatchPercentage%');
    return cgpa >= requiredCgpa && tenthPercentage >= requiredPercentage && skillsEligible;
  }

  Future<void> _showApplyOptions() async {
    if (!_isEligible) {
      setState(() {
        _errorMessage = 'You are not eligible for this drive.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _errorMessage,
            style: GoogleFonts.roboto(color: Colors.white),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Apply for ${widget.drive['company']}',
          style: GoogleFonts.roboto(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        content: const Text('Choose how you want to apply:'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _applyManually();
            },
            child: Text(
              'Manually Apply',
              style: GoogleFonts.roboto(color: Colors.indigo.shade600),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _applyWithResume();
            },
            child: Text(
              'Apply with Resume',
              style: GoogleFonts.roboto(color: Colors.indigo.shade600),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _applyManually() async {
    setState(() {
      _isApplying = true;
      _errorMessage = '';
    });

    try {
      await DrivesService.applyForDrive(widget.drive['_id']);
      setState(() {
        _hasApplied = true;
        _isApplying = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Successfully applied for the drive!',
            style: GoogleFonts.roboto(color: Colors.white),
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } catch (e) {
      String errorMessage = e.toString().replaceFirst('Exception: ', '');
      if (errorMessage.contains('already applied')) {
        errorMessage = 'You have already applied for this drive.';
      } else if (errorMessage.contains('not eligible')) {
        errorMessage = 'You are not eligible for this drive.';
      } else if (errorMessage.contains('non-upcoming')) {
        errorMessage = 'This drive is no longer open for applications.';
      }
      setState(() {
        _errorMessage = errorMessage;
        _isApplying = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            errorMessage,
            style: GoogleFonts.roboto(color: Colors.white),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  Future<void> _applyWithResume() async {
    setState(() {
      _isApplying = true;
      _errorMessage = '';
    });

    try {
      final List<Map<String, dynamic>> resumes = await ResumeService.fetchResumes();
      print('DEBUG: Fetched resumes: $resumes');
      if (resumes.isEmpty) {
        throw Exception('No resume found. Please upload a resume.');
      }

      final Map<String, dynamic> activeResume = resumes.firstWhere(
        (resume) => resume['isActive'],
        orElse: () => resumes.first,
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EligibilityCheckScreen(
            drive: widget.drive,
            profile: {
              'cgpa': _studentProfile?['currentCgpa']?.toDouble() ?? 0.0,
              'tenthPercentage': _studentProfile?['tenthPercentage']?.toDouble() ?? 0.0,
              'skills': _resumeSkills,
              'resumeId': activeResume['filePath'] ?? '',
            },
            onApply: () async {
              await DrivesService.applyForDrive(widget.drive['_id'], resumeId: activeResume['filePath']);
              setState(() {
                _hasApplied = true;
                _isApplying = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Successfully applied with resume!',
                    style: GoogleFonts.roboto(color: Colors.white),
                  ),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              );
            },
          ),
        ),
      ).then((_) {
        setState(() {
          _isApplying = false;
        });
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isApplying = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _errorMessage,
            style: GoogleFonts.roboto(color: Colors.white),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  Widget _buildBanner() {
    final drive = widget.drive;
    final companyName = (drive['company'] ?? 'Unknown').toString().toLowerCase();
    return Container(
      height: 220,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade700, Colors.indigo.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: CachedNetworkImage(
          imageUrl: drive['bannerImage']?.isNotEmpty == true
              ? drive['bannerImage']
              : 'http://192.168.1.101:3000/uploads/placement_banners/$companyName.jpg',
          height: 220,
          width: double.infinity,
          fit: BoxFit.cover,
          placeholder: (context, url) => const Center(child: CircularProgressIndicator(color: Colors.white)),
          errorWidget: (context, url, error) => Container(
            color: Colors.grey[300],
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.image_not_supported, size: 50, color: Colors.grey[600]),
                Text(
                  'Image Not Available',
                  style: GoogleFonts.roboto(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    final drive = widget.drive;
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              drive['company'] ?? 'Unknown Company',
              style: GoogleFonts.roboto(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.indigo.shade700,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Sector', drive['sector'] ?? 'N/A'),
            _buildInfoRow('Job Profile', drive['jobProfile'] ?? 'N/A'),
            _buildInfoRow('Package', '${drive['package'] ?? 'N/A'} LPA'),
            _buildInfoRow('Required CGPA', drive['requiredCgpa']?.toString() ?? 'N/A'),
            _buildInfoRow('Required Percentage', drive['requiredPercentage']?.toString() ?? 'N/A'),
            _buildInfoRow('Skills', (drive['skills'] as List<dynamic>?)?.join(', ') ?? 'N/A'),
            _buildInfoRow('Drive Date', drive['driveDate'] ?? 'TBD'),
            _buildInfoRow('Eligibility', _isEligible ? 'Eligible' : 'Not Eligible'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: GoogleFonts.roboto(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.roboto(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSection() {
    final drive = widget.drive;
    return AnimatedOpacity(
      opacity: _isLoading ? 0.0 : 1.0,
      duration: const Duration(milliseconds: 500),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_errorMessage.isNotEmpty)
            Card(
              elevation: 2,
              color: Colors.red.shade50,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage,
                        style: GoogleFonts.roboto(color: Colors.red.shade700, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (drive['status']?.toLowerCase() == 'ongoing' && _roundStatus != null) ...[
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Round Status',
                      style: GoogleFonts.roboto(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo.shade700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow('Current Round', _roundStatus!['currentRound'] ?? 'N/A'),
                    _buildInfoRow(
                      'Shortlist Status',
                      _roundStatus!['isShortlisted'] ? 'Shortlisted' : 'Not Shortlisted',
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (drive['status']?.toLowerCase() == 'upcoming') ...[
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Application Status',
                      style: GoogleFonts.roboto(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo.shade700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_hasApplied)
                      Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green.shade700),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'You have already applied for this drive.',
                              style: GoogleFonts.roboto(
                                fontSize: 16,
                                color: Colors.green.shade700,
                              ),
                              softWrap: true,
                            ),
                          ),
                        ],
                      )
                    else
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: ElevatedButton(
                          onPressed: _isApplying ? null : _showApplyOptions,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            elevation: 4,
                            textStyle: GoogleFonts.roboto(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          child: _isApplying
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Apply Now'),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
          if (drive['status']?.toLowerCase() == 'completed' && _shortlistResults != null) ...[
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Shortlist Results',
                      style: GoogleFonts.roboto(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo.shade700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          _isShortlisted ? Icons.check_circle : Icons.cancel,
                          color: _isShortlisted ? Colors.green.shade700 : Colors.red.shade700,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isShortlisted ? 'You are shortlisted!' : 'You are not shortlisted.',
                          style: GoogleFonts.roboto(
                            fontSize: 16,
                            color: _isShortlisted ? Colors.green.shade700 : Colors.red.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _shortlistResults!.isEmpty
                        ? Text(
                            'No students shortlisted for this drive.',
                            style: GoogleFonts.roboto(
                              fontSize: 16,
                              color: Colors.grey[700],
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _shortlistResults!.length,
                            itemBuilder: (context, index) {
                              final student = _shortlistResults![index];
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  '${student['firstName']} ${student['lastName']}',
                                  style: GoogleFonts.roboto(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                subtitle: Text(
                                  'USN: ${student['usn']}',
                                  style: GoogleFonts.roboto(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              );
                            },
                          ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.indigo.shade700, Colors.indigo.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Text(
          widget.drive['company'] ?? 'Company Details',
          style: GoogleFonts.roboto(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 0,
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.indigo.shade50, Colors.white],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          _isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.indigo))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBanner(),
                      const SizedBox(height: 16),
                      _buildInfoCard(),
                      const SizedBox(height: 16),
                      _buildStatusSection(),
                    ],
                  ),
                ),
        ],
      ),
    );
  }
}

class EligibilityCheckScreen extends StatefulWidget {
  final Map<String, dynamic> drive;
  final Map<String, dynamic> profile;
  final VoidCallback onApply;

  const EligibilityCheckScreen({
    super.key,
    required this.drive,
    required this.profile,
    required this.onApply,
  });

  @override
  _EligibilityCheckScreenState createState() => _EligibilityCheckScreenState();
}

class _EligibilityCheckScreenState extends State<EligibilityCheckScreen> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _cgpaEligible = false;
  bool _percentageEligible = false;
  bool _skillsEligible = false;
  List<String> _ineligibilityReasons = [];
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.5, 0.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _checkEligibility();
  }

  Future<void> _checkEligibility() async {
    final drive = widget.drive;
    final profile = widget.profile;

    // CGPA Check
    double requiredCgpa = (drive['requiredCgpa'] as num?)?.toDouble() ?? 0.0;
    double userCgpa = profile['cgpa']?.toDouble() ?? 0.0;
    _cgpaEligible = userCgpa >= requiredCgpa;
    if (!_cgpaEligible) {
      _ineligibilityReasons.add('CGPA ($userCgpa) is below required ($requiredCgpa).');
    }
    setState(() {
      _currentStep = 1;
    });
    _controller.forward(from: 0.0);
    await Future.delayed(const Duration(milliseconds: 1500));

    // Percentage Check
    double requiredPercentage = (drive['requiredPercentage'] as num?)?.toDouble() ?? 80.0;
    double userPercentage = profile['tenthPercentage']?.toDouble() ?? 0.0;
    _percentageEligible = userPercentage >= requiredPercentage;
    if (!_percentageEligible) {
      _ineligibilityReasons.add('Tenth Percentage ($userPercentage%) is below required ($requiredPercentage%).');
    }
    setState(() {
      _currentStep = 2;
    });
    _controller.forward(from: 0.0);
    await Future.delayed(const Duration(milliseconds: 1500));

    // Skills Check
    List<String> requiredSkills = List<String>.from(drive['skills'] ?? []);
    List<String> userSkills = List<String>.from(profile['skills'] ?? []);
    int matchedSkills = requiredSkills.where((skill) => userSkills.contains(skill.toLowerCase())).length;
    double skillMatchPercentage = requiredSkills.isEmpty ? 100.0 : (matchedSkills / requiredSkills.length) * 100;
    _skillsEligible = skillMatchPercentage >= 80.0;
    if (!_skillsEligible) {
      _ineligibilityReasons.add('Skills match ($skillMatchPercentage%) is below 80%. Missing: ${requiredSkills.where((s) => !userSkills.contains(s.toLowerCase())).join(', ')}.');
    }
    setState(() {
      _currentStep = 3;
    });
    _controller.forward(from: 0.0);
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Need Help?',
          style: GoogleFonts.roboto(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'You are not eligible due to:\n${_ineligibilityReasons.join('\n')}\n\nContact the placement office at placement@mite.ac.in for guidance or to improve your profile.',
          style: GoogleFonts.roboto(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: GoogleFonts.roboto(color: Colors.indigo.shade600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Eligibility Check',
          style: GoogleFonts.roboto(color: Colors.white),
        ),
        backgroundColor: Colors.indigo.shade700,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Checking your eligibility for ${widget.drive['company']}',
              style: GoogleFonts.roboto(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.indigo.shade700,
              ),
            ),
            const SizedBox(height: 20),
            if (_currentStep >= 1)
              FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Row(
                    children: [
                      Icon(
                        _cgpaEligible ? Icons.check_circle : Icons.cancel,
                        color: _cgpaEligible ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _cgpaEligible
                            ? 'CGPA: Eligible (${widget.profile['cgpa']})'
                            : 'CGPA: Not Eligible (${widget.profile['cgpa']} < ${widget.drive['requiredCgpa']})',
                        style: GoogleFonts.roboto(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 10),
            if (_currentStep >= 2)
              FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Row(
                    children: [
                      Icon(
                        _percentageEligible ? Icons.check_circle : Icons.cancel,
                        color: _percentageEligible ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _percentageEligible
                            ? 'Tenth Percentage: Eligible (${widget.profile['tenthPercentage']}%)'
                            : 'Tenth Percentage: Not Eligible (${widget.profile['tenthPercentage']}% < ${widget.drive['requiredPercentage']}%)',
                        style: GoogleFonts.roboto(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 10),
            if (_currentStep >= 3)
              FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Row(
                    children: [
                      Icon(
                        _skillsEligible ? Icons.check_circle : Icons.cancel,
                        color: _skillsEligible ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _skillsEligible
                            ? 'Skills: Eligible'
                            : 'Skills: Not Eligible (Less than 80% match)',
                        style: GoogleFonts.roboto(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 20),
            if (_currentStep >= 3)
              _cgpaEligible && _percentageEligible && _skillsEligible
                  ? ElevatedButton(
                      onPressed: widget.onApply,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(
                        'Apply',
                        style: GoogleFonts.roboto(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'You are not eligible due to:',
                          style: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red.shade700),
                        ),
                        ..._ineligibilityReasons.map(
                          (reason) => Text(
                            '- $reason',
                            style: GoogleFonts.roboto(fontSize: 16, color: Colors.red.shade700),
                          ),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: _showHelpDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text(
                            'Get Help',
                            style: GoogleFonts.roboto(fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
          ],
        ),
      ),
    );
  }
}