import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import '../utils/secure_storage.dart';

/// AuthService using FlutterSecureStorage (AES-256) instead of SharedPreferences.
/// Tokens and session data are stored in the OS keychain, NOT plain SharedPreferences.
class AuthService {
  // ── LOGIN ──────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        await SecureStorage.saveSession(
          token: data['accessToken'],
          userId: data['id'],
          role: data['role'],
          name: data['name'],
        );
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Login failed'};
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error. Please try again.'
      };
    }
  }

  // ── GOOGLE SSO ─────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> googleLogin(String idToken) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/auth/google'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'idToken': idToken}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        await SecureStorage.saveSession(
          token: data['accessToken'],
          userId: data['id'],
          role: data['role'],
          name: data['name'],
        );
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Google login failed'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error. Please try again.'
      };
    }
  }

  // ── REGISTER ──────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
    String phone,
    String role,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'phone': phone,
          'role': role,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': 'Registration successful. Please log in.'
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Registration failed'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error. Please try again.'
      };
    }
  }

  // ── FORGOT PASSWORD ────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      await http.post(
        Uri.parse('${AppConstants.baseUrl}/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      // Always 200 (anti-enumeration) — safe to show generic message
      return {
        'success': true,
        'message': 'If that email is registered, a reset link has been sent.'
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error. Please try again.'
      };
    }
  }

  // ── RESET PASSWORD ─────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> resetPassword(
      String token, String newPassword) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'token': token, 'newPassword': newPassword}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Reset failed'};
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error. Please try again.'
      };
    }
  }

  // ── PROFILE OPS ────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> updateProfile(
    String name,
    String phone,
    String? profilePic,
  ) async {
    try {
      final token = await SecureStorage.getToken();
      final response = await http.put(
        Uri.parse('${AppConstants.baseUrl}/users/profile'),
        headers: {
          'Content-Type': 'application/json',
          'x-access-token': token ?? '',
        },
        body: jsonEncode(
            {'name': name, 'phone': phone, 'profile_pic': profilePic}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        await SecureStorage.saveUserName(name);
        return {'success': true, 'message': data['message']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Update failed'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error. Please try again.'
      };
    }
  }

  Future<Map<String, dynamic>> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    try {
      final token = await SecureStorage.getToken();
      final response = await http.put(
        Uri.parse('${AppConstants.baseUrl}/users/password'),
        headers: {
          'Content-Type': 'application/json',
          'x-access-token': token ?? '',
        },
        body: jsonEncode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Password change failed'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error. Please try again.'
      };
    }
  }

  // ── SESSION ────────────────────────────────────────────────────────────────
  Future<String?> getToken() => SecureStorage.getToken();

  Future<void> logout() => SecureStorage.clearSession();
}
