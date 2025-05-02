import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/drive_service.dart';

class CompanyDetailsScreen extends StatefulWidget {
  final String placementId;
  final String companyName;
  final String status;

  const CompanyDetailsScreen({
    super.key,
    required this.placementId,
    required this.companyName,
    required this.status,
  });

  @override
  _CompanyDetailsScreenState createState() => _CompanyDetailsScreenState();
}

class _CompanyDetailsScreenState extends State<CompanyDetailsScreen> {
  Map<String, dynamic>? _placementDetails;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    print('DEBUG: CompanyDetailsScreen initialized for ${widget.companyName}');
    _fetchPlacementDetails();
  }

  Future<void> _fetchPlacementDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final details = await DrivesService.fetchPlacementDetails(widget.placementId);
      setState(() {
        _placementDetails = details;
        _isLoading = false;
      });
      print('DEBUG: Placement details loaded: ${details['company']}');
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
      print('DEBUG: Error fetching placement details: $e');
    }
  }

  Widget _buildInfoRow(String label, dynamic value) {
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
              value?.toString() ?? 'N/A',
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

  Widget _buildCompanyDetails() {
    final details = _placementDetails!['companyDetails'];
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: const Text(
          'Company Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.indigo,
          ),
        ),
        leading: const Icon(Icons.business, color: Colors.indigo),
        childrenPadding: const EdgeInsets.all(16.0),
        children: [
          _buildInfoRow('Sector', details['sector']),
          _buildInfoRow('Location', details['location']),
          _buildInfoRow('Job Profile', details['jobProfile']),
          _buildInfoRow('Category', details['category']),
          _buildInfoRow('Package', '${details['package']} LPA'),
          _buildInfoRow('Required CGPA', details['requiredCgpa']),
          _buildInfoRow('10th Percentage', '${details['tenthPercentage']}%'),
          _buildInfoRow('12th Percentage', '${details['twelfthPercentage']}%'),
          _buildInfoRow('Diploma Percentage', details['diplomaPercentage'] != null ? '${details['diplomaPercentage']}%' : 'N/A'),
          _buildInfoRow('Skills', details['skills']?.join(', ') ?? 'N/A'),
          _buildInfoRow('Backlogs Allowed', details['backlogsAllowed']),
          _buildInfoRow('Students Applied', details['studentsAppliedCount']),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Job Description',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  details['jobDescription'] ?? 'No description provided',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoundsSection() {
    final rounds = _placementDetails!['rounds'] as List<dynamic>;
    if (rounds.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text(
          'No rounds available.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: const Text(
          'Recruitment Rounds',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.indigo,
          ),
        ),
        leading: const Icon(Icons.event, color: Colors.indigo),
        childrenPadding: const EdgeInsets.all(16.0),
        children: rounds.map((round) {
          return ListTile(
            title: Text(
              round['roundName'] ?? 'Unknown Round',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Date: ${round['date'] ?? 'TBD'}'),
                Text('Shortlisted: ${round['shortlistedCount']} students'),
                if (round['shortlistedStudents']?.isNotEmpty == true)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'Students: ${(round['shortlistedStudents'] as List<dynamic>).map((s) => s['fullName']).join(', ')}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildResultsSection() {
    final results = _placementDetails!['placementResults'] as List<dynamic>;
    if (results.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text(
          'No placement results available.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: const Text(
          'Placement Results',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.indigo,
          ),
        ),
        leading: const Icon(Icons.emoji_events, color: Colors.indigo),
        childrenPadding: const EdgeInsets.all(16.0),
        children: [
          Text(
            'Selected Students: ${results.where((r) => r['status'] == 'selected').length}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...results.map((result) {
            return ListTile(
              title: Text(
                result['student']['fullName'] ?? 'Unknown',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: Text('USN: ${result['student']['usn'] ?? 'N/A'}'),
              trailing: Chip(
                label: Text(result['status'] ?? 'Unknown'),
                backgroundColor: result['status'] == 'selected' ? Colors.green[100] : Colors.red[100],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.indigo,
        title: Text(
          widget.companyName,
          style: const TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
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
                        onPressed: _fetchPlacementDetails,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                          shape: const StadiumBorder(),
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchPlacementDetails,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        CachedNetworkImage(
                          imageUrl: _placementDetails!['bannerImage'] ?? '',
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                          errorWidget: (context, url, error) => const Icon(Icons.error),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildCompanyDetails(),
                              if (widget.status == 'Ongoing' || widget.status == 'Completed')
                                _buildRoundsSection(),
                              if (widget.status == 'Completed')
                                _buildResultsSection(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}