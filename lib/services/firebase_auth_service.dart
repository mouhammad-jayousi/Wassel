import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  String? _verificationId;
  
  User? get currentUser => _auth.currentUser;
  String? get currentUserId => _auth.currentUser?.uid;
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  
  Future<bool> sendOTP({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onError,
  }) async {
    try {
      print('📱 [FirebaseAuthService] Starting OTP send for: $phoneNumber');
      
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          print('✅ [FirebaseAuthService] Verification completed automatically');
          await _auth.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          print('❌ [FirebaseAuthService] Verification failed: ${e.message}');
          onError(e.message ?? 'Verification failed');
        },
        codeSent: (String verificationId, int? resendToken) {
          print('✅ [FirebaseAuthService] Code sent successfully. Verification ID: $verificationId');
          _verificationId = verificationId;
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          print('⏱️ [FirebaseAuthService] Code auto-retrieval timeout. Verification ID: $verificationId');
          _verificationId = verificationId;
        },
      );
      print('✅ [FirebaseAuthService] verifyPhoneNumber call completed');
      return true;
    } catch (e) {
      print('❌ [FirebaseAuthService] Exception in sendOTP: $e');
      onError(e.toString());
      return false;
    }
  }
  
  Future<UserCredential?> verifyOTP({
    required String otp,
    String? verificationId,
  }) async {
    print('🔍 [FirebaseAuthService] Starting OTP verification...');
    print('📱 Verification ID provided: ${verificationId != null}');
    print('📱 Stored verification ID: ${_verificationId != null}');
    print('🔢 OTP received: $otp (length: ${otp.length})');
    
    // Validate OTP format
    if (otp.isEmpty || otp.length != 4) {
      final error = '❌ Invalid OTP format. Must be 4 digits';
      print(error);
      throw FirebaseAuthException(
        code: 'invalid-verification-code',
        message: error,
      );
    }
    
    try {
      final String vid = verificationId ?? _verificationId ?? '';
      
      if (vid.isEmpty) {
        final error = '❌ Verification ID is missing. Please request a new OTP';
        print(error);
        throw FirebaseAuthException(
          code: 'missing-verification-id',
          message: error,
        );
      }
      
      print('🔑 Creating PhoneAuthCredential...');
      PhoneAuthCredential credential;
      try {
        credential = PhoneAuthProvider.credential(
          verificationId: vid,
          smsCode: otp,
        );
        print('✅ Credential created successfully');
      } catch (credError) {
        print('❌ Error creating credential:');
        print('Error type: ${credError.runtimeType}');
        print('Error details: $credError');
        throw FirebaseAuthException(
          code: 'invalid-credential',
          message: 'Failed to create phone auth credential',
        );
      }
      
      print('🔐 Signing in with credential...');
      UserCredential userCredential;
      try {
        userCredential = await _auth.signInWithCredential(credential);
        print('✅ Successfully signed in with credential');
        print('👤 User ID: ${userCredential.user?.uid}');
        print('📞 Phone: ${userCredential.user?.phoneNumber}');
        print('🆕 New user: ${userCredential.additionalUserInfo?.isNewUser ?? false}');
      } on FirebaseAuthException catch (e) {
        print('❌ Firebase Auth Error during signInWithCredential:');
        print('Error code: ${e.code}');
        print('Error message: ${e.message}');
        rethrow;
      } catch (signInError) {
        print('❌ Unknown error during signInWithCredential:');
        print('Error type: ${signInError.runtimeType}');
        print('Error details: $signInError');
        rethrow;
      }
      
      // Try to create user document, but don't fail if it errors
      try {
        if (userCredential.additionalUserInfo?.isNewUser ?? false) {
          print('📝 Creating new user document...');
          await _createUserDocument(userCredential.user!);
          print('✅ User document created successfully');
        } else {
          print('ℹ️ User already exists, skipping document creation');
        }
      } catch (docError) {
        print('⚠️ Error creating user document: $docError');
        print('🔄 Continuing with authentication...');
      }
      
      return userCredential;
    } catch (e) {
      print('❌ [FirebaseAuthService] Error in verifyOTP:');
      print('Error type: ${e.runtimeType}');
      print('Error details: $e');
      rethrow; // Rethrow to let the caller handle the error
    }
  }
  
  Future<void> _createUserDocument(User user) async {
    try {
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'phoneNumber': user.phoneNumber,
        'createdAt': FieldValue.serverTimestamp(),
        'userName': 'MJ',
        'rating': 5.0,
        'totalRides': 0,
        'profileImageUrl': '',
      });
    } catch (e) {
      print('Error creating user document: $e');
    }
  }
  
  Future<void> updateUserProfile({
    required String userId,
    String? userName,
    String? email,
    String? profileImageUrl,
  }) async {
    try {
      Map<String, dynamic> data = {};
      
      if (userName != null) data['userName'] = userName;
      if (email != null) data['email'] = email;
      if (profileImageUrl != null) data['profileImageUrl'] = profileImageUrl;
      
      if (data.isNotEmpty) {
        await _firestore.collection('users').doc(userId).update(data);
      }
    } catch (e) {
      print('Error updating user profile: $e');
    }
  }
  
  Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(userId).get();
      return doc.data() as Map<String, dynamic>?;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }
  
  Future<void> signOut() async {
    await _auth.signOut();
  }
  
  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).delete();
        await user.delete();
      }
    } catch (e) {
      print('Error deleting account: $e');
      rethrow;
    }
  }
}
