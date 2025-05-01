import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'session_service.dart';

class ProfileService {
  static final SessionService _sessionService = SessionService();

  // Fetch Student Profile
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
        Uri.parse('${dotenv.env['API_URL']}/api/profile'),
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

  // Fetch Resumes for the logged-in student
  static Future<List<Map<String, dynamic>>> fetchResumes() async {
    final session = await _sessionService.getSession();
    final token = session['token'];
    final usn = session['usn'];

    if (token == null || usn == null) {
      print('DEBUG: No session for resumes fetch');
      throw Exception('Not logged in');
    }

    try {
      final response = await http.get(
        Uri.parse('${dotenv.env['API_URL']}/api/resumes'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('DEBUG: Resumes fetch response: ${response.statusCode}, ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Handle single resume object or list
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        } else if (data is Map<String, dynamic>) {
          return [data];
        } else {
          return [];
        }
      } else if (response.statusCode == 401) {
        print('DEBUG: Unauthorized resumes fetch: ${response.body}');
        await _sessionService.clearSession();
        throw Exception('Unauthorized: Invalid or expired token');
      } else if (response.statusCode == 404) {
        print('DEBUG: No resumes found: ${response.body}');
        return []; // Return empty list if no resumes exist
      } else {
        print('DEBUG: Resumes fetch failed: ${response.statusCode}, ${response.body}');
        throw Exception(jsonDecode(response.body)['message'] ?? 'Failed to fetch resumes');
      }
    } catch (e) {
      print('DEBUG: Resumes fetch error: $e');
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }
}