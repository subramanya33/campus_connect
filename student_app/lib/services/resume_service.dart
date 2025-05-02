import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'session_service.dart';

class ResumeService {
  static final SessionService _sessionService = SessionService();

  static Future<Map<String, dynamic>> saveResume({
    required String usn,
    required String pdfData,
    required String originalFileName,
  }) async {
    final session = await _sessionService.getSession();
    final token = session['token'];

    if (token == null) {
      print('DEBUG: No session for resume save');
      throw Exception('Not logged in');
    }

    try {
      print('DEBUG: Sending resume data: usn=$usn, originalFileName=$originalFileName, pdfDataLength=${pdfData.length}');
      final response = await http.post(
        Uri.parse('${dotenv.env['API_URL']}/api/resume/custom'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'usn': usn,
          'pdfData': pdfData,
          'originalFileName': originalFileName,
        }),
      ).timeout(const Duration(seconds: 30), onTimeout: () {
        throw Exception('Request timed out');
      });

      print('DEBUG: Resume save response: ${response.statusCode}, ${response.body}');

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        print('DEBUG: Unauthorized resume save: ${response.body}');
        await _sessionService.clearSession();
        throw Exception('Unauthorized: Invalid or expired token');
      } else if (response.statusCode == 413) {
        print('DEBUG: Payload too large: ${response.body}');
        throw Exception('File too large. Maximum size is 7.5MB.');
      } else if (response.statusCode == 400) {
        print('DEBUG: Bad request: ${response.body}');
        try {
          final error = jsonDecode(response.body)['message'] ?? 'Invalid request';
          throw Exception(error);
        } catch (e) {
          throw Exception('Invalid request: ${response.body}');
        }
      } else if (response.statusCode == 403) {
        print('DEBUG: Resume limit exceeded: ${response.body}');
        throw Exception('Resume limit reached. Please delete an existing resume.');
      } else {
        print('DEBUG: Resume save failed: ${response.statusCode}, ${response.body}');
        try {
          final error = jsonDecode(response.body)['message'] ?? 'Failed to save resume';
          throw Exception(error);
        } catch (e) {
          throw Exception('Failed to save resume: ${response.body}');
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
        Uri.parse('${dotenv.env['API_URL']}/api/resume'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 30), onTimeout: () {
        throw Exception('Request timed out');
      });

      print('DEBUG: Resumes fetch response: ${response.statusCode}, ${response.body}');

      if (response.statusCode == 200) {
        final resumeList = jsonDecode(response.body);
        return (resumeList is List ? resumeList : [resumeList]).cast<Map<String, dynamic>>();
      } else if (response.statusCode == 401) {
        print('DEBUG: Unauthorized resume fetch: ${response.body}');
        await _sessionService.clearSession();
        throw Exception('Unauthorized: Invalid or expired token');
      } else if (response.statusCode == 404) {
        print('DEBUG: No resumes found: ${response.body}');
        return [];
      } else {
        print('DEBUG: Resume fetch failed: ${response.statusCode}, ${response.body}');
        try {
          final error = jsonDecode(response.body)['message'] ?? 'Failed to fetch resumes';
          throw Exception(error);
        } catch (e) {
          throw Exception('Failed to fetch resumes: ${response.body}');
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
        Uri.parse('${dotenv.env['API_URL']}/api/resume/$id'),
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
      } else if (response.statusCode == 404) {
        print('DEBUG: Resume not found: ${response.body}');
        throw Exception('Resume not found');
      } else {
        print('DEBUG: Resume delete failed: ${response.statusCode}, ${response.body}');
        try {
          final error = jsonDecode(response.body)['message'] ?? 'Failed to delete resume';
          throw Exception(error);
        } catch (e) {
          throw Exception('Failed to delete resume: ${response.body}');
        }
      }
    } catch (e) {
      print('DEBUG: Resume delete error: $e');
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  static Future<Map<String, dynamic>> setActiveResume(String id) async {
    final session = await _sessionService.getSession();
    final token = session['token'];

    if (token == null) {
      print('DEBUG: No session for setting active resume');
      throw Exception('Not logged in');
    }

    try {
      final response = await http.put(
        Uri.parse('${dotenv.env['API_URL']}/api/resume/$id/active'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30), onTimeout: () {
        throw Exception('Request timed out');
      });

      print('DEBUG: Set active resume response: ${response.statusCode}, ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        print('DEBUG: Unauthorized set active resume: ${response.body}');
        await _sessionService.clearSession();
        throw Exception('Unauthorized: Invalid or expired token');
      } else if (response.statusCode == 404) {
        print('DEBUG: Resume not found: ${response.body}');
        throw Exception('Resume not found');
      } else {
        print('DEBUG: Set active resume failed: ${response.statusCode}, ${response.body}');
        try {
          final error = jsonDecode(response.body)['message'] ?? 'Failed to set active resume';
          throw Exception(error);
        } catch (e) {
          throw Exception('Failed to set active resume: ${response.body}');
        }
      }
    } catch (e) {
      print('DEBUG: Set active resume error: $e');
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  static Future<Map<String, dynamic>> uploadCustomResume({
    required String usn,
    required String pdfData,
    required String originalFileName,
  }) async {
    try {
      // Validate base64 data
      if (pdfData.isEmpty) {
        throw Exception('PDF data is empty');
      }

      // Validate file size (approximate, since base64 inflates size by ~33%)
      final approximateByteSize = (pdfData.length * 3 / 4).round();
      if (approximateByteSize > 7.5 * 1024 * 1024) {
        throw Exception('File size exceeds 7.5MB limit');
      }

      print('DEBUG: Uploading resume: usn=$usn, originalFileName=$originalFileName, pdfDataLength=${pdfData.length}');

      // Strip MIME type prefix if present
      String cleanedPdfData = pdfData;
      if (pdfData.startsWith('data:application/pdf;base64,')) {
        cleanedPdfData = pdfData.replaceFirst('data:application/pdf;base64,', '');
      }
      print('DEBUG: Cleaned pdfData length: ${cleanedPdfData.length}');

      // Validate base64 format
      try {
        base64Decode(cleanedPdfData);
      } catch (e) {
        print('DEBUG: Invalid base64 format: $e');
        throw Exception('Invalid base64 format: $e');
      }

      // Calculate file hash
      final bytes = base64Decode(cleanedPdfData);
      final fileHash = md5.convert(bytes).toString();
      print('DEBUG: File hash: $fileHash');

      final resumeData = await saveResume(
        usn: usn,
        pdfData: pdfData, // Send original pdfData with MIME prefix
        originalFileName: originalFileName,
      );

      print('DEBUG: Resume upload successful: ${resumeData['resume']['_id']}');
      return resumeData;
    } catch (e) {
      print('DEBUG: Resume upload error: $e');
      throw Exception('Failed to upload resume: $e');
    }
  }
}