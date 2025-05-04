import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'session_service.dart';

class QuestionBankService {
  static final SessionService _sessionService = SessionService();

  Future<List<dynamic>> fetchQuestionBanks() async {
    print('DEBUG: QuestionBankService: Starting fetchQuestionBanks');
    try {
      final session = await _sessionService.getSession();
      final token = session['token'];
      final usn = session['usn'];

      print('DEBUG: QuestionBankService: Retrieved session - Token: ${token != null ? '[HIDDEN]' : null}, USN: $usn, Token length: ${token?.length ?? 0}');

      if (token == null || usn == null) {
        print('DEBUG: QuestionBankService: No session found');
        throw Exception('Not logged in');
      }

      final requestUrl = '${dotenv.env['API_URL']}/api/questionbank/question-banks';
      print('DEBUG: QuestionBankService: Preparing HTTP GET request to: $requestUrl');

      final response = await http.get(
        Uri.parse(requestUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('DEBUG: QuestionBankService: Received response - Status: ${response.statusCode}, Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('DEBUG: QuestionBankService: JSON decoded successfully, data length: ${data.length}');
        return data;
      } else {
        print('DEBUG: QuestionBankService: Request failed: ${response.body}');
        final errorMessage = jsonDecode(response.body)['message'] ?? 'Failed to fetch question banks';
        if (errorMessage == 'Invalid token') {
          print('DEBUG: QuestionBankService: Invalid token detected; clearing session');
          await _sessionService.clearSession();
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('DEBUG: QuestionBankService: Error during fetchQuestionBanks: $e');
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }
}