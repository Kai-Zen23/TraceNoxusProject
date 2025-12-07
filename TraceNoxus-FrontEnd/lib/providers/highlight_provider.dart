import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/highlight_model.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import '../core/constants/app_constants.dart';
import '../services/auth_service.dart';

class HighlightProvider with ChangeNotifier {
  final String _baseUrl = '${AppConstants.baseUrl}/api';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final AuthService _authService = AuthService();

  List<HighlightModel> _highlights = [];
  bool _isLoading = false;

  List<HighlightModel> get highlights => _highlights;
  bool get isLoading => _isLoading;

  Future<String?> _getToken() async {
    return await _storage.read(key: 'token');
  }

  Future<http.Response> _authenticatedRequest(
    Future<http.Response> Function(String token) requestBuilder,
  ) async {
    String? token = await _getToken();
    var response = await requestBuilder(token ?? '');

    if (response.statusCode == 401) {
      // Token might be expired, try to refresh
      try {
        await _authService.refreshToken();
        token = await _getToken();
        if (token != null) {
          // Retry request with new token
          response = await requestBuilder(token);
        }
      } catch (e) {
        debugPrint('Token refresh failed: $e');
      }
    }
    return response;
  }

  // Wrapper for Multipart Request since it doesn't return http.Response initially
  Future<http.Response> _authenticatedMultipartRequest(
    Future<http.StreamedResponse> Function(String token) requestBuilder,
  ) async {
    String? token = await _getToken();
    var streamedResponse = await requestBuilder(token ?? '');
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 401) {
      try {
        await _authService.refreshToken();
        token = await _getToken();
        if (token != null) {
          streamedResponse = await requestBuilder(token);
          response = await http.Response.fromStream(streamedResponse);
        }
      } catch (e) {
        debugPrint('Token refresh failed: $e');
      }
    }
    return response;
  }

  Future<void> fetchHighlights() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _authenticatedRequest((token) {
        return http.get(
          Uri.parse('$_baseUrl/highlights/'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );
      });

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _highlights = data.map((json) => HighlightModel.fromJson(json)).toList();
      } else {
        debugPrint('Failed to fetch highlights: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('Error fetching highlights: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> uploadHighlight({
    File? videoFile,
    String? videoUrl,
    required String title,
    required String category,
  }) async {
    try {
      if (videoFile != null) {
        // Upload File
        final response = await _authenticatedMultipartRequest((token) async {
          var request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/highlights/'));
          request.headers.addAll({
            'Authorization': 'Bearer $token',
          });
          request.fields['title'] = title;
          request.fields['category'] = category;

          final mimeType = lookupMimeType(videoFile.path) ?? 'video/mp4';
          request.files.add(await http.MultipartFile.fromPath(
            'video_file',
            videoFile.path,
            contentType: MediaType.parse(mimeType),
          ));
          return request.send();
        });
        
        if (response.statusCode == 201) {
          await fetchHighlights();
          return null; // Success
        } else {
          debugPrint('Failed to upload highlight (file): ${response.body}');
          return 'Failed: ${response.body}';
        }
      } else if (videoUrl != null) {
        // Upload URL
        final response = await _authenticatedRequest((token) {
          return http.post(
            Uri.parse('$_baseUrl/highlights/'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: json.encode({
              'title': title,
              'category': category,
              'video_url': videoUrl,
            }),
          );
        });

        if (response.statusCode == 201) {
          await fetchHighlights();
          return null; // Success
        } else {
          debugPrint('Failed to upload highlight (url): ${response.body}');
          return 'Failed: ${response.statusCode} - ${response.body}';
        }
      }
      return 'No video provided via file or URL';
    } catch (e) {
      debugPrint('Error uploading highlight: $e');
      return 'Error: $e';
    }
  }

  Future<bool> deleteHighlight(int id) async {
    try {
      final response = await _authenticatedRequest((token) {
        return http.delete(
          Uri.parse('$_baseUrl/highlights/$id/'),
          headers: {
            'Authorization': 'Bearer $token',
          },
        );
      });

      if (response.statusCode == 204) {
        _highlights.removeWhere((item) => item.id == id);
        notifyListeners();
        return true;
      } else {
        debugPrint('Failed to delete highlight: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('Error deleting highlight: $e');
      return false;
    }
  }

  Future<bool> updateHighlight({
    required int id,
    String? title,
    String? category,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (title != null) body['title'] = title;
      if (category != null) body['category'] = category;

      final response = await _authenticatedRequest((token) {
        return http.patch(
          Uri.parse('$_baseUrl/highlights/$id/'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: json.encode(body),
        );
      });

      if (response.statusCode == 200) {
        final updated = HighlightModel.fromJson(json.decode(response.body));
        final index = _highlights.indexWhere((h) => h.id == id);
        if (index != -1) {
          _highlights[index] = updated;
          notifyListeners();
        }
        return true;
      } else {
        debugPrint('Failed to update highlight: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('Error updating highlight: $e');
      return false;
    }
  }
}
