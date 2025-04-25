import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // Save token and USN to SharedPreferences
  Future<void> _saveSession(String token, String usn) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
    await prefs.setString('usn', usn);
    print('DEBUG: Session saved - Token: [HIDDEN], USN: $usn, Token length: ${token.length}');
  }

  // Retrieve session
  Future<Map<String, String?>> _getSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    final usn = prefs.getString('usn');
    print('DEBUG: Retrieved session - Token: ${token != null ? '[HIDDEN]' : 'null'}, USN: $usn, Token length: ${token?.length}');
    return {'token': token, 'usn': usn};
  }

  // Clear session
  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('usn');
    print('DEBUG: Session cleared');
  }

  // Check session with backend (for app startup)
  Future<Map<String, dynamic>> checkSession() async {
    final session = await _getSession();
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
        await _clearSession();
        return {'isLoggedIn': false};
      }
    } catch (e) {
      print('DEBUG: Session check error: $e');
      await _clearSession();
      return {'isLoggedIn': false};
    }
  }

  // Check login status (for LoginScreen)
  Future<Map<String, dynamic>> checkLoginStatus(String usn) async {
    try {
      final response = await http.post(
        Uri.parse('${dotenv.env['API_URL']}/api/students/check-login-status'),
        headers: {'Content-Type': 'application/json'},
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
        await _saveSession(data['token'], data['usn']);
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

  // Fetch Student Profile
  Future<Map<String, dynamic>> fetchStudentProfile() async {
    final session = await _getSession();
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
      } else {
        print('DEBUG: Profile fetch failed: ${response.body}');
        await _clearSession();
        throw Exception(jsonDecode(response.body)['message']);
      }
    } catch (e) {
      print('DEBUG: Profile fetch error: $e');
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // Fetch Featured Placements
  Future<List<Map<String, dynamic>>> fetchFeaturedPlacements() async {
    final session = await _getSession();
    final token = session['token'];

    if (token == null) {
      print('DEBUG: No session for featured placements');
      throw Exception('Not logged in');
    }

    try {
      final response = await http.get(
        Uri.parse('${dotenv.env['API_URL']}/api/placements/featured'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('DEBUG: Featured placements response: ${response.statusCode}, ${response.body}');

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      } else {
        print('DEBUG: Featured placements failed: ${response.body}');
        await _clearSession();
        throw Exception(jsonDecode(response.body)['message']);
      }
    } catch (e) {
      print('DEBUG: Featured placements error: $e');
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // Fetch Ongoing Drives
  Future<List<Map<String, dynamic>>> fetchOngoingDrives() async {
    final session = await _getSession();
    final token = session['token'];

    if (token == null) {
      print('DEBUG: No session for ongoing drives');
      throw Exception('Not logged in');
    }

    try {
      final response = await http.get(
        Uri.parse('${dotenv.env['API_URL']}/api/placements/ongoing'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('DEBUG: Ongoing drives response: ${response.statusCode}, ${response.body}');

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      } else {
        print('DEBUG: Ongoing drives failed: ${response.body}');
        await _clearSession();
        throw Exception(jsonDecode(response.body)['message']);
      }
    } catch (e) {
      print('DEBUG: Ongoing drives error: $e');
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // Fetch Upcoming Drives
  Future<List<Map<String, dynamic>>> fetchUpcomingDrives() async {
    final session = await _getSession();
    final token = session['token'];

    if (token == null) {
      print('DEBUG: No session for upcoming drives');
      throw Exception('Not logged in');
    }

    try {
      final response = await http.get(
        Uri.parse('${dotenv.env['API_URL']}/api/placements/upcoming'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('DEBUG: Upcoming drives response: ${response.statusCode}, ${response.body}');

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      } else {
        print('DEBUG: Upcoming drives failed: ${response.body}');
        await _clearSession();
        throw Exception(jsonDecode(response.body)['message']);
      }
    } catch (e) {
      print('DEBUG: Upcoming drives error: $e');
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // Fetch Completed Drives
  Future<List<Map<String, dynamic>>> fetchCompletedDrives() async {
    final session = await _getSession();
    final token = session['token'];

    if (token == null) {
      print('DEBUG: No session for completed drives');
      throw Exception('Not logged in');
    }

    try {
      final response = await http.get(
        Uri.parse('${dotenv.env['API_URL']}/api/placements/completed'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('DEBUG: Completed drives response: ${response.statusCode}, ${response.body}');

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      } else {
        print('DEBUG: Completed drives failed: ${response.body}');
        await _clearSession();
        throw Exception(jsonDecode(response.body)['message']);
      }
    } catch (e) {
      print('DEBUG: Completed drives error: $e');
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // Logout
  Future<void> logout() async {
    await _clearSession();
    print('DEBUG: Logged out');
  }
}