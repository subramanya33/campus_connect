import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class QuestionBankService {
  static const String baseUrl = 'http://192.168.1.101:3000/api/questionbank'; // Update for emulator if needed

  Future<List<dynamic>> fetchQuestionBanks() async {
    print('DEBUG: QuestionBankService: Starting fetchQuestionBanks');
    try {
      // Retrieve session data
      print('DEBUG: QuestionBankService: Retrieving SharedPreferences');
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      final usn = prefs.getString('usn');

      print('DEBUG: QuestionBankService: Retrieved session - Token: ${token != null ? '[HIDDEN]' : null}, USN: $usn, Token length: ${token?.length ?? 0}');

      // Validate session
      if (token == null || usn == null) {
        print('DEBUG: QuestionBankService: No token or USN found in SharedPreferences');
        throw Exception('No token found');
      }

      // Prepare request
      final requestUrl = '$baseUrl/question-banks';
      print('DEBUG: QuestionBankService: Preparing HTTP GET request to: $requestUrl');
      print('DEBUG: QuestionBankService: Request headers: Content-Type: application/json, Authorization: Bearer [HIDDEN]');

      // Send request
      final response = await http.get(
        Uri.parse(requestUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      // Log response
      print('DEBUG: QuestionBankService: Received response - Status: ${response.statusCode}, Body: ${response.body}');

      // Handle response
      if (response.statusCode == 200) {
        print('DEBUG: QuestionBankService: Response successful, decoding JSON');
        try {
          final data = jsonDecode(response.body);
          print('DEBUG: QuestionBankService: JSON decoded successfully, data length: ${data.length}');
          return data;
        } catch (e) {
          print('DEBUG: QuestionBankService: JSON decode error: $e');
          throw Exception('Failed to decode response: $e');
        }
      } else if (response.statusCode == 401) {
        print('DEBUG: QuestionBankService: Unauthorized request (401): ${response.body}');
        throw Exception('Unauthorized: Invalid or expired token');
      } else {
        print('DEBUG: QuestionBankService: Request failed with status: ${response.statusCode}, Body: ${response.body}');
        throw Exception('Failed to fetch question banks: ${response.body}');
      }
    } catch (e) {
      print('DEBUG: QuestionBankService: Error during fetchQuestionBanks: $e');
      throw Exception('Error fetching question banks: $e');
    }
  }
}