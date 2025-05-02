import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/resume_service.dart';
import '../services/profile_service.dart';
import 'dart:convert';

class ResumeBuilderScreen extends StatefulWidget {
  final String usn;

  const ResumeBuilderScreen({super.key, required this.usn});

  @override
  _ResumeBuilderScreenState createState() => _ResumeBuilderScreenState();
}

class _ResumeBuilderScreenState extends State<ResumeBuilderScreen> {
  bool _showForm = false;
  String _selectedFormat = 'college';
  bool _isLoading = false;
  String _errorMessage = '';
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  // Form fields
  String _name = '';
  String _email = '';
  String _phone = '';
  String _linkedin = '';
  String _github = '';
  String _address = '';
  String _summary = '';
  String _sslcSchool = '';
  String _sslcYear = '';
  String _sslcPercentage = '';
  String _puCollege = '';
  String _puYear = '';
  String _puPercentage = '';
  String _diplomaCollege = '';
  String _diplomaYear = '';
  String _diplomaPercentage = '';
  bool _hasDiploma = false;
  String _beCollege = '';
  String _beYear = '';
  String _beCgpa = '';
  String _languages = '';
  String _interface = '';
  String _database = '';
  String _tools = '';
  List<Map<String, String>> _customSkills = [];
  String _internship = '';
  String _projects = '';
  String _courses = '';
  String _hobbies = '';
  File? _photoFile;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final profile = await ProfileService.fetchStudentProfile();
      setState(() {
        _name = profile['fullName'] ?? '';
        _email = profile['email'] ?? '';
        _phone = profile['phone'] ?? '';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load profile: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _pickPhoto() async {
    final status = await Permission.photos.request();
    if (status.isGranted) {
      final XFile? photo = await _picker.pickImage(source: ImageSource.gallery);
      if (photo != null) {
        setState(() {
          _photoFile = File(photo.path);
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo permission denied')),
      );
    }
  }

  Future<pw.ImageProvider?> _getPhotoImage() async {
    if (_photoFile == null) return null;
    try {
      final bytes = await _photoFile!.readAsBytes();
      return pw.MemoryImage(bytes);
    } catch (e) {
      print('DEBUG: Failed to load photo: $e');
      return null;
    }
  }

  Future<void> _generateAndDownloadPdf() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final pdf = pw.Document();

    // Load Times New Roman font from assets
    final timesRegular = await pw.Font.ttf(
        await DefaultAssetBundle.of(context).load('assets/fonts/times.ttf'));
    final timesBold = await pw.Font.ttf(
        await DefaultAssetBundle.of(context).load('assets/fonts/timesbd.ttf'));
    final textColor = PdfColor.fromHex('#000000');
    final photoImage = await _getPhotoImage();

    if (_selectedFormat == 'college') {
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) => [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Name and Photo
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(
                      child: pw.Text(
                        _name,
                        style: pw.TextStyle(
                          font: timesBold,
                          fontSize: 24,
                          color: textColor,
                        ),
                      ),
                    ),
                    if (photoImage != null)
                      pw.Container(
                        width: 80,
                        height: 80,
                        child: pw.ClipOval(
                          child: pw.Image(
                            photoImage,
                            fit: pw.BoxFit.cover,
                          ),
                        ),
                      ),
                  ],
                ),
                pw.SizedBox(height: 8),
                // Contact Info
                pw.Text(
                  _email,
                  style: pw.TextStyle(
                    font: timesRegular,
                    fontSize: 10,
                    color: textColor,
                  ),
                ),
                pw.Text(
                  _phone,
                  style: pw.TextStyle(
                    font: timesRegular,
                    fontSize: 10,
                    color: textColor,
                  ),
                ),
                pw.Text(
                  _github,
                  style: pw.TextStyle(
                    font: timesRegular,
                    fontSize: 10,
                    color: textColor,
                  ),
                ),
                pw.Text(
                  _address,
                  style: pw.TextStyle(
                    font: timesRegular,
                    fontSize: 10,
                    color: textColor,
                  ),
                ),
                pw.SizedBox(height: 12),
                // Summary
                pw.Text(
                  'SUMMARY',
                  style: pw.TextStyle(
                    font: timesBold,
                    fontSize: 14,
                    color: textColor,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  _summary,
                  style: pw.TextStyle(
                    font: timesRegular,
                    fontSize: 10,
                    color: textColor,
                  ),
                ),
                pw.SizedBox(height: 12),
                // Education
                pw.Text(
                  'EDUCATION',
                  style: pw.TextStyle(
                    font: timesBold,
                    fontSize: 14,
                    color: textColor,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Bachelor of Engineering - Artificial Intelligence and Machine Learning $_beYear CGPA: $_beCgpa\n$_beCollege',
                  style: pw.TextStyle(
                    font: timesRegular,
                    fontSize: 10,
                    color: textColor,
                  ),
                ),
                if (_hasDiploma)
                  pw.Text(
                    'Diploma $_diplomaYear Percentage: $_diplomaPercentage\n$_diplomaCollege',
                    style: pw.TextStyle(
                      font: timesRegular,
                      fontSize: 10,
                      color: textColor,
                    ),
                  ),
                if (!_hasDiploma)
                  pw.Text(
                    'Senior Secondary (12th) $_puYear Percentage: $_puPercentage\n$_puCollege',
                    style: pw.TextStyle(
                      font: timesRegular,
                      fontSize: 10,
                      color: textColor,
                    ),
                  ),
                pw.Text(
                  'Secondary School (SSLC) $_sslcYear Percentage: $_sslcPercentage\n$_sslcSchool',
                  style: pw.TextStyle(
                    font: timesRegular,
                    fontSize: 10,
                    color: textColor,
                  ),
                ),
                pw.SizedBox(height: 12),
                // Skills
                pw.Text(
                  'SKILLS',
                  style: pw.TextStyle(
                    font: timesBold,
                    fontSize: 14,
                    color: textColor,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Languages: $_languages',
                  style: pw.TextStyle(
                    font: timesRegular,
                    fontSize: 10,
                    color: textColor,
                  ),
                ),
                pw.Text(
                  'Interface: $_interface',
                  style: pw.TextStyle(
                    font: timesRegular,
                    fontSize: 10,
                    color: textColor,
                  ),
                ),
                pw.Text(
                  'Database: $_database',
                  style: pw.TextStyle(
                    font: timesRegular,
                    fontSize: 10,
                    color: textColor,
                  ),
                ),
                pw.Text(
                  'Tools: $_tools',
                  style: pw.TextStyle(
                    font: timesRegular,
                    fontSize: 10,
                    color: textColor,
                  ),
                ),
                for (var custom in _customSkills)
                  pw.Text(
                    '${custom['heading']}: ${custom['content']}',
                    style: pw.TextStyle(
                      font: timesRegular,
                      fontSize: 10,
                      color: textColor,
                    ),
                  ),
                pw.SizedBox(height: 12),
                // Internship
                pw.Text(
                  'INTERNSHIP',
                  style: pw.TextStyle(
                    font: timesBold,
                    fontSize: 14,
                    color: textColor,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  _internship,
                  style: pw.TextStyle(
                    font: timesRegular,
                    fontSize: 10,
                    color: textColor,
                  ),
                ),
                pw.SizedBox(height: 12),
                // Projects
                pw.Text(
                  'PROJECTS',
                  style: pw.TextStyle(
                    font: timesBold,
                    fontSize: 14,
                    color: textColor,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  _projects,
                  style: pw.TextStyle(
                    font: timesRegular,
                    fontSize: 10,
                    color: textColor,
                  ),
                ),
                pw.SizedBox(height: 12),
                // Courses
                pw.Text(
                  'COURSES',
                  style: pw.TextStyle(
                    font: timesBold,
                    fontSize: 14,
                    color: textColor,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  _courses,
                  style: pw.TextStyle(
                    font: timesRegular,
                    fontSize: 10,
                    color: textColor,
                  ),
                ),
                pw.SizedBox(height: 12),
                // Hobbies
                pw.Text(
                  'HOBBIES',
                  style: pw.TextStyle(
                    font: timesBold,
                    fontSize: 14,
                    color: textColor,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  _hobbies,
                  style: pw.TextStyle(
                    font: timesRegular,
                    fontSize: 10,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    } else {
      pdf.addPage(
        pw.Page(
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) => pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                flex: 1,
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  color: PdfColor.fromHex('#E3F2FD'),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        _name,
                        style: pw.TextStyle(
                          font: timesBold,
                          fontSize: 20,
                        ),
                      ),
                      if (photoImage != null)
                        pw.Container(
                          width: 60,
                          height: 60,
                          margin: const pw.EdgeInsets.only(bottom: 8),
                          child: pw.ClipOval(
                            child: pw.Image(
                              photoImage,
                              fit: pw.BoxFit.cover,
                            ),
                          ),
                        ),
                      pw.Text(
                        _email,
                        style: pw.TextStyle(
                          font: timesRegular,
                          fontSize: 10,
                        ),
                      ),
                      pw.Text(
                        _phone,
                        style: pw.TextStyle(
                          font: timesRegular,
                          fontSize: 10,
                        ),
                      ),
                      pw.Text(
                        _github,
                        style: pw.TextStyle(
                          font: timesRegular,
                          fontSize: 10,
                        ),
                      ),
                      pw.Text(
                        _address,
                        style: pw.TextStyle(
                          font: timesRegular,
                          fontSize: 10,
                        ),
                      ),
                      pw.SizedBox(height: 12),
                      pw.Text(
                        'SKILLS',
                        style: pw.TextStyle(
                          font: timesBold,
                          fontSize: 14,
                        ),
                      ),
                      pw.Text(
                        'Languages: $_languages',
                        style: pw.TextStyle(
                          font: timesRegular,
                          fontSize: 10,
                        ),
                      ),
                      pw.Text(
                        'Interface: $_interface',
                        style: pw.TextStyle(
                          font: timesRegular,
                          fontSize: 10,
                        ),
                      ),
                      pw.Text(
                        'Database: $_database',
                        style: pw.TextStyle(
                          font: timesRegular,
                          fontSize: 10,
                        ),
                      ),
                      pw.Text(
                        'Tools: $_tools',
                        style: pw.TextStyle(
                          font: timesRegular,
                          fontSize: 10,
                        ),
                      ),
                      for (var custom in _customSkills)
                        pw.Text(
                          '${custom['heading']}: ${custom['content']}',
                          style: pw.TextStyle(
                            font: timesRegular,
                            fontSize: 10,
                          ),
                        ),
                      pw.SizedBox(height: 12),
                      pw.Text(
                        'HOBBIES',
                        style: pw.TextStyle(
                          font: timesBold,
                          fontSize: 14,
                        ),
                      ),
                      pw.Text(
                        _hobbies,
                        style: pw.TextStyle(
                          font: timesRegular,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(width: 16),
              pw.Expanded(
                flex: 2,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'SUMMARY',
                      style: pw.TextStyle(
                        font: timesBold,
                        fontSize: 14,
                      ),
                    ),
                    pw.Text(
                      _summary,
                      style: pw.TextStyle(
                        font: timesRegular,
                        fontSize: 10,
                      ),
                    ),
                    pw.SizedBox(height: 12),
                    pw.Text(
                      'EDUCATION',
                      style: pw.TextStyle(
                        font: timesBold,
                        fontSize: 14,
                      ),
                    ),
                    pw.Text(
                      'Bachelor of Engineering - Artificial Intelligence and Machine Learning $_beYear CGPA: $_beCgpa\n$_beCollege',
                      style: pw.TextStyle(
                        font: timesRegular,
                        fontSize: 10,
                      ),
                    ),
                    if (_hasDiploma)
                      pw.Text(
                        'Diploma $_diplomaYear Percentage: $_diplomaPercentage\n$_diplomaCollege',
                        style: pw.TextStyle(
                          font: timesRegular,
                          fontSize: 10,
                        ),
                      ),
                    if (!_hasDiploma)
                      pw.Text(
                        'Senior Secondary (12th) $_puYear Percentage: $_puPercentage\n$_puCollege',
                        style: pw.TextStyle(
                          font: timesRegular,
                          fontSize: 10,
                        ),
                      ),
                    pw.Text(
                      'Secondary School (SSLC) $_sslcYear Percentage: $_sslcPercentage\n$_sslcSchool',
                      style: pw.TextStyle(
                        font: timesRegular,
                        fontSize: 10,
                      ),
                    ),
                    pw.SizedBox(height: 12),
                    pw.Text(
                      'INTERNSHIP',
                      style: pw.TextStyle(
                        font: timesBold,
                        fontSize: 14,
                      ),
                    ),
                    pw.Text(
                      _internship,
                      style: pw.TextStyle(
                        font: timesRegular,
                        fontSize: 10,
                      ),
                    ),
                    pw.SizedBox(height: 12),
                    pw.Text(
                      'PROJECTS',
                      style: pw.TextStyle(
                        font: timesBold,
                        fontSize: 14,
                      ),
                    ),
                    pw.Text(
                      _projects,
                      style: pw.TextStyle(
                        font: timesRegular,
                        fontSize: 10,
                        lineSpacing: 1.5,
                      ),
                    ),
                    pw.SizedBox(height: 12),
                    pw.Text(
                      'COURSES',
                      style: pw.TextStyle(
                        font: timesBold,
                        fontSize: 14,
                      ),
                    ),
                    pw.Text(
                      _courses,
                      style: pw.TextStyle(
                        font: timesRegular,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    try {
      // Generate PDF bytes
      final pdfBytes = await pdf.save();
      // Encode PDF to base64
      final base64Data = base64Encode(pdfBytes);
      // Generate filename
      final originalFileName = 'resume_${widget.usn}_${_selectedFormat}.pdf';

      // Save resume to backend
      await ResumeService.saveResume(
        usn: widget.usn,
        pdfData: base64Data,
        originalFileName: originalFileName,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Resume saved successfully: $originalFileName')),
      );

      // Save PDF locally and share
      final outputDir = await getTemporaryDirectory();
      final file = File('${outputDir.path}/$originalFileName');
      await file.writeAsBytes(pdfBytes);
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: originalFileName,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF generated and ready for download')),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to generate or save resume: $e';
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // ... Rest of the file remains unchanged ...


  Widget _buildPreview(String format) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedFormat = format;
            _showForm = true;
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                format == 'college'
                    ? 'College Format (Recommended)'
                    : 'General Format',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: format == _selectedFormat
                      ? Colors.indigo
                      : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                ),
                child: format == 'college'
                    ? _buildCollegePreview()
                    : _buildGeneralPreview(),
              ),
              const SizedBox(height: 8),
              Text(
                format == 'college'
                    ? 'Single-column layout with photo, ideal for academic submissions'
                    : 'Two-column modern design, great for industry applications',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCollegePreview() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Name',
                  style: TextStyle(
                    fontFamily: 'Times',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey,
                ),
                child: const Icon(
                  Icons.person,
                  size: 20,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Email | Phone | GitHub | Address',
            style: TextStyle(
              fontFamily: 'Times',
              fontSize: 8,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'SUMMARY',
            style: TextStyle(
              fontFamily: 'Times',
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
          Container(height: 10, color: Colors.grey.shade200),
          const SizedBox(height: 8),
          const Text(
            'EDUCATION',
            style: TextStyle(
              fontFamily: 'Times',
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
          const Text(
            'B.E. | 12th | SSLC',
            style: TextStyle(
              fontFamily: 'Times',
              fontSize: 8,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'SKILLS',
            style: TextStyle(
              fontFamily: 'Times',
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
          const Text(
            'Languages | Interface | Database | Tools',
            style: TextStyle(
              fontFamily: 'Times',
              fontSize: 8,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'INTERNSHIP',
            style: TextStyle(
              fontFamily: 'Times',
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
          Container(height: 10, color: Colors.grey.shade200),
          const SizedBox(height: 8),
          const Text(
            'PROJECTS',
            style: TextStyle(
              fontFamily: 'Times',
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
          Container(height: 10, color: Colors.grey.shade200),
          const SizedBox(height: 8),
          const Text(
            'COURSES',
            style: TextStyle(
              fontFamily: 'Times',
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
          Container(height: 10, color: Colors.grey.shade200),
          const SizedBox(height: 8),
          const Text(
            'HOBBIES',
            style: TextStyle(
              fontFamily: 'Times',
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
          Container(height: 10, color: Colors.grey.shade200),
        ],
      ),
    );
  }

  Widget _buildGeneralPreview() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 1,
          child: Container(
            color: Colors.blue.shade50,
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Name',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey,
                  ),
                  child: const Icon(
                    Icons.person,
                    size: 15,
                    color: Colors.white,
                  ),
                ),
                const Text(
                  'Contact',
                  style: TextStyle(fontSize: 8),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Skills',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 8,
                  ),
                ),
                Container(height: 20, color: Colors.grey.shade200),
                const SizedBox(height: 4),
                const Text(
                  'Hobbies',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 8,
                  ),
                ),
                Container(height: 20, color: Colors.grey.shade200),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Summary',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 8,
                  ),
                ),
                Container(height: 20, color: Colors.grey.shade200),
                const SizedBox(height: 4),
                const Text(
                  'Education',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 8,
                  ),
                ),
                Container(height: 20, color: Colors.grey.shade200),
                const SizedBox(height: 4),
                const Text(
                  'Internship',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 8,
                  ),
                ),
                Container(height: 20, color: Colors.grey.shade200),
                const SizedBox(height: 4),
                const Text(
                  'Projects',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 8,
                  ),
                ),
                Container(height: 20, color: Colors.grey.shade200),
                const SizedBox(height: 4),
                const Text(
                  'Courses',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 8,
                  ),
                ),
                Container(height: 20, color: Colors.grey.shade200),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextFormField(
                initialValue: _name,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                validator: (value) => value!.isEmpty ? 'Required' : null,
                onSaved: (value) => _name = value!,
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: _email,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                validator: (value) => value!.isEmpty ? 'Required' : null,
                onSaved: (value) => _email = value!,
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: _phone,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                validator: (value) => value!.isEmpty ? 'Required' : null,
                onSaved: (value) => _phone = value!,
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: _github,
                decoration: InputDecoration(
                  labelText: 'GitHub URL',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                onSaved: (value) => _github = value ?? '',
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: _address,
                decoration: InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                onSaved: (value) => _address = value ?? '',
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: _summary,
                decoration: InputDecoration(
                  labelText: 'Summary',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                maxLines: 4,
                validator: (value) => value!.isEmpty ? 'Required' : null,
                onSaved: (value) => _summary = value!,
              ),
              const SizedBox(height: 12),
              // Education: SSLC
              TextFormField(
                initialValue: _sslcSchool,
                decoration: InputDecoration(
                  labelText: 'SSLC School Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                validator: (value) => value!.isEmpty ? 'Required' : null,
                onSaved: (value) => _sslcSchool = value!,
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: _sslcYear,
                decoration: InputDecoration(
                  labelText: 'SSLC Year (e.g., 2018-2019)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                validator: (value) => value!.isEmpty ? 'Required' : null,
                onSaved: (value) => _sslcYear = value!,
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: _sslcPercentage,
                decoration: InputDecoration(
                  labelText: 'SSLC Percentage (e.g., 88%)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                validator: (value) => value!.isEmpty ? 'Required' : null,
                onSaved: (value) => _sslcPercentage = value!,
              ),
              const SizedBox(height: 12),
              // Education: 12th or Diploma
              CheckboxListTile(
                title: const Text('Diploma instead of 12th'),
                value: _hasDiploma,
                onChanged: (value) {
                  setState(() {
                    _hasDiploma = value!;
                  });
                },
              ),
              if (!_hasDiploma) ...[
                TextFormField(
                  initialValue: _puCollege,
                  decoration: InputDecoration(
                    labelText: '12th College Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                  onSaved: (value) => _puCollege = value!,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: _puYear,
                  decoration: InputDecoration(
                    labelText: '12th Year (e.g., 2019-2021)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                  onSaved: (value) => _puYear = value!,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: _puPercentage,
                  decoration: InputDecoration(
                    labelText: '12th Percentage (e.g., 89%)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                  onSaved: (value) => _puPercentage = value!,
                ),
              ],
              if (_hasDiploma) ...[
                TextFormField(
                  initialValue: _diplomaCollege,
                  decoration: InputDecoration(
                    labelText: 'Diploma College Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                  onSaved: (value) => _diplomaCollege = value!,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: _diplomaYear,
                  decoration: InputDecoration(
                    labelText: 'Diploma Year (e.g., 2019-2021)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                  onSaved: (value) => _diplomaYear = value!,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: _diplomaPercentage,
                  decoration: InputDecoration(
                    labelText: 'Diploma Percentage (e.g., 85%)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                  onSaved: (value) => _diplomaPercentage = value!,
                ),
              ],
              const SizedBox(height: 12),
              // Education: B.E.
              TextFormField(
                initialValue: _beCollege,
                decoration: InputDecoration(
                  labelText: 'B.E. College Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                validator: (value) => value!.isEmpty ? 'Required' : null,
                onSaved: (value) => _beCollege = value!,
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: _beYear,
                decoration: InputDecoration(
                  labelText: 'B.E. Year (e.g., 2021-Present)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                validator: (value) => value!.isEmpty ? 'Required' : null,
                onSaved: (value) => _beYear = value!,
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: _beCgpa,
                decoration: InputDecoration(
                  labelText: 'B.E. CGPA (e.g., 8.55)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                validator: (value) => value!.isEmpty ? 'Required' : null,
                onSaved: (value) => _beCgpa = value!,
              ),
              const SizedBox(height: 12),
              // Skills
              TextFormField(
                initialValue: _languages,
                decoration: InputDecoration(
                  labelText: 'Languages (e.g., Java, Python, C)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                validator: (value) => value!.isEmpty ? 'Required' : null,
                onSaved: (value) => _languages = value!,
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: _interface,
                decoration: InputDecoration(
                  labelText: 'Interface (e.g., HTML, CSS)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                validator: (value) => value!.isEmpty ? 'Required' : null,
                onSaved: (value) => _interface = value!,
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: _database,
                decoration: InputDecoration(
                  labelText: 'Database (e.g., Firebase, SQL)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                validator: (value) => value!.isEmpty ? 'Required' : null,
                onSaved: (value) => _database = value!,
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: _tools,
                decoration: InputDecoration(
                  labelText: 'Tools (e.g., MySQL, VS Code, Jupyter)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                validator: (value) => value!.isEmpty ? 'Required' : null,
                onSaved: (value) => _tools = value!,
              ),
              const SizedBox(height: 12),
              // Custom Skills
              ..._customSkills.asMap().entries.map((entry) {
                int index = entry.key;
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: _customSkills[index]['heading'],
                            decoration: InputDecoration(
                              labelText: 'Custom Skill Heading',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                            onSaved: (value) =>
                                _customSkills[index]['heading'] = value!,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              _customSkills.removeAt(index);
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      initialValue: _customSkills[index]['content'],
                      decoration: InputDecoration(
                        labelText: 'Custom Skill Content',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                      onSaved: (value) =>
                          _customSkills[index]['content'] = value!,
                    ),
                    const SizedBox(height: 12),
                  ],
                );
              }),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _customSkills.add({'heading': '', 'content': ''});
                  });
                },
                child: const Text('Add Custom Skill'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: _internship,
                decoration: InputDecoration(
                  labelText:
                      'Internship (e.g., Niveus Solutions | Android App Developer | Oct 2023 - Nov 2023\nProject: ...)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                maxLines: 4,
                onSaved: (value) => _internship = value ?? '',
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: _projects,
                decoration: InputDecoration(
                  labelText:
                      'Projects (e.g., Automobile Review System | Jan 2023 - Mar 2024\nTechnologies: ...)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                maxLines: 4,
                onSaved: (value) => _projects = value ?? '',
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: _courses,
                decoration: InputDecoration(
                  labelText: 'Courses (e.g., Cloud Computing, NPTEL, 2023)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                maxLines: 2,
                onSaved: (value) => _courses = value ?? '',
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: _hobbies,
                decoration: InputDecoration(
                  labelText: 'Hobbies (e.g., Playing Mobile Games)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                maxLines: 2,
                onSaved: (value) => _hobbies = value ?? '',
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _pickPhoto,
                child: const Text('Upload Photo'),
              ),
              if (_photoFile != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Image.file(
                    _photoFile!,
                    height: 100,
                    width: 100,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(height: 16),
              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () {
                        if (_formKey.currentState!.validate()) {
                          _formKey.currentState!.save();
                          _generateAndDownloadPdf();
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Generate PDF',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resume Builder'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _showForm
              ? _buildForm()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Choose a Resume Format',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildPreview('college'),
                      _buildPreview('general'),
                    ],
                  ),
                ),
    );
  }
}