import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'session_service.dart';

class DrivesService {
  static final SessionService _sessionService = SessionService();

  // Fetch Featured Placements
  static Future<List<Map<String, dynamic>>> fetchFeaturedPlacements() async {
    final session = await _sessionService.getSession();
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
        await _sessionService.clearSession();
        throw Exception(jsonDecode(response.body)['message']);
      }
    } catch (e) {
      print('DEBUG: Featured placements error: $e');
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // Fetch Ongoing Drives
  static Future<List<Map<String, dynamic>>> fetchOngoingDrives() async {
    final session = await _sessionService.getSession();
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
        await _sessionService.clearSession();
        throw Exception(jsonDecode(response.body)['message']);
      }
    } catch (e) {
      print('DEBUG: Ongoing drives error: $e');
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // Fetch Upcoming Drives
  static Future<List<Map<String, dynamic>>> fetchUpcomingDrives() async {
    final session = await _sessionService.getSession();
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
        await _sessionService.clearSession();
        throw Exception(jsonDecode(response.body)['message']);
      }
    } catch (e) {
      print('DEBUG: Upcoming drives error: $e');
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  // Fetch Completed Drives
  static Future<List<Map<String, dynamic>>> fetchCompletedDrives() async {
    final session = await _sessionService.getSession();
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
        await _sessionService.clearSession();
        throw Exception(jsonDecode(response.body)['message']);
      }
    } catch (e) {
      print('DEBUG: Completed drives error: $e');
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }
  
  // Additional drive-related methods can be added here
  // For example: applyForDrive, checkDriveStatus, etc.
}