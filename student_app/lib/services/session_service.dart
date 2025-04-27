import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  // Save token and USN to SharedPreferences
  Future<void> saveSession(String token, String usn) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt_token', token);
      await prefs.setString('usn', usn);
      final savedToken = prefs.getString('jwt_token');
      print('DEBUG: Session saved - Token: ${savedToken != null ? '[HIDDEN]' : 'null'}, USN: $usn, Token length: ${savedToken?.length ?? 0}');
    } catch (e) {
      print('DEBUG: Error saving session: $e');
      throw Exception('Failed to save session: $e');
    }
  }

  // Retrieve session
  Future<Map<String, String?>> getSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      final usn = prefs.getString('usn');
      print('DEBUG: Retrieved session - Token: ${token != null ? '[HIDDEN]' : 'null'}, USN: $usn, Token length: ${token?.length ?? 0}');
      return {'token': token, 'usn': usn};
    } catch (e) {
      print('DEBUG: Error retrieving session: $e');
      return {'token': null, 'usn': null};
    }
  }

  // Retrieve token
  Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      print('DEBUG: Retrieved token - Token: ${token != null ? '[HIDDEN]' : 'null'}, Token length: ${token?.length ?? 0}');
      return token;
    } catch (e) {
      print('DEBUG: Error retrieving token: $e');
      return null;
    }
  }

  // Clear session
  Future<void> clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('jwt_token');
      await prefs.remove('usn');
      print('DEBUG: Session cleared');
    } catch (e) {
      print('DEBUG: Error clearing session: $e');
    }
  }

  // Check session with backend (for app startup)
  Future<Map<String, dynamic>> checkSession() async {
    final session = await getSession();
    final token = session['token'];
    final usn = session['usn'];

    if (token == null || usn == null) {
      print('DEBUG: No session found');
      return {'isLoggedIn': false};
    }

    try {
      final response = await http.post(
        Uri.parse('${dotenv.env['API_URL']}/api/students/check-login-status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'usn': usn}),
      );

      print('DEBUG: Check session response: ${response.statusCode}, ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'isLoggedIn': true,
          'usn': data['usn'],
          'studentId': data['studentId'],
          'firstLogin': data['firstLogin'],
        };
      } else if (response.statusCode == 401) {
        print('DEBUG: Session invalid (401): ${response.body}');
        await clearSession();
        return {'isLoggedIn': false};
      } else {
        print('DEBUG: Session check failed: ${response.statusCode}, ${response.body}');
        return {'isLoggedIn': false}; // Do not clear session on non-401 errors
      }
    } catch (e) {
      print('DEBUG: Session check error: $e');
      return {'isLoggedIn': false}; // Do not clear session on network errors
    }
  }
}