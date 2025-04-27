import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'session_service.dart';

class AuthService {
  final SessionService _sessionService = SessionService();

  // Check session with backend (for app startup)
  Future<Map<String, dynamic>> checkSession() async {
    return await _sessionService.checkSession();
  }

  // Check login status (for LoginScreen)
  Future<Map<String, dynamic>> checkLoginStatus(String usn) async {
    try {
      final token = await _sessionService.getToken();
      print('DEBUG: Check login status - Token: ${token != null ? '[HIDDEN]' : null}, USN: $usn, Token length: ${token?.length ?? 0}');

      final response = await http.post(
        Uri.parse('${dotenv.env['API_URL']}/api/students/check-login-status'),
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
        Uri.parse('${dotenv.env['API_URL']}/api/students/register'),
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
        Uri.parse('${dotenv.env['API_URL']}/api/students/login'),
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
        Uri.parse('${dotenv.env['API_URL']}/api/students/forgot-password'),
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
        Uri.parse('${dotenv.env['API_URL']}/api/students/verify-otp'),
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
        Uri.parse('${dotenv.env['API_URL']}/api/students/reset-password'),
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
}