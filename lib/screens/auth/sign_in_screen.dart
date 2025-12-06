import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:country_picker/country_picker.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../providers/auth_provider.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController _phoneController = TextEditingController();
  String _selectedCountryCode = '+972';
  late Country _selectedCountry;
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _selectedCountry = CountryParser.parseCountryCode('IL');
    _selectedCountryCode = '+${_selectedCountry.phoneCode}';
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
          child: Column(
            children: [
              // Top Section with Logo Widget
              Expanded(
                flex: 2,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Custom Wassel Widget
                      SizedBox(
                        width: 120,
                        height: 120,
                        child: Image.asset(
                          'assets/images/wassel_widget.png',
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            
            // Bottom Section with Form
            Expanded(
              flex: 4,
              child: Container(
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      
                      // Title
                      const Text(
                        'Enter your phone number',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Phone Number Input - Unified with Country Code
                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          hintText: 'Mobile Number',
                          prefixIcon: GestureDetector(
                            onTap: _showCountryCodePicker,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _selectedCountry.flagEmoji,
                                    style: const TextStyle(fontSize: 20),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _selectedCountryCode,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const Icon(
                                    Icons.arrow_drop_down,
                                    size: 16,
                                    color: AppColors.textMedium,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Next Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleNext,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: AppColors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Next'),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Terms & Conditions
                      const Text(
                        'By continuing you agree to our Terms & Conditions',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textLight,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleNext() async {
    if (_phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your phone number')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final phoneNumber = '$_selectedCountryCode${_phoneController.text}';
    
    print('📱 [SignInScreen] Attempting to send OTP to: $phoneNumber');
    
    final success = await authProvider.signInWithPhone(phoneNumber);

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (success) {
      print('✅ [SignInScreen] OTP sent successfully');
      Navigator.pushNamed(
        context,
        AppRouter.phoneVerification,
        arguments: {
          'phoneNumber': phoneNumber,
        },
      );
    } else {
      print('❌ [SignInScreen] OTP sending failed');
      final errorMessage = authProvider.errorMessage ?? 'Failed to send OTP. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showCountryCodePicker() {
    showCountryPicker(
      context: context,
      showPhoneCode: true,
      onSelect: (Country country) {
        setState(() {
          _selectedCountry = country;
          _selectedCountryCode = '+${country.phoneCode}';
        });
      },
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }
}
