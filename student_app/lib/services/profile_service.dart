import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'session_service.dart';

class ProfileService {
  static final SessionService _sessionService = SessionService();

  // Fetch Student Profile - static method for easier access
  static Future<Map<String, dynamic>> fetchStudentProfile() async {
    final session = await _sessionService.getSession();
    final token = session['token'];
    final usn = session['usn'];

    if (token == null || usn == null) {
      print('DEBUG: No session for profile fetch');
      throw Exception('Not logged in');
    }

    try {
      final response = await http.get(
        Uri.parse('${dotenv.env['API_URL']}/api/students/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('DEBUG: Profile fetch response: ${response.statusCode}, ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        print('DEBUG: Unauthorized profile fetch: ${response.body}');
        await _sessionService.clearSession();
        throw Exception('Unauthorized: Invalid or expired token');
      } else {
        print('DEBUG: Profile fetch failed: ${response.statusCode}, ${response.body}');
        throw Exception(jsonDecode(response.body)['message'] ?? 'Failed to fetch profile');
      }
    } catch (e) {
      print('DEBUG: Profile fetch error: $e');
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }
}