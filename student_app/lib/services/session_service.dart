import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SessionService {
  static const String _tokenKey = 'jwt_token';
  static const String _usnKey = 'usn';

  // Save token and USN to SharedPreferences
  Future<void> saveSession(String token, String usn) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_usnKey, usn);
  }

  // Retrieve token and USN
  Future<Map<String, String?>> getSession() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'token': prefs.getString(_tokenKey),
      'usn': prefs.getString(_usnKey),
    };
  }

  // Clear session
  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_usnKey);
  }

  // Check session with backend
  Future<Map<String, dynamic>> checkSession() async {
    final session = await getSession();
    final token = session['token'];
    final usn = session['usn'];

    if (token == null || usn == null) {
      return {'isLoggedIn': false};
    }

    try {
      final response = await http.post(
        Uri.parse('${dotenv.env['API_URL']}/api/students/check-login-status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'usn': usn, 'token': token}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'isLoggedIn': true,
          'usn': data['usn'],
          'studentId': data['studentId'],
          'firstLogin': data['firstLogin'],
        };
      } else {
        return {'isLoggedIn': false};
      }
    } catch (e) {
      print('Session check error: $e');
      return {'isLoggedIn': false};
    }
  }
}