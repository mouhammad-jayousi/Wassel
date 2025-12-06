import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Check if user is authenticated
      if (authProvider.isAuthenticated) {
        // User is logged in
        if (!authProvider.hasSeenOnboarding) {
          // Show onboarding first time after login
          Navigator.pushReplacementNamed(context, AppRouter.onboarding);
        } else {
          // User has seen onboarding, go to home
          Navigator.pushReplacementNamed(context, AppRouter.home);
        }
      } else {
        // User not logged in, show sign in
        Navigator.pushReplacementNamed(context, AppRouter.signIn);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.34, 1.0],
            colors: [
              Color(0xFF000000), // Black at top
              Color(0xFF000000), // Black until 34%
              Color(0xFFDA015C), // Pink at bottom
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Wassel Widget
                SizedBox(
                  width: 160,
                  height: 160,
                  child: Image.asset(
                    'assets/images/wassel_widget.png',
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                ),
                
                const SizedBox(height: 60),
                
                // Loading Indicator
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
