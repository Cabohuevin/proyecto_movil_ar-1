import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

/// Authentication Service
class AuthService {
  final ApiService _apiService;
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  AuthService({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  /// Login with email and password
  /// According to API documentation: https://api.codigocreativo.cloud/api/docs
  /// Endpoint: POST /api/usuarios/auth
  /// Fields required: email and password
  Future<AuthResult> login(String email, String password) async {
    try {
      // Use the usuarios/auth endpoint with email and password
      final response = await _apiService.post(
        '/usuarios/auth',
        body: {
          'email': email,
          'password': password,
        },
      );

      // Debug: Print response to help diagnose
      print('Login response: $response');
      
      // Try different response formats
      String? token;
      Map<String, dynamic>? userData;

      // Format 1: Direct token at root level
      final tokenValue = response['userToken'] ??
                        response['token'] ?? 
                        response['access_token'] ?? 
                        response['auth_token'] ??
                        response['accessToken'] ??
                        response['authToken'];
      if (tokenValue != null) {
        token = tokenValue.toString();
        final userValue = response['user'] ?? response['usuario'] ?? response['data'];
        if (userValue != null && userValue is Map) {
          userData = userValue as Map<String, dynamic>;
        }
      }
      
      // Format 2: Nested in data
      if (token == null) {
        final dataValue = response['data'];
        if (dataValue != null) {
          if (dataValue is Map) {
            final data = dataValue as Map<String, dynamic>;
            final tokenInData = data['userToken'] ??
                               data['token'] ?? 
                               data['access_token'] ?? 
                               data['auth_token'] ??
                               data['accessToken'] ??
                               data['authToken'];
            if (tokenInData != null) {
              token = tokenInData.toString();
            }
            final userInData = data['user'] ?? data['usuario'];
            if (userInData != null && userInData is Map) {
              userData = userInData as Map<String, dynamic>;
            } else if (data.containsKey('id') || data.containsKey('id_usuario')) {
              userData = data;
            }
          } else if (dataValue is String) {
            token = dataValue.toString();
          }
        }
      }
      
      // Format 3: Check result field
      if (token == null) {
        final resultValue = response['result'];
        if (resultValue != null && resultValue is Map) {
          final result = resultValue as Map<String, dynamic>;
          final tokenInResult = result['userToken'] ??
                               result['token'] ?? 
                               result['access_token'] ?? 
                               result['auth_token'];
          if (tokenInResult != null) {
            token = tokenInResult.toString();
          }
          final userInResult = result['user'] ?? result['usuario'];
          if (userInResult != null && userInResult is Map) {
            userData = userInResult as Map<String, dynamic>;
          }
        }
      }
      
      // Format 4: Check success field with token
      if (token == null && response['success'] == true) {
        final tokenInResponse = response['userToken'] ??
                               response['token'] ?? 
                               response['access_token'] ?? 
                               response['auth_token'];
        if (tokenInResponse != null) {
          token = tokenInResponse.toString();
        }
      }

      if (token != null && token.isNotEmpty) {
        // Clean token - remove "Bearer " prefix if present
        String cleanToken = token.trim();
        if (cleanToken.startsWith('Bearer ')) {
          cleanToken = cleanToken.substring(7); // Remove "Bearer " (7 characters)
          print('🔧 [AuthService] Removed "Bearer " prefix from token before saving');
        }
        
        await _saveToken(cleanToken);
        if (userData != null) {
          await _saveUserData(userData);
        }
        print('🔑 [AuthService] Setting token in ApiService');
        print('   Original token length: ${token.length}');
        print('   Clean token length: ${cleanToken.length}');
        print('   Token preview: ${cleanToken.length > 20 ? cleanToken.substring(0, 20) + "..." : cleanToken}');
        _apiService.setAuthToken(cleanToken);
        ApiService.setSharedAuthToken(cleanToken);
        return AuthResult.success(token: cleanToken, userData: userData);
      }

      // If no token found, return detailed error with response structure
      print('Token not found in response. Response keys: ${response.keys.toList()}');
      print('Full response: ${response.toString()}');
      return AuthResult.failure('Token no encontrado en la respuesta del servidor. Respuesta recibida: ${response.toString()}');
    } on ApiException catch (e) {
      if (e.isUnauthorized) {
        return AuthResult.failure('Credenciales incorrectas. Verifica tu email/usuario y contraseña');
      }
      return AuthResult.failure(e.message);
    } catch (e) {
      return AuthResult.failure('Error de conexión: ${e.toString()}');
    }
  }

  /// Login with token (for refresh)
  Future<AuthResult> loginWithToken(String token) async {
    try {
      // Clean token - remove "Bearer " prefix if present
      String cleanToken = token.trim();
      if (cleanToken.startsWith('Bearer ')) {
        cleanToken = cleanToken.substring(7);
      }
      await _saveToken(cleanToken);
      _apiService.setAuthToken(cleanToken);
      ApiService.setSharedAuthToken(cleanToken);
      
      // Verify token is valid by making a test request
      final response = await _apiService.get('/auth/me');
      
      if (response['data'] != null || response['user'] != null) {
        final userDataRaw = response['data'] ?? response['user'];
        Map<String, dynamic>? userData;
        if (userDataRaw != null && userDataRaw is Map) {
          userData = userDataRaw as Map<String, dynamic>;
          await _saveUserData(userData);
        }
        return AuthResult.success(token: cleanToken, userData: userData);
      }
      
      return AuthResult.failure('Token inválido');
    } catch (e) {
      await _clearAuth();
      if (e is ApiException) {
        return AuthResult.failure(e.message);
      }
      return AuthResult.failure('Error de conexión: ${e.toString()}');
    }
  }

  /// Get stored token
  Future<String?> getStoredToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Get stored user data
  Future<Map<String, dynamic>?> getStoredUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    if (userJson != null) {
      try {
        return jsonDecode(userJson) as Map<String, dynamic>;
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await getStoredToken();
    if (token != null) {
      // Clean token - remove "Bearer " prefix if present
      String cleanToken = token.trim();
      if (cleanToken.startsWith('Bearer ')) {
        cleanToken = cleanToken.substring(7);
      }
      _apiService.setAuthToken(cleanToken);
      ApiService.setSharedAuthToken(cleanToken);
      return true;
    }
    return false;
  }

  /// Initialize authentication from stored token
  Future<bool> initializeAuth() async {
    final token = await getStoredToken();
    if (token != null) {
      // Clean token - remove "Bearer " prefix if present
      String cleanToken = token.trim();
      if (cleanToken.startsWith('Bearer ')) {
        cleanToken = cleanToken.substring(7);
      }
      _apiService.setAuthToken(cleanToken);
      ApiService.setSharedAuthToken(cleanToken);
      return true;
    }
    return false;
  }

  /// Logout
  Future<void> logout() async {
    try {
      await _apiService.post('/auth/logout');
    } catch (e) {
      // Ignore logout errors
    } finally {
      await _clearAuth();
    }
  }

  /// Save token to storage
  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  /// Save user data to storage
  Future<void> _saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(userData));
  }

  /// Clear authentication data
  Future<void> _clearAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    _apiService.setAuthToken(null);
    ApiService.setSharedAuthToken(null);
  }
}

/// Authentication result
class AuthResult {
  final bool success;
  final String? token;
  final Map<String, dynamic>? userData;
  final String? errorMessage;

  AuthResult._({
    required this.success,
    this.token,
    this.userData,
    this.errorMessage,
  });

  factory AuthResult.success({
    required String token,
    Map<String, dynamic>? userData,
  }) {
    return AuthResult._(
      success: true,
      token: token,
      userData: userData,
    );
  }

  factory AuthResult.failure(String errorMessage) {
    return AuthResult._(
      success: false,
      errorMessage: errorMessage,
    );
  }
}

