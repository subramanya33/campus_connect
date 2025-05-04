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

    print('DEBUG: Fetch profile - Token: ${token != null ? '[HIDDEN]' : null}, USN: $usn, Token length: ${token?.length ?? 0}');

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
      ).timeout(const Duration(seconds: 30), onTimeout: () {
        throw Exception('Request timed out');
      });

      print('DEBUG: Profile fetch response: ${response.statusCode}, ${response.body}');

      if (response.statusCode == 200) {
        final profile = jsonDecode(response.body);
        // Combine firstName and lastName into fullName for compatibility
        if (profile['firstName'] != null && profile['lastName'] != null) {
          profile['fullName'] = '${profile['firstName']} ${profile['lastName']}';
        }
        return profile;
      } else {
        print('DEBUG: Profile fetch failed: ${response.body}');
        final errorMessage = jsonDecode(response.body)['message'] ?? 'Failed to fetch profile';
        if (errorMessage == 'Invalid token') {
          print('DEBUG: Invalid token detected; clearing session');
          await _sessionService.clearSession();
        }
        throw Exception(errorMessage);
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

    print('DEBUG: Fetch resumes - Token: ${token != null ? '[HIDDEN]' : null}, USN: $usn, Token length: ${token?.length ?? 0}');

    if (token == null || usn == null) {
      print('DEBUG: No session for resumes fetch');
      throw Exception('Not logged in');
    }

    try {
      final response = await http.get(
        Uri.parse('${dotenv.env['API_URL']}/api/resume'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 30), onTimeout: () {
        throw Exception('Request timed out');
      });

      print('DEBUG: Resumes fetch response: ${response.statusCode}, ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        } else if (data is Map<String, dynamic>) {
          return [data];
        } else {
          return [];
        }
      } else if (response.statusCode == 404) {
        print('DEBUG: No resumes found: ${response.body}');
        return [];
      } else {
        print('DEBUG: Resumes fetch failed: ${response.body}');
        final errorMessage = jsonDecode(response.body)['message'] ?? 'Failed to fetch resumes';
        if (errorMessage == 'Invalid token') {
          print('DEBUG: Invalid token detected; clearing session');
          await _sessionService.clearSession();
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('DEBUG: Resumes fetch error: $e');
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }
}