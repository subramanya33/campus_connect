import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'session_service.dart';

class DrivesService {
  static final SessionService sessionService = SessionService();

  // Apply for a Drive
  static Future<void> applyForDrive(String driveId, {String? resumeId}) async {
    final session = await sessionService.getSession();
    final token = session['token'];
    final usn = session['usn'];

    print('DEBUG: Apply for drive - DriveID: $driveId, Token: ${token != null ? '[HIDDEN]' : null}, USN: $usn, ResumeID: $resumeId');

    if (token == null || usn == null) {
      print('DEBUG: No session for apply drive');
      throw Exception('Not logged in');
    }

    try {
      final response = await http.post(
        Uri.parse('${dotenv.env['API_URL']}/api/students/apply/$driveId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(resumeId != null ? {'resumeId': resumeId} : {}),
      ).timeout(const Duration(seconds: 30), onTimeout: () {
        throw Exception('Request timed out');
      });

      print('DEBUG: Apply drive response: ${response.statusCode}, ${response.body}');

      if (response.statusCode == 200) {
        return;
      } else {
        print('DEBUG: Apply drive failed: ${response.body}');
        final errorMessage = jsonDecode(response.body)['message'] ?? 'Failed to apply';
        if (errorMessage == 'Invalid token') {
          print('DEBUG: Invalid token detected; clearing session');
          await sessionService.clearSession();
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('DEBUG: Apply drive error: $e');
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // Check Application Status
  static Future<bool> checkApplicationStatus(String driveId) async {
    final session = await sessionService.getSession();
    final token = session['token'];
    final usn = session['usn'];

    print('DEBUG: Check application status - DriveID: $driveId, Token: ${token != null ? '[HIDDEN]' : null}, USN: $usn');

    if (token == null || usn == null) {
      print('DEBUG: No session for application status');
      throw Exception('Not logged in');
    }

    try {
      final response = await http.get(
        Uri.parse('${dotenv.env['API_URL']}/api/placements/$driveId/application-status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 30), onTimeout: () {
        throw Exception('Request timed out');
      });

      print('DEBUG: Application status response: ${response.statusCode}, ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['hasApplied'] ?? false;
      } else {
        print('DEBUG: Application status failed: ${response.body}');
        final errorMessage = jsonDecode(response.body)['message'] ?? 'Failed to check application status';
        if (errorMessage == 'Invalid token') {
          print('DEBUG: Invalid token detected; clearing session');
          await sessionService.clearSession();
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('DEBUG: Application status error: $e');
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // Fetch Round Status
  static Future<Map<String, dynamic>> fetchRoundStatus(String driveId) async {
    final session = await sessionService.getSession();
    final token = session['token'];
    final usn = session['usn'];

    print('DEBUG: Fetch round status - DriveID: $driveId, Token: ${token != null ? '[HIDDEN]' : null}, USN: $usn');

    if (token == null || usn == null) {
      print('DEBUG: No session for round status');
      throw Exception('Not logged in');
    }

    try {
      final response = await http.get(
        Uri.parse('${dotenv.env['API_URL']}/api/placements/$driveId/round-status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 30), onTimeout: () {
        throw Exception('Request timed out');
      });

      print('DEBUG: Round status response: ${response.statusCode}, ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('DEBUG: Round status failed: ${response.body}');
        final errorMessage = jsonDecode(response.body)['message'] ?? 'Failed to fetch round status';
        if (errorMessage == 'Invalid token') {
          print('DEBUG: Invalid token detected; clearing session');
          await sessionService.clearSession();
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('DEBUG: Round status error: $e');
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // Fetch Shortlist Results
  static Future<List<dynamic>> fetchShortlistResults(String driveId) async {
    final session = await sessionService.getSession();
    final token = session['token'];
    final usn = session['usn'];

    print('DEBUG: Fetch shortlist results - DriveID: $driveId, Token: ${token != null ? '[HIDDEN]' : null}, USN: $usn');

    if (token == null || usn == null) {
      print('DEBUG: No session for shortlist results');
      throw Exception('Not logged in');
    }

    try {
      final response = await http.get(
        Uri.parse('${dotenv.env['API_URL']}/api/placements/$driveId/shortlist-results'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 30), onTimeout: () {
        throw Exception('Request timed out');
      });

      print('DEBUG: Shortlist results response: ${response.statusCode}, ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('DEBUG: Shortlist results failed: ${response.body}');
        final errorMessage = jsonDecode(response.body)['message'] ?? 'Failed to fetch shortlist results';
        if (errorMessage == 'Invalid token') {
          print('DEBUG: Invalid token detected; clearing session');
          await sessionService.clearSession();
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('DEBUG: Shortlist results error: $e');
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // Fetch Featured Placements
  static Future<List<Map<String, dynamic>>> fetchFeaturedPlacements() async {
    final session = await sessionService.getSession();
    final token = session['token'];
    final usn = session['usn'];

    print('DEBUG: Fetch featured placements - Token: ${token != null ? '[HIDDEN]' : null}, USN: $usn');

    if (token == null || usn == null) {
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
      ).timeout(const Duration(seconds: 30), onTimeout: () {
        throw Exception('Request timed out');
      });

      print('DEBUG: Featured placements response: ${response.statusCode}, ${response.body}');

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      } else {
        print('DEBUG: Featured placements failed: ${response.body}');
        final errorMessage = jsonDecode(response.body)['message'] ?? 'Failed to fetch featured placements';
        if (errorMessage == 'Invalid token') {
          print('DEBUG: Invalid token detected; clearing session');
          await sessionService.clearSession();
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('DEBUG: Featured placements error: $e');
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // Fetch Ongoing Drives
  static Future<List<Map<String, dynamic>>> fetchOngoingDrives() async {
    final session = await sessionService.getSession();
    final token = session['token'];
    final usn = session['usn'];

    print('DEBUG: Fetch ongoing drives - Token: ${token != null ? '[HIDDEN]' : null}, USN: $usn');

    if (token == null || usn == null) {
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
      ).timeout(const Duration(seconds: 30), onTimeout: () {
        throw Exception('Request timed out');
      });

      print('DEBUG: Ongoing drives response: ${response.statusCode}, ${response.body}');

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      } else {
        print('DEBUG: Ongoing drives failed: ${response.body}');
        final errorMessage = jsonDecode(response.body)['message'] ?? 'Failed to fetch ongoing drives';
        if (errorMessage == 'Invalid token') {
          print('DEBUG: Invalid token detected; clearing session');
          await sessionService.clearSession();
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('DEBUG: Ongoing drives error: $e');
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // Fetch Upcoming Drives
  static Future<List<Map<String, dynamic>>> fetchUpcomingDrives() async {
    final session = await sessionService.getSession();
    final token = session['token'];
    final usn = session['usn'];

    print('DEBUG: Fetch upcoming drives - Token: ${token != null ? '[HIDDEN]' : null}, USN: $usn');

    if (token == null || usn == null) {
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
      ).timeout(const Duration(seconds: 30), onTimeout: () {
        throw Exception('Request timed out');
      });

      print('DEBUG: Upcoming drives response: ${response.statusCode}, ${response.body}');

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      } else {
        print('DEBUG: Upcoming drives failed: ${response.body}');
        final errorMessage = jsonDecode(response.body)['message'] ?? 'Failed to fetch upcoming drives';
        if (errorMessage == 'Invalid token') {
          print('DEBUG: Invalid token detected; clearing session');
          await sessionService.clearSession();
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('DEBUG: Upcoming drives error: $e');
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // Fetch Completed Drives
  static Future<List<Map<String, dynamic>>> fetchCompletedDrives() async {
    final session = await sessionService.getSession();
    final token = session['token'];
    final usn = session['usn'];

    print('DEBUG: Fetch completed drives - Token: ${token != null ? '[HIDDEN]' : null}, USN: $usn');

    if (token == null || usn == null) {
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
      ).timeout(const Duration(seconds: 30), onTimeout: () {
        throw Exception('Request timed out');
      });

      print('DEBUG: Completed drives response: ${response.statusCode}, ${response.body}');

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      } else {
        print('DEBUG: Completed drives failed: ${response.body}');
        final errorMessage = jsonDecode(response.body)['message'] ?? 'Failed to fetch completed drives';
        if (errorMessage == 'Invalid token') {
          print('DEBUG: Invalid token detected; clearing session');
          await sessionService.clearSession();
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('DEBUG: Completed drives error: $e');
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }
}