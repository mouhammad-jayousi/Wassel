import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';

class OnboardConfirmationScreen extends StatefulWidget {
  const OnboardConfirmationScreen({super.key});

  @override
  State<OnboardConfirmationScreen> createState() => _OnboardConfirmationScreenState();
}

class _OnboardConfirmationScreenState extends State<OnboardConfirmationScreen> {
  bool _isConfirming = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  size: 60,
                  color: AppColors.primary,
                ),
              ),

              const SizedBox(height: 32),

              // Title
              const Text(
                'Confirm with Driver',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Description
              const Text(
                'Please confirm with your driver that you are in the car and ready to go',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textMedium,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 48),

              // Confirm button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isConfirming ? null : () => _confirmOnboard(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isConfirming
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: AppColors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Confirm & Start Ride',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              // Back button
              TextButton(
                onPressed: _isConfirming ? null : () => Navigator.pop(context),
                child: const Text(
                  'Go Back',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textMedium,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmOnboard(BuildContext context) async {
    setState(() {
      _isConfirming = true;
    });

    // Simulate confirmation delay
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    // Navigate to en route screen
    Navigator.pushReplacementNamed(context, AppRouter.enRoute);
  }
}
