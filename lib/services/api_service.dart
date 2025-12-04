import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

/// API Service for codigocreativo.cloud
/// Base URL configurable desde ApiConfig
/// Documentation: https://api.codigocreativo.cloud/api/docs
class ApiService {
  static String get baseUrl => ApiConfig.apiBaseUrl;
  
  // Shared instance for token management
  static String? _sharedAuthToken;
  
  final http.Client _client;
  String? _authToken;
  
  ApiService({http.Client? client, String? authToken}) 
      : _client = client ?? http.Client(),
        _authToken = authToken ?? _sharedAuthToken;
  
  /// Set shared authentication token (affects all instances)
  static void setSharedAuthToken(String? token) {
    _sharedAuthToken = token;
  }
  
  /// Get shared authentication token
  static String? getSharedAuthToken() => _sharedAuthToken;
  
  /// Set authentication token (also updates shared token)
  void setAuthToken(String? token) {
    _authToken = token;
    _sharedAuthToken = token;
  }
  
  /// Get authentication headers
  Map<String, String> _getAuthHeaders() {
    final headers = <String, String>{};
    final token = _authToken ?? _sharedAuthToken;
    if (token != null) {
      // Remove "Bearer " prefix if token already includes it
      String cleanToken = token.trim();
      if (cleanToken.startsWith('Bearer ')) {
        cleanToken = cleanToken.substring(7); // Remove "Bearer " (7 characters)
        print('🔧 [ApiService] Removed "Bearer " prefix from token');
      }
      
      headers['Authorization'] = 'Bearer $cleanToken';
      print('🔑 [ApiService] Token found and added to headers');
      print('   Original token length: ${token.length}');
      print('   Clean token length: ${cleanToken.length}');
      print('   Token preview: ${cleanToken.length > 20 ? cleanToken.substring(0, 20) + "..." : cleanToken}');
      print('   Final Authorization header: Bearer ${cleanToken.length > 20 ? cleanToken.substring(0, 20) + "..." : cleanToken}');
    } else {
      print('⚠️ [ApiService] No token available - request will be unauthenticated');
    }
    return headers;
  }

  /// Generic GET request
  Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final url = baseUrl;
      print('🌐 [ApiService] GET request');
      print('   Base URL: $url');
      print('   Endpoint: $endpoint');
      print('   Query parameters: ${queryParameters ?? "none"}');
      Uri uri = Uri.parse('$url$endpoint');
      
      if (queryParameters != null && queryParameters.isNotEmpty) {
        final queryString = queryParameters.map((key, value) => MapEntry(key, value.toString()));
        print('   Query string map: $queryString');
        uri = uri.replace(queryParameters: queryString);
      }

      final fullUrl = uri.toString();
      print('   Full URL: $fullUrl');
      
      final authHeaders = _getAuthHeaders();
      print('   Auth headers: ${authHeaders.isNotEmpty ? "Bearer token present" : "No token"}');
      print('   Request headers: Content-Type, Accept, Authorization');
      
      final response = await _client.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          ...authHeaders,
          ...?headers,
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('   ⏱️ Request timeout after 30 seconds');
          throw ApiException('Request timeout', 408);
        },
      );

      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) {
        print('   ❌ ApiException rethrown: ${e.message}');
        rethrow;
      }
      print('   ❌ Network/Unknown error: $e');
      print('   Error type: ${e.runtimeType}');
      throw ApiException('Network error: ${e.toString()}', 0);
    }
  }

  /// Generic POST request
  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    try {
      final url = baseUrl;
      print('🌐 [ApiService] POST request');
      print('   Base URL: $url');
      print('   Endpoint: $endpoint');
      print('   Full URL: $url$endpoint');
      
      final authHeaders = _getAuthHeaders();
      final allHeaders = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        ...authHeaders,
        ...?headers,
      };
      
      print('   📋 Request headers:');
      allHeaders.forEach((key, value) {
        if (key == 'Authorization') {
          // Value already includes "Bearer " prefix, so just print it
          final authValue = value.toString();
          print('      $key: ${authValue.length > 30 ? authValue.substring(0, 30) + "..." : authValue}');
        } else {
          print('      $key: $value');
        }
      });
      
      if (body != null) {
        final bodyJson = jsonEncode(body);
        print('   📦 Request body: $bodyJson');
        print('   📦 Body length: ${bodyJson.length} bytes');
      } else {
        print('   📦 Request body: null');
      }
      
      final response = await _client.post(
        Uri.parse('$url$endpoint'),
        headers: allHeaders,
        body: body != null ? jsonEncode(body) : null,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('   ⏱️ Request timeout after 30 seconds');
          throw ApiException('Request timeout', 408);
        },
      );

      print('   ✅ Response received');
      print('   Status code: ${response.statusCode}');
      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) {
        print('   ❌ ApiException: ${e.message}');
        rethrow;
      }
      print('   ❌ Network/Unknown error: $e');
      throw ApiException('Network error: ${e.toString()}', 0);
    }
  }

  /// Generic PUT request
  Future<Map<String, dynamic>> put(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    try {
      final url = baseUrl;
      final response = await _client.put(
        Uri.parse('$url$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          ..._getAuthHeaders(),
          ...?headers,
        },
        body: body != null ? jsonEncode(body) : null,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw ApiException('Request timeout', 408);
        },
      );

      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: ${e.toString()}', 0);
    }
  }

  /// Generic PATCH request
  Future<Map<String, dynamic>> patch(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    try {
      final url = baseUrl;
      print('🌐 [ApiService] PATCH request');
      print('   Base URL: $url');
      print('   Endpoint: $endpoint');
      print('   Body: ${body ?? "none"}');
      final response = await _client.patch(
        Uri.parse('$url$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          ..._getAuthHeaders(),
          ...?headers,
        },
        body: body != null ? jsonEncode(body) : null,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('   ⏱️ Request timeout after 30 seconds');
          throw ApiException('Request timeout', 408);
        },
      );

      print('   ✅ Response received');
      print('   Status code: ${response.statusCode}');
      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) {
        print('   ❌ ApiException: ${e.message}');
        rethrow;
      }
      print('   ❌ Network/Unknown error: $e');
      throw ApiException('Network error: ${e.toString()}', 0);
    }
  }

  /// Generic DELETE request
  Future<Map<String, dynamic>> delete(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    try {
      final url = baseUrl;
      final response = await _client.delete(
        Uri.parse('$url$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          ..._getAuthHeaders(),
          ...?headers,
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw ApiException('Request timeout', 408);
        },
      );

      return _handleResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: ${e.toString()}', 0);
    }
  }

  /// Handle HTTP response
  /// Supports multiple response formats:
  /// - { data: ... }
  /// - { results: ... }
  /// - Direct array/object
  Map<String, dynamic> _handleResponse(http.Response response) {
    print('📡 [ApiService] Handling response');
    print('   Status code: ${response.statusCode}');
    print('   URL: ${response.request?.url}');
    print('   Headers: ${response.headers}');
    print('   Body length: ${response.body.length}');
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        print('   ✅ Empty response body, returning success');
        return {'success': true};
      }
      
      try {
        print('   Parsing JSON response...');
        final decoded = jsonDecode(response.body);
        print('   Decoded type: ${decoded.runtimeType}');
        
        // If response is already a Map, return it
        if (decoded is Map<String, dynamic>) {
          print('   ✅ Response is Map<String, dynamic>');
          print('   Keys: ${decoded.keys.take(10).toList()}...');
          return decoded;
        }
        
        // If response is a List, wrap it in a data field
        if (decoded is List) {
          print('   ✅ Response is List (${decoded.length} items), wrapping in data');
          return {'data': decoded};
        }
        
        // If decoded is a Map but not String-keyed, try to convert
        if (decoded is Map) {
          print('   ✅ Response is Map (not String-keyed), converting...');
          return Map<String, dynamic>.from(decoded.map((key, value) => 
            MapEntry(key.toString(), value)));
        }
        
        print('   ⚠️ Unknown decoded type, returning as string data');
        // Fallback: return as string data
        return {'data': response.body, 'success': true};
      } catch (e) {
        print('   ❌ JSON parse error: $e');
        print('   Body preview: ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}');
        // If response is not JSON, return as string
        return {'data': response.body, 'success': true};
      }
    } else {
      print('   ❌ Error response received');
      print('   Status code: ${response.statusCode}');
      print('   Body: ${response.body}');
      
      String errorMessage = 'Request failed';
      Map<String, dynamic>? errorDetails;
      
      try {
        final errorBody = jsonDecode(response.body);
        print('   Error body type: ${errorBody.runtimeType}');
        
        if (errorBody is Map<String, dynamic>) {
          errorDetails = errorBody;
          print('   Error keys: ${errorBody.keys.toList()}');
          
          // Handle message field - can be String or List
          final messageField = errorBody['message'];
          if (messageField is List) {
            // Join array of messages
            errorMessage = messageField.map((m) => m.toString()).join(', ');
            print('   Error message (array): $errorMessage');
          } else if (messageField is String) {
            errorMessage = messageField;
            print('   Error message (string): $errorMessage');
          } else {
            errorMessage = errorBody['error'] ?? 
                          errorBody['detail'] ??
                          errorBody['msg'] ??
                          errorMessage;
            print('   Error message extracted: $errorMessage');
          }
        } else if (errorBody is String) {
          errorMessage = errorBody;
          print('   Error message (string): $errorMessage');
        } else if (errorBody is List) {
          // Error body is directly a list
          errorMessage = errorBody.map((m) => m.toString()).join(', ');
          print('   Error message (list): $errorMessage');
        }
      } catch (e) {
        print('   ⚠️ Could not parse error body as JSON: $e');
        errorMessage = response.body.isNotEmpty 
            ? response.body 
            : 'HTTP ${response.statusCode}';
        print('   Using raw body as error message');
      }
      
      print('   🚨 Throwing ApiException: $errorMessage (${response.statusCode})');
      throw ApiException(errorMessage, response.statusCode, details: errorDetails);
    }
  }

  void dispose() {
    _client.close();
  }
}

/// Custom exception for API errors
class ApiException implements Exception {
  final String message;
  final int statusCode;
  final Map<String, dynamic>? details;

  ApiException(this.message, this.statusCode, {this.details});

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
  
  /// Check if error is due to authentication
  bool get isUnauthorized => statusCode == 401 || statusCode == 403;
  
  /// Check if error is due to not found
  bool get isNotFound => statusCode == 404;
  
  /// Check if error is due to server error
  bool get isServerError => statusCode >= 500;
}

