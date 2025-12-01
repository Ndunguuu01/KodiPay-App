import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String? _errorMessage;
  String? _userName;
  int? _userId;
  String? _userRole;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get userName => _userName;
  int? get userId => _userId;
  String? get userRole => _userRole;

  Future<bool> tryAutoLogin() async {
    await loadUser();
    return _userId != null;
  }

  Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    _userName = prefs.getString('userName');
    _userId = prefs.getInt('userId');
    _userRole = prefs.getString('userRole');
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _authService.login(email, password);

    _isLoading = false;
    if (result['success']) {
      await loadUser();
      notifyListeners();
      return true;
    } else {
      _errorMessage = result['message'];
      notifyListeners();
      return false;
    }
  }

  Future<bool> googleLogin(String idToken) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _authService.googleLogin(idToken);

    _isLoading = false;
    if (result['success']) {
      await loadUser();
      notifyListeners();
      return true;
    } else {
      _errorMessage = result['message'];
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String name, String email, String password, String phone, String role) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _authService.register(name, email, password, phone, role);

    _isLoading = false;
    if (result['success']) {
      notifyListeners();
      return true;
    } else {
      _errorMessage = result['message'];
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProfile(String name, String phone, String? profilePic) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _authService.updateProfile(name, phone, profilePic);

    _isLoading = false;
    if (result['success']) {
      _userName = name;
      // Also update shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userName', name);
      notifyListeners();
      return true;
    } else {
      _errorMessage = result['message'];
      notifyListeners();
      return false;
    }
  }

  Future<bool> changePassword(String currentPassword, String newPassword) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _authService.changePassword(currentPassword, newPassword);

    _isLoading = false;
    if (result['success']) {
      notifyListeners();
      return true;
    } else {
      _errorMessage = result['message'];
      notifyListeners();
      return false;
    }
  }

  void logout() {
    _authService.logout();
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
