import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuthService _authService = FirebaseAuthService();
  
  bool _isAuthenticated = false;
  bool _hasSeenOnboarding = false;
  String? _userId;
  String? _phoneNumber;
  String? _userName;
  String? _verificationId;
  String? _errorMessage;
  
  bool get isAuthenticated => _isAuthenticated;
  bool get hasSeenOnboarding => _hasSeenOnboarding;
  String? get userId => _userId;
  String? get phoneNumber => _phoneNumber;
  String? get userName => _userName;
  String? get errorMessage => _errorMessage;
  
  AuthProvider() {
    _initializeAuthState();
  }
  
  void _initializeAuthState() {
    _authService.authStateChanges.listen((User? user) {
      if (user != null) {
        _isAuthenticated = true;
        _userId = user.uid;
        _phoneNumber = user.phoneNumber;
        _loadUserData();
      } else {
        _isAuthenticated = false;
        _userId = null;
        _phoneNumber = null;
        _userName = null;
      }
      notifyListeners();
    });
  }
  
  Future<void> _loadUserData() async {
    if (_userId != null) {
      final userData = await _authService.getUserData(_userId!);
      if (userData != null) {
        _userName = userData['userName'] ?? 'MJ';
      }
      notifyListeners();
    }
  }
  
  Future<bool> signInWithPhone(String phoneNumber) async {
    _errorMessage = null;
    
    try {
      final success = await _authService.sendOTP(
        phoneNumber: phoneNumber,
        onCodeSent: (verificationId) {
          _verificationId = verificationId;
          _phoneNumber = phoneNumber;
          notifyListeners();
        },
        onError: (error) {
          _errorMessage = error;
          notifyListeners();
        },
      );
      
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
  
  Future<bool> verifyOTP(String otp) async {
    print('🔍 [AuthProvider] Starting OTP verification...');
    print('📱 Verification ID: $_verificationId');
    print('🔢 OTP received: $otp (length: ${otp.length})');
    
    _errorMessage = null;
    
    // Basic OTP validation
    if (otp.isEmpty || otp.length != 4) {
      _errorMessage = 'Please enter a valid 4-digit OTP code';
      print('❌ $_errorMessage');
      notifyListeners();
      return false;
    }
    
    if (_verificationId == null || _verificationId!.isEmpty) {
      _errorMessage = 'No verification in progress. Please request a new OTP';
      print('❌ $_errorMessage');
      notifyListeners();
      return false;
    }
    
    try {
      print('📡 Calling verifyOTP in FirebaseAuthService...');
      final userCredential = await _authService.verifyOTP(
        otp: otp,
        verificationId: _verificationId,
      );
      
      if (userCredential != null && userCredential.user != null) {
        print('✅ [AuthProvider] OTP verification successful!');
        print('👤 User ID: ${userCredential.user!.uid}');
        print('📞 Phone: ${userCredential.user!.phoneNumber}');
        
        _isAuthenticated = true;
        _userId = userCredential.user!.uid;
        _phoneNumber = userCredential.user!.phoneNumber;
        
        print('🔄 Loading user data...');
        await _loadUserData();
        
        print('📢 Notifying listeners...');
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Verification failed. Please try again.';
        print('❌ [AuthProvider] OTP verification failed - No user credential returned');
        notifyListeners();
        return false;
      }
    } on FirebaseAuthException catch (e) {
      print('❌ Firebase Auth Error:');
      print('Code: ${e.code}');
      print('Message: ${e.message}');
      
      switch (e.code) {
        case 'invalid-verification-code':
          _errorMessage = 'The verification code is invalid. Please try again.';
          break;
        case 'missing-verification-id':
          _errorMessage = 'Session expired. Please request a new OTP.';
          break;
        case 'session-expired':
          _errorMessage = 'The SMS code has expired. Please request a new OTP.';
          break;
        case 'quota-exceeded':
          _errorMessage = 'Too many attempts. Please try again later.';
          break;
        default:
          _errorMessage = 'Verification failed: ${e.message ?? 'Unknown error'}';
      }
      
      notifyListeners();
      return false;
    } catch (e) {
      print('❌ Unexpected error during OTP verification:');
      print('Error type: ${e.runtimeType}');
      print('Error details: $e');
      
      _errorMessage = 'An unexpected error occurred. Please try again.';
      notifyListeners();
      return false;
    }
  }
  
  void markOnboardingAsViewed() {
    _hasSeenOnboarding = true;
    notifyListeners();
  }
  
  Future<void> updateProfile({
    String? userName,
    String? email,
    String? profileImageUrl,
  }) async {
    if (_userId != null) {
      await _authService.updateUserProfile(
        userId: _userId!,
        userName: userName,
        email: email,
        profileImageUrl: profileImageUrl,
      );
      
      if (userName != null) _userName = userName;
      notifyListeners();
    }
  }
  
  Future<void> signUp({
    required String email,
    required String phoneNumber,
    required String name,
  }) async {
    _phoneNumber = phoneNumber;
    _userName = name;
    notifyListeners();
  }
  
  Future<void> logout() async {
    await _authService.signOut();
    _isAuthenticated = false;
    _hasSeenOnboarding = false;
    _userId = null;
    _phoneNumber = null;
    _userName = null;
    _verificationId = null;
    _errorMessage = null;
    notifyListeners();
  }
  
  Future<void> deleteAccount() async {
    try {
      await _authService.deleteAccount();
      await logout();
    } catch (e) {
      _errorMessage = 'Failed to delete account: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }
}
