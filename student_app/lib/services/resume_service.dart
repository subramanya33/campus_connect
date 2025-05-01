import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'session_service.dart';
import 'dart:io';

class ResumeService {
  static final SessionService _sessionService = SessionService();

  static Future<void> saveResume({
    required String usn,
    required String format,
    required String data,
  }) async {
    final session = await _sessionService.getSession();
    final token = session['token'];

    if (token == null) {
      print('DEBUG: No session for resume save');
      throw Exception('Not logged in');
    }

    try {
      final response = await http.post(
        Uri.parse('${dotenv.env['API_URL']}/api/resumes'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'usn': usn,
          'format': format,
          'data': data,
        }),
      ).timeout(const Duration(seconds: 30), onTimeout: () {
        throw Exception('Request timed out');
      });

      print('DEBUG: Resume save response: ${response.statusCode}, ${response.body}');

      if (response.statusCode == 201) {
        return;
      } else if (response.statusCode == 401) {
        print('DEBUG: Unauthorized resume save: ${response.body}');
        await _sessionService.clearSession();
        throw Exception('Unauthorized: Invalid or expired token');
      } else if (response.statusCode == 413) {
        print('DEBUG: Payload too large: ${response.body}');
        throw Exception('File too large. Maximum size is 10MB.');
      } else {
        print('DEBUG: Resume save failed: ${response.statusCode}, ${response.body}');
        try {
          final error = jsonDecode(response.body)['message'] ?? 'Failed to save resume';
          throw Exception(error);
        } catch (e) {
          throw Exception('Failed to save resume: Server returned invalid response');
        }
      }
    } catch (e) {
      print('DEBUG: Resume save error: $e');
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  static Future<List<Map<String, dynamic>>> fetchResumes() async {
    final session = await _sessionService.getSession();
    final token = session['token'];

    if (token == null) {
      print('DEBUG: No session for resume fetch');
      throw Exception('Not logged in');
    }

    try {
      final response = await http.get(
        Uri.parse('${dotenv.env['API_URL']}/api/resumes'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 30), onTimeout: () {
        throw Exception('Request timed out');
      });

      print('DEBUG: Resume fetch response: ${response.statusCode}, ${response.body}');

      if (response.statusCode == 200) {
        final resumeList = jsonDecode(response.body);
        return (resumeList is List
                ? resumeList
                : [resumeList]).cast<Map<String, dynamic>>();
      } else if (response.statusCode == 401) {
        print('DEBUG: Unauthorized resume fetch: ${response.body}');
        await _sessionService.clearSession();
        throw Exception('Unauthorized: Invalid or expired token');
      } else if (response.statusCode == 404) {
        return [];
      } else {
        print('DEBUG: Resume fetch failed: ${response.statusCode}, ${response.body}');
        try {
          final error = jsonDecode(response.body)['message'] ?? 'Failed to fetch resumes';
          throw Exception(error);
        } catch (e) {
          throw Exception('Failed to fetch resumes: Server returned invalid response');
        }
      }
    } catch (e) {
      print('DEBUG: Resume fetch error: $e');
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  static Future<void> deleteResume(String id) async {
    final session = await _sessionService.getSession();
    final token = session['token'];

    if (token == null) {
      print('DEBUG: No session for resume delete');
      throw Exception('Not logged in');
    }

    try {
      final response = await http.delete(
        Uri.parse('${dotenv.env['API_URL']}/api/resumes/$id'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 30), onTimeout: () {
        throw Exception('Request timed out');
      });

      print('DEBUG: Resume delete response: ${response.statusCode}, ${response.body}');

      if (response.statusCode == 200) {
        return;
      } else if (response.statusCode == 401) {
        print('DEBUG: Unauthorized resume delete: ${response.body}');
        await _sessionService.clearSession();
        throw Exception('Unauthorized: Invalid or expired token');
      } else {
        print('DEBUG: Resume delete failed: ${response.statusCode}, ${response.body}');
        try {
          final error = jsonDecode(response.body)['message'] ?? 'Failed to delete resume';
          throw Exception(error);
        } catch (e) {
          throw Exception('Failed to delete resume: Server returned invalid response');
        }
      }
    } catch (e) {
      print('DEBUG: Resume delete error: $e');
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  static Future<void> uploadCustomResume({
    required String usn,
    required File pdfFile,
  }) async {
    try {
      // Validate file size
      final fileSize = await pdfFile.length();
      if (fileSize > 7.5 * 1024 * 1024) {
        throw Exception('File size exceeds 7.5MB limit');
      }

      print('DEBUG: Uploading file: ${pdfFile.path}, Size: ${fileSize / (1024 * 1024)} MB');

      // Read PDF file as bytes
      final bytes = await pdfFile.readAsBytes();
      // Calculate file hash
      final fileHash = md5.convert(bytes).toString();
      print('DEBUG: File hash: $fileHash');
      final base64Data = base64Encode(bytes);

      print('DEBUG: Base64 data length: ${base64Data.length}, First 100 chars: ${base64Data.substring(0, 100)}');

      await saveResume(
        usn: usn,
        format: 'custom',
        data: base64Data,
      );
    } catch (e) {
      print('DEBUG: Resume upload error: $e');
      throw Exception('Failed to upload resume: $e');
    }
  }
}