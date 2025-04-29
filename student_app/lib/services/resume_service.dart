import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'session_service.dart';

class ResumeService {
  static final SessionService _sessionService = SessionService();

  static Future<void> saveResume({
    required String usn,
    required String format,
    required String data, // Changed to String for base64-encoded PDF
  }) async {
    final session = await _sessionService.getSession();
    final token = session['token'];

    if (token == null) {
      print('DEBUG: No session for resume save');
      throw Exception('Not logged in');
    }

    try {
      final response = await http.post(
        Uri.parse('${dotenv.env['API_URL']}/api/resumes'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'usn': usn,
          'format': format,
          'data': data, // Send base64 string
        }),
      );

      print('DEBUG: Resume save response: ${response.statusCode}, ${response.body}');

      if (response.statusCode == 201) {
        return;
      } else if (response.statusCode == 401) {
        print('DEBUG: Unauthorized resume save: ${response.body}');
        await _sessionService.clearSession();
        throw Exception('Unauthorized: Invalid or expired token');
      } else {
        print('DEBUG: Resume save failed: ${response.statusCode}, ${response.body}');
        throw Exception(jsonDecode(response.body)['message'] ?? 'Failed to save resume');
      }
    } catch (e) {
      print('DEBUG: Resume save error: $e');
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  static Future<Map<String, dynamic>> fetchResume() async {
    final session = await _sessionService.getSession();
    final token = session['token'];

    if (token == null) {
      print('DEBUG: No session for resume fetch');
      throw Exception('Not logged in');
    }

    try {
      final response = await http.get(
        Uri.parse('${dotenv.env['API_URL']}/api/resumes'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      print('DEBUG: Resume fetch response: ${response.statusCode}, ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        print('DEBUG: Unauthorized resume fetch: ${response.body}');
        await _sessionService.clearSession();
        throw Exception('Unauthorized: Invalid or expired token');
      } else if (response.statusCode == 404) {
        throw Exception('Resume not found');
      } else {
        print('DEBUG: Resume fetch failed: ${response.statusCode}, ${response.body}');
        throw Exception(jsonDecode(response.body)['message'] ?? 'Failed to fetch resume');
      }
    } catch (e) {
      print('DEBUG: Resume fetch error: $e');
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }
}