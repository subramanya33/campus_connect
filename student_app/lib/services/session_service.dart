import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  // Save token and USN to SharedPreferences
  Future<void> saveSession(String token, String usn) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
    await prefs.setString('usn', usn);
    print('DEBUG: Session saved - Token: [HIDDEN], USN: $usn, Token length: ${token.length}');
  }

  // Retrieve session
  Future<Map<String, String?>> getSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    final usn = prefs.getString('usn');
    print('DEBUG: Retrieved session - Token: ${token != null ? '[HIDDEN]' : 'null'}, USN: $usn, Token length: ${token?.length}');
    return {'token': token, 'usn': usn};
  }

  // Clear session
  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('usn');
    print('DEBUG: Session cleared');
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
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'usn': usn, 'token': token}),
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
      } else {
        print('DEBUG: Session invalid: ${response.body}');
        await clearSession();
        return {'isLoggedIn': false};
      }
    } catch (e) {
      print('DEBUG: Session check error: $e');
      await clearSession();
      return {'isLoggedIn': false};
    }
  }
}