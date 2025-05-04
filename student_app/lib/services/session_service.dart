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

  // Retrieve USN
  Future<String?> getUsn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usn = prefs.getString('usn');
      print('DEBUG: Retrieved USN: $usn');
      return usn;
    } catch (e) {
      print('DEBUG: Error retrieving USN: $e');
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
}