import 'package:flutter/material.dart';
import '../services/questionbank_service.dart';
import '../services/profile_service.dart';
import '../widgets/custom_drawer.dart';

class QuestionBanksScreen extends StatefulWidget {
  const QuestionBanksScreen({super.key});

  @override
  _QuestionBanksScreenState createState() => _QuestionBanksScreenState();
}

class _QuestionBanksScreenState extends State<QuestionBanksScreen> {
  List<Map<String, dynamic>> _questionBanks = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String _fullName = '';
  String _usn = '';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    print('DEBUG: QuestionBanksScreen initialized');
    _fetchProfile();
    _fetchQuestionBanks();
  }

  Future<void> _fetchProfile() async {
    try {
      final profile = await ProfileService.fetchStudentProfile();
      setState(() {
        _fullName = profile['fullName'] ?? '';
        _usn = profile['usn'] ?? '';
      });
      print('DEBUG: Profile loaded - Full Name: $_fullName, USN: $_usn');
    } catch (e) {
      print('DEBUG: Error fetching profile: $e');
    }
  }

  Future<void> _fetchQuestionBanks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final questionBanks = await QuestionBankService().fetchQuestionBanks();
      setState(() {
        _questionBanks = questionBanks.cast<Map<String, dynamic>>();
        _isLoading = false;
      });
      print('DEBUG: Question banks loaded: ${_questionBanks.length} categories');
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().contains('Connection refused')
            ? 'Cannot connect to server. Please check your network or try again later.'
            : e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
      print('DEBUG: Error fetching question banks: $e');
    }
  }

  void _showQuestionsDialog(BuildContext context, String companyName, List<Map<String, dynamic>> questions) {
    final groupedQuestions = <String, List<Map<String, dynamic>>>{};
    for (var q in questions) {
      final year = q['year'] ?? 'Unknown';
      groupedQuestions.putIfAbsent(year, () => []).add(q);
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '$companyName Questions',
          style: const TextStyle(
            color: Colors.indigo,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: groupedQuestions.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'No questions available',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: groupedQuestions.keys.length,
                  itemBuilder: (context, index) {
                    final year = groupedQuestions.keys.elementAt(index);
                    final yearQuestions = groupedQuestions[year]!;
                    return ExpansionTile(
                      title: Text(
                        year,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.indigo,
                        ),
                      ),
                      children: yearQuestions.map((q) {
                        return ListTile(
                          title: Text(
                            q['question'] ?? 'No question',
                            style: const TextStyle(fontSize: 16),
                          ),
                          subtitle: Text(
                            q['answer'] ?? 'No answer',
                            style: const TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        );
                      }).toList(),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(color: Colors.indigo, fontSize: 16),
            ),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'aptitude test':
        return Icons.calculate;
      case 'technical round':
        return Icons.code;
      case 'hr round':
        return Icons.people;
      case 'managerial round':
        return Icons.business_center;
      case 'group discussion':
        return Icons.group;
      case 'coding round':
        return Icons.computer;
      default:
        return Icons.question_answer;
    }
  }

  Widget _buildCategorySection(Map<String, dynamic> category) {
    final companies = (category['companies'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ExpansionTile(
        title: Text(
          category['category'] ?? 'Unknown',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.indigo,
          ),
        ),
        leading: Icon(
          _getCategoryIcon(category['category'] ?? 'Unknown'),
          color: Colors.indigo,
          size: 28,
        ),
        backgroundColor: Colors.white,
        collapsedBackgroundColor: Colors.grey[100],
        childrenPadding: const EdgeInsets.all(16),
        children: companies.isNotEmpty
            ? companies.map((company) {
                return ListTile(
                  title: Text(
                    company['name'] ?? 'Unknown Company',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey,
                  ),
                  onTap: () {
                    final questions = (company['questions'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
                    print('DEBUG: Tapped company: ${company['name']}');
                    _showQuestionsDialog(context, company['name'], questions);
                  },
                );
              }).toList()
            : [
                const ListTile(
                  title: Text(
                    'No companies available',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
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
      appBar: AppBar(
        backgroundColor: Colors.indigo,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white, size: 28),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
            print('DEBUG: Hamburger menu tapped');
          },
        ),
        title: const Text(
          'Question Banks',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 4,
      ),
      drawer: CustomDrawer(fullName: _fullName, usn: _usn),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.indigo))
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchQuestionBanks,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text(
                          'Retry',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchQuestionBanks,
                  color: Colors.indigo,
                  child: SingleChildScrollView(
                    child: Column(
                      children: _questionBanks.isNotEmpty
                          ? _questionBanks.map((category) => _buildCategorySection(category)).toList()
                          : [
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.info_outline,
                                      size: 48,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No question banks available',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.grey[700],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Please check back later or contact support.',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                        fontWeight: FontWeight.w400,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
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