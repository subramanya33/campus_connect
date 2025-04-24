import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class AuthService {
  static String get _baseUrl => dotenv.env['API_URL'] ?? 'http://192.168.1.100:3000';

  Future<Map<String, dynamic>> checkLoginStatus(String usn, {String? token}) async {
    print('DEBUG: Checking login status for USN: $usn, Token provided: ${token != null}');
    try {
      final body = {'usn': usn.trim().toUpperCase()};
      if (token != null) {
        body['token'] = token;
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/api/students/check-login-status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      print('DEBUG: checkLoginStatus response: ${response.statusCode}, ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(jsonDecode(response.body)['message'] ?? 'Failed to check login status');
      }
    } catch (e) {
      print('DEBUG: Error in checkLoginStatus: $e');
      throw Exception('Error checking login status: $e');
    }
  }

  Future<Map<String, dynamic>> login(String usn, String password) async {
    print('DEBUG: Login attempt for USN: $usn, Password: [HIDDEN]');
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/students/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'usn': usn.trim().toUpperCase(), 'password': password.trim()}),
      );
      print('DEBUG: login response: ${response.statusCode}, ${response.body}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (!result['firstLogin']) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('usn', usn.trim().toUpperCase());
          await prefs.setString('session_token', result['token']);
          print('DEBUG: Session saved - USN: $usn, Token: ${result['token']}');
        }
        return result;
      } else {
        throw Exception(jsonDecode(response.body)['message'] ?? 'Invalid credentials');
      }
    } catch (e) {
      print('DEBUG: Error in login: $e');
      throw Exception('Error logging in: $e');
    }
  }

  Future<void> requestOtp(String usn, String email) async {
    print('DEBUG: Requesting OTP for USN: $usn, Email: $email');
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/students/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'usn': usn.trim().toUpperCase(), 'email': email.trim().toLowerCase()}),
      );
      print('DEBUG: requestOtp response: ${response.statusCode}, ${response.body}');

      if (response.statusCode != 200) {
        throw Exception(jsonDecode(response.body)['message'] ?? 'Failed to send OTP');
      }
    } catch (e) {
      print('DEBUG: Error in requestOtp: $e');
      throw Exception('Error requesting OTP: $e');
    }
  }

  Future<void> verifyOtp(String usn, String otp) async {
    print('DEBUG: Verifying OTP for USN: $usn, OTP: $otp');
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/students/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'usn': usn.trim().toUpperCase(), 'otp': otp.trim()}),
      );
      print('DEBUG: verifyOtp response: ${response.statusCode}, ${response.body}');

      if (response.statusCode != 200) {
        throw Exception(jsonDecode(response.body)['message'] ?? 'Invalid OTP');
      }
    } catch (e) {
      print('DEBUG: Error in verifyOtp: $e');
      throw Exception('Error verifying OTP: $e');
    }
  }

  Future<void> resetPassword(String usn, String newPassword) async {
    print('DEBUG: Resetting password for USN: $usn');
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/students/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'usn': usn.trim().toUpperCase(), 'newPassword': newPassword}),
      );
      print('DEBUG: resetPassword response: ${response.statusCode}, ${response.body}');

      if (response.statusCode != 200) {
        throw Exception(jsonDecode(response.body)['message'] ?? 'Failed to reset password');
      }
    } catch (e) {
      print('DEBUG: Error in resetPassword: $e');
      throw Exception('Error resetting password: $e');
    }
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final usn = prefs.getString('usn');
    final sessionToken = prefs.getString('session_token');
    print('DEBUG: Checking session - USN: $usn, Token: $sessionToken');

    if (usn == null || sessionToken == null) {
      print('DEBUG: No session data found');
      return false;
    }

    try {
      await checkLoginStatus(usn, token: sessionToken);
      print('DEBUG: Session validated successfully');
      return true;
    } catch (e) {
      print('DEBUG: Session invalid or error: $e');
      await prefs.remove('usn');
      await prefs.remove('session_token');
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final usn = prefs.getString('usn');
    print('DEBUG: Logging out USN: $usn');
    await prefs.remove('usn');
    await prefs.remove('session_token');
    print('DEBUG: Session cleared');
  }

  Future<Map<String, dynamic>> fetchStudentProfile() async {
    print('DEBUG: Fetching student profile');
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionToken = prefs.getString('session_token');
      if (sessionToken == null) {
        throw Exception('No user logged in');
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/api/students/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $sessionToken',
        },
      );
      print('DEBUG: fetchStudentProfile response: ${response.statusCode}, ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(jsonDecode(response.body)['message'] ?? 'Failed to fetch student profile');
      }
    } catch (e) {
      print('DEBUG: Error in fetchStudentProfile: $e');
      throw Exception('Error fetching student profile: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchFeaturedPlacements() async {
    print('DEBUG: Fetching featured placements');
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionToken = prefs.getString('session_token');
      if (sessionToken == null) {
        throw Exception('No user logged in');
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/api/placements/featured'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $sessionToken',
        },
      );
      print('DEBUG: fetchFeaturedPlacements response: ${response.statusCode}, ${response.body}');

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      } else {
        throw Exception(jsonDecode(response.body)['message'] ?? 'Failed to fetch featured placements');
      }
    } catch (e) {
      print('DEBUG: Error in fetchFeaturedPlacements: $e');
      throw Exception('Error fetching featured placements: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchOngoingDrives() async {
    print('DEBUG: Fetching ongoing drives');
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionToken = prefs.getString('session_token');
      if (sessionToken == null) {
        throw Exception('No user logged in');
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/api/placements/ongoing'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $sessionToken',
        },
      );
      print('DEBUG: fetchOngoingDrives response: ${response.statusCode}, ${response.body}');

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      } else {
        throw Exception(jsonDecode(response.body)['message'] ?? 'Failed to fetch ongoing drives');
      }
    } catch (e) {
      print('DEBUG: Error in fetchOngoingDrives: $e');
      throw Exception('Error fetching ongoing drives: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchUpcomingDrives() async {
    print('DEBUG: Fetching upcoming drives');
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionToken = prefs.getString('session_token');
      if (sessionToken == null) {
        throw Exception('No user logged in');
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/api/placements/upcoming'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $sessionToken',
        },
      );
      print('DEBUG: fetchUpcomingDrives response: ${response.statusCode}, ${response.body}');

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      } else {
        throw Exception(jsonDecode(response.body)['message'] ?? 'Failed to fetch upcoming drives');
      }
    } catch (e) {
      print('DEBUG: Error in fetchUpcomingDrives: $e');
      throw Exception('Error fetching upcoming drives: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchCompletedDrives() async {
    print('DEBUG: Fetching completed drives');
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionToken = prefs.getString('session_token');
      if (sessionToken == null) {
        throw Exception('No user logged in');
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/api/placements/completed'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $sessionToken',
        },
      );
      print('DEBUG: fetchCompletedDrives response: ${response.statusCode}, ${response.body}');

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      } else {
        throw Exception(jsonDecode(response.body)['message'] ?? 'Failed to fetch completed drives');
      }
    } catch (e) {
      print('DEBUG: Error in fetchCompletedDrives: $e');
      throw Exception('Error fetching completed drives: $e');
    }
  }
}