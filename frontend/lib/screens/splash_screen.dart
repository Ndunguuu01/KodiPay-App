import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:local_auth/local_auth.dart';
import '../providers/auth_provider.dart';
import 'landlord_dashboard.dart';
import 'tenant_dashboard.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToLogin();
  }

  _navigateToLogin() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');
    final userRole = prefs.getString('userRole');

    if (token != null && userRole != null) {
      // Check for biometrics
      final LocalAuthentication auth = LocalAuthentication();
      bool canCheckBiometrics = false;
      try {
        canCheckBiometrics = await auth.canCheckBiometrics || await auth.isDeviceSupported();
      } catch (e) {
        canCheckBiometrics = false;
      }

      bool authenticated = false;
      if (canCheckBiometrics) {
        try {
          authenticated = await auth.authenticate(
            localizedReason: 'Please authenticate to access KodiPay',
            options: const AuthenticationOptions(
              stickyAuth: true,
              biometricOnly: true,
            ),
          );
        } catch (e) {
          authenticated = false;
        }
      } else {
        // If no biometrics supported, maybe just proceed or ask for login?
        // User request specifically mentioned "ask for finger print first".
        // If not supported, we'll assume we should verify session or just go to login.
        // Let's assume if not supported, we just verify session (auto-login).
        authenticated = true; 
      }

      if (authenticated) {
        // Restore session
        if (!mounted) return;
        Provider.of<AuthProvider>(context, listen: false).tryAutoLogin().then((success) {
          if (success && mounted) {
            if (userRole == 'landlord') {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LandlordDashboard()),
              );
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const TenantDashboard()),
              );
            }
          } else {
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            }
          }
        });
      } else {
        // Authentication failed or cancelled
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      }
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: AnimationConfiguration.toStaggeredList(
            duration: const Duration(milliseconds: 1000),
            childAnimationBuilder: (widget) => SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: widget,
              ),
            ),
            children: [
              ScaleAnimation(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.apartment_rounded,
                    size: 80,
                    color: AppConstants.primaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'KodiPay',
                style: GoogleFonts.poppins(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Premium Property Management',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.white70,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
