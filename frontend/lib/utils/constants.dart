import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppConstants {
  // API URL
  static const String baseUrl = kReleaseMode 
      ? 'https://kodipay-app.onrender.com/api' 
      : 'https://kodipay-app.onrender.com/api'; // Using live backend for testing
  
  // Colors - Premium Theme
  static const Color primaryColor = Color(0xFF1A237E); // Deep Navy Blue
  static const Color secondaryColor = Color(0xFFFFA000); // Amber/Gold
  static const Color backgroundColor = Color(0xFFF8F9FA); // Off-white
  static const Color textColor = Color(0xFF212121); // Dark Grey
  static const Color errorColor = Color(0xFFD32F2F);
}
