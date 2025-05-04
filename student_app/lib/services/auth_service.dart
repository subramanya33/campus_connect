import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'session_service.dart';

class AuthService {
  final SessionService _sessionService = SessionService();

  // Check session with backend (for app startup)
  Future<Map<String, dynamic>> checkSession() async {
    try {
      final session = await _sessionService.getSession();
      final token = session['token'];
      final usn = session['usn'];
      print('DEBUG: Check session - Token: ${token != null ? '[HIDDEN]' : null}, USN: $usn, Token length: ${token?.length ?? 0}');

      if (token == null || usn == null) {
        print('DEBUG: No session found');
        return {'isLoggedIn': false};
      }

      final response = await http.post(
        Uri.parse('${dotenv.env['API_URL']}/api/auth/check-login-status'),
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
          'firstLogin': data['firstLogin'] ?? false,
          'usn': data['usn'] ?? usn,
          'studentId': data['studentId'] ?? '',
        };
      } else if (jsonDecode(response.body)['message'] == 'Invalid token') {
        print('DEBUG: Invalid token detected; clearing session');
        await _sessionService.clearSession();
        return {'isLoggedIn': false};
      } else {
        print('DEBUG: Session check failed: ${response.statusCode}, ${response.body}');
        return {'isLoggedIn': false}; // Do not clear session
      }
    } catch (e) {
      print('DEBUG: Check session error: $e');
      return {'isLoggedIn': false}; // Do not clear session
    }
  }

  // Check login status (for LoginScreen)
  Future<Map<String, dynamic>> checkLoginStatus(String usn) async {
    try {
      final session = await _sessionService.getSession();
      final token = session['token'];
      print('DEBUG: Check login status - Token: ${token != null ? '[HIDDEN]' : null}, USN: $usn, Token length: ${token?.length ?? 0}');

      final response = await http.post(
        Uri.parse('${dotenv.env['API_URL']}/api/auth/check-login-status'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'usn': usn}),
      );

      print('DEBUG: Check login status response: ${response.statusCode}, ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'firstLogin': data['firstLogin'] ?? false,
          'usn': data['usn'] ?? usn,
          'studentId': data['studentId'] ?? '',
        };
      } else {
        throw Exception(jsonDecode(response.body)['message']);
      }
    } catch (e) {
      print('DEBUG: Check login status error: $e');
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // Register
  Future<void> register({
    required String firstName,
    required String lastName,
    String? middleName,
    required String usn,
    required String dob,
    required double tenthPercentage,
    double? twelfthPercentage,
    double? diplomaPercentage,
    required double currentCgpa,
    required int noOfBacklogs,
    required String phone,
    required String email,
    required String address,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${dotenv.env['API_URL']}/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'firstName': firstName,
          'middleName': middleName,
          'lastName': lastName,
          'usn': usn,
          'dob': dob,
          'tenthPercentage': tenthPercentage,
          'twelfthPercentage': twelfthPercentage,
          'diplomaPercentage': diplomaPercentage,
          'currentCgpa': currentCgpa,
          'noOfBacklogs': noOfBacklogs,
          'phone': phone,
          'email': email,
          'address': address,
          'password': password,
        }),
      );

      print('DEBUG: Register response: ${response.statusCode}, ${response.body}');

      if (response.statusCode == 201) {
        return;
      } else {
        throw Exception(jsonDecode(response.body)['message']);
      }
    } catch (e) {
      print('DEBUG: Register error: $e');
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // Login
  Future<void> login(String usn, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${dotenv.env['API_URL']}/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'usn': usn, 'password': password}),
      );

      print('DEBUG: Login response: ${response.statusCode}, ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _sessionService.saveSession(data['token'], data['usn']);
        final savedToken = await _sessionService.getToken();
        print('DEBUG: Session saved - Token: ${savedToken != null ? '[HIDDEN]' : null}, USN: ${data['usn']}, Token length: ${savedToken?.length ?? 0}');
        return;
      } else {
        throw Exception(jsonDecode(response.body)['message']);
      }
    } catch (e) {
      print('DEBUG: Login error: $e');
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // Request OTP
  Future<void> requestOtp(String usn, String email) async {
    try {
      final response = await http.post(
        Uri.parse('${dotenv.env['API_URL']}/api/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'usn': usn, 'email': email}),
      );

      print('DEBUG: Request OTP response: ${response.statusCode}, ${response.body}');

      if (response.statusCode == 200) {
        return;
      } else {
        throw Exception(jsonDecode(response.body)['message']);
      }
    } catch (e) {
      print('DEBUG: Request OTP error: $e');
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // Verify OTP
  Future<void> verifyOtp(String usn, String otp) async {
    try {
      final response = await http.post(
        Uri.parse('${dotenv.env['API_URL']}/api/auth/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'usn': usn, 'otp': otp}),
      );

      print('DEBUG: Verify OTP response: ${response.statusCode}, ${response.body}');

      if (response.statusCode == 200) {
        return;
      } else {
        throw Exception(jsonDecode(response.body)['message']);
      }
    } catch (e) {
      print('DEBUG: Verify OTP error: $e');
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // Reset Password
  Future<void> resetPassword(String usn, String newPassword) async {
    try {
      final response = await http.post(
        Uri.parse('${dotenv.env['API_URL']}/api/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'usn': usn, 'newPassword': newPassword}),
      );

      print('DEBUG: Reset password response: ${response.statusCode}, ${response.body}');

      if (response.statusCode == 200) {
        return;
      } else {
        throw Exception(jsonDecode(response.body)['message']);
      }
    } catch (e) {
      print('DEBUG: Reset password error: $e');
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // Logout
  Future<void> logout() async {
    await _sessionService.clearSession();
    print('DEBUG: Logged out');
  }

  // Fetch drives (generic method for placement APIs)
  Future<List<dynamic>> fetchDrives(String endpoint) async {
    try {
      final session = await _sessionService.getSession();
      final token = session['token'];
      final usn = session['usn'];
      print('DEBUG: Fetch drives - Endpoint: $endpoint, Token: ${token != null ? '[HIDDEN]' : null}, USN: $usn, Token length: ${token?.length ?? 0}');

      if (token == null || usn == null) {
        throw Exception('Not logged in');
      }

      final response = await http.get(
        Uri.parse('${dotenv.env['API_URL']}/api/placements/$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('DEBUG: $endpoint response: ${response.statusCode}, ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorMessage = jsonDecode(response.body)['message'];
        print('DEBUG: $endpoint failed: $errorMessage');
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('DEBUG: $endpoint error: $e');
      if (e.toString().contains('Invalid token')) {
        print('DEBUG: Invalid token detected in fetchDrives; clearing session');
        await _sessionService.clearSession();
      }
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }
}