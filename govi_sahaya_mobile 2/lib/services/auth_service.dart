import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:internet_connection_checker/internet_connection_checker.dart';
import '../models/user.dart' as app_user;
import 'backend_auth_service.dart';

class OfflineException implements Exception {
  final String message;
  OfflineException(
      [this.message = 'No internet connection. Please try again.']);

  @override
  String toString() => message;
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
  final BackendAuthService _backendAuth = BackendAuthService();

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  BackendAuthService get backendAuth => _backendAuth;
  String get baseUrl => BackendAuthService.baseUrl;

  Future<void> _requireInternet() async {
    final hasInternet = await InternetConnectionChecker().hasConnection;
    if (!hasInternet) throw OfflineException();
  }

  String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'network-request-failed':
        return 'No internet connection. Please connect and try again.';
      case 'user-not-found':
        return 'No account found with that email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'email-already-in-use':
        return 'That email is already registered.';
      case 'weak-password':
        return 'The password is too weak.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return e.message ?? 'Authentication error occurred.';
    }
  }

  app_user.User _userFromFirestore(Map<String, dynamic> data, String uid) {
    return app_user.User.fromFirestore(data, uid);
  }

  // ── Call backend /auth/register to send verification email ──
  Future<void> _registerWithBackend({
    required String name,
    required String email,
    required String phone,
    required String firebaseUid,
  }) async {
    try {
      print('📧 Calling backend /auth/register to send verification email...');
      final response = await http
          .post(
            Uri.parse('${BackendAuthService.baseUrl}/auth/register'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'name': name,
              'email': email,
              'phone': phone,
              'password': firebaseUid, // dummy — Firebase owns auth
              'firebaseUid': firebaseUid,
              'role': 'farmer',
            }),
          )
          .timeout(const Duration(seconds: 30));

      print('📡 Register response: ${response.statusCode}');

      if (response.statusCode == 201) {
        print('✅ Backend register success — verification email sent!');
      } else if (response.statusCode == 409) {
        print('ℹ️ User already in backend, skipping register');
      } else {
        print('⚠️ Backend register failed: ${response.body}');
      }
    } catch (e) {
      print('⚠️ Backend register error (non-critical): $e');
    }
  }

  // ── Google Sign-In ─────────────────────────────────────────────
  Future<app_user.User?> signInWithGoogle() async {
    try {
      await _requireInternet();
      await _googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      if (googleAuth.idToken == null) {
        throw Exception('Missing Google idToken');
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      User? firebaseUser;
      try {
        final UserCredential userCredential =
            await _auth.signInWithCredential(credential);
        firebaseUser = userCredential.user;
      } on TypeError catch (e) {
        print('⚠️ Firebase Pigeon TypeError (Google): $e');
        await Future.delayed(const Duration(milliseconds: 800));
        firebaseUser = await _auth
            .authStateChanges()
            .firstWhere((u) => u != null, orElse: () => null);
        firebaseUser ??= _auth.currentUser;
      } on FirebaseAuthException catch (e) {
        throw Exception(_mapAuthError(e));
      }

      if (firebaseUser == null) {
        throw Exception('Authentication failed');
      }

      final userRef = _firestore.collection('users').doc(firebaseUser.uid);
      final now = DateTime.now();

      try {
        await userRef.set(
          {
            'uid': firebaseUser.uid,
            'email': firebaseUser.email ?? '',
            'name': firebaseUser.displayName ?? 'User',
            'phone': firebaseUser.phoneNumber ?? '',
            'photoUrl': firebaseUser.photoURL ?? '',
            'updated_at': Timestamp.fromDate(now),
          },
          SetOptions(merge: true),
        );

        final doc = await userRef.get();
        if ((doc.data() ?? {})['created_at'] == null) {
          await userRef.set(
            {'created_at': Timestamp.fromDate(now)},
            SetOptions(merge: true),
          );
        }
      } catch (e) {
        print('⚠️ Firestore error (non-critical): $e');
      }

      final finalDoc = await userRef.get();
      final finalData = finalDoc.data() ?? <String, dynamic>{};

      try {
        await _backendAuth.syncWithBackend(
          firebaseUid: firebaseUser.uid,
          email: finalData['email'] ?? (firebaseUser.email ?? ''),
          name: finalData['name'] ?? (firebaseUser.displayName ?? 'User'),
          phone: finalData['phone'],
        );
      } catch (e) {
        print('⚠️ Backend sync failed (non-critical): $e');
      }

      return _userFromFirestore(finalData, firebaseUser.uid);
    } on OfflineException catch (e) {
      throw Exception(e.message);
    } on PlatformException catch (e) {
      if (e.code.toLowerCase().contains('network')) {
        throw Exception('No internet connection. Please try again.');
      }
      throw Exception('Google sign-in failed: ${e.message}');
    } catch (e) {
      print('❌ Google sign-in error: $e');
      throw Exception('Google sign-in failed: $e');
    }
  }

  // ── Sign Up ────────────────────────────────────────────────────
  Future<app_user.User?> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    try {
      await _requireInternet();

      UserCredential? result;
      User? user;

      try {
        result = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        user = result.user;
      } on FirebaseAuthException catch (e) {
        throw Exception(_mapAuthError(e));
      } catch (e) {
        print('⚠️ Pigeon bug during signUp: $e');
        await Future.delayed(const Duration(milliseconds: 800));
        user = _auth.currentUser;
      }

      if (user == null) return null;

      // DO NOT call user.sendEmailVerification()
      // Backend /auth/register sends the HTML verification email

      final now = DateTime.now();

      // Save to Firestore
      try {
        await _firestore.collection('users').doc(user.uid).set(
          {
            'uid': user.uid,
            'email': email,
            'name': name,
            'phone': phone,
            'role': 'farmer',
            'isVerified': false,
            'isActive': true,
            'created_at': Timestamp.fromDate(now),
            'updated_at': Timestamp.fromDate(now),
          },
          SetOptions(merge: true),
        );
      } catch (e) {
        print('⚠️ Firestore error: $e');
      }

      // Call backend /auth/register — this sends verification email
      await _registerWithBackend(
        name: name,
        email: email,
        phone: phone,
        firebaseUid: user.uid,
      );

      // Sign out — user must verify email before logging in
      await _auth.signOut();

      return app_user.User(
        uid: user.uid,
        email: email,
        name: name,
        phone: phone,
        createdAt: now,
        isVerified: false,
      );
    } on OfflineException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      print('❌ Sign up error: $e');
      throw Exception('Sign up failed: $e');
    }
  }

  // ── Sign In ────────────────────────────────────────────────────
  Future<app_user.User?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final hasInternet = await InternetConnectionChecker().hasConnection;

      if (!hasInternet) {
        final u = _auth.currentUser;
        if (u != null) {
          final cached = await getUserData(u.uid, preferCache: true);
          return cached ??
              app_user.User(
                uid: u.uid,
                email: u.email ?? email,
                name: u.displayName ?? 'User',
                phone: u.phoneNumber ?? '',
                createdAt: DateTime.now(),
              );
        }
        throw OfflineException(
          'You are offline. Connect to the internet to log in.',
        );
      }

      UserCredential? result;
      User? user;

      try {
        result = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        user = result.user;
      } on FirebaseAuthException catch (e) {
        throw Exception(_mapAuthError(e));
      } catch (e) {
        print('⚠️ Pigeon bug during signIn: $e');
        user = _auth.currentUser;
      }

      if (user == null) return null;

      final userData = await getUserData(user.uid);

      try {
        await _backendAuth.syncWithBackend(
          firebaseUid: user.uid,
          email: userData?.email ?? email,
          name: userData?.name ?? user.displayName ?? 'User',
          phone: userData?.phone ?? '',
        );
      } catch (e) {
        print('⚠️ Backend sync failed (non-critical): $e');
      }

      // Keep Firestore isVerified in sync
      await _firestore
          .collection('users')
          .doc(user.uid)
          .update({'isVerified': true}).catchError((_) {});

      return userData;
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapAuthError(e));
    } catch (e) {
      print('❌ Sign in error: $e');
      rethrow;
    }
  }

  // ── Forgot Password (via backend) ──────────────────────────────
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _requireInternet();

      print('📧 Calling backend /auth/forgot-password...');
      final response = await http
          .post(
            Uri.parse('${BackendAuthService.baseUrl}/auth/forgot-password'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email.trim()}),
          )
          .timeout(const Duration(seconds: 30));

      print('📡 Forgot password response: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('✅ Password reset email sent via backend!');
        return;
      } else if (response.statusCode == 404) {
        throw Exception('No account found with that email.');
      } else {
        try {
          final body = jsonDecode(response.body);
          throw Exception(body['message'] ?? 'Failed to send reset email.');
        } catch (_) {
          throw Exception('Failed to send reset email. Please try again.');
        }
      }
    } on OfflineException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      print('❌ Backend forgot-password error: $e');
      throw Exception('Failed to send reset email: $e');
    }
  }

  // ── Resend verification email (calls backend) ──────────────────
  Future<void> resendVerificationEmail() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      print('📧 Requesting backend to resend verification email...');
      await http.post(
        Uri.parse('${BackendAuthService.baseUrl}/auth/resend-verification'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': user.email}),
      );
    } catch (e) {
      print('⚠️ Resend verification error: $e');
    }
  }

  // ── Sign Out ───────────────────────────────────────────────────
  Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
        _backendAuth.clearBackendToken(),
      ]);
    } catch (e) {
      print('❌ Error during sign out: $e');
    }
  }

  // ── Get User Data (Firestore, offline-safe) ────────────────────
  Future<app_user.User?> getUserData(
    String uid, {
    bool preferCache = false,
  }) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get(
            GetOptions(
              source: preferCache ? Source.cache : Source.serverAndCache,
            ),
          );
      if (!doc.exists) return null;
      return _userFromFirestore(doc.data() ?? <String, dynamic>{}, uid);
    } catch (e) {
      if (!preferCache) {
        try {
          final cacheDoc = await _firestore
              .collection('users')
              .doc(uid)
              .get(const GetOptions(source: Source.cache));
          if (cacheDoc.exists) {
            return _userFromFirestore(
                cacheDoc.data() ?? <String, dynamic>{}, uid);
          }
        } catch (_) {}
      }
      print('❌ Error getting user data: $e');
      return null;
    }
  }

  // ── Update User Data ───────────────────────────────────────────
  Future<void> updateUserData({
    required String uid,
    required String name,
    required String phone,
    String? address,
    String? birthday,
    String? gender,
    String? farmLocation,
    String? extraNotes,
    String? profileImageUrl,
  }) async {
    try {
      await _requireInternet();
      final now = DateTime.now();
      final Map<String, dynamic> updates = {
        'name': name,
        'phone': phone,
        'updated_at': Timestamp.fromDate(now),
      };
      if (address != null) updates['address'] = address;
      if (birthday != null) updates['birthday'] = birthday;
      if (gender != null) updates['gender'] = gender;
      if (farmLocation != null) updates['farmLocation'] = farmLocation;
      if (extraNotes != null) updates['extraNotes'] = extraNotes;
      if (profileImageUrl != null) updates['profileImageUrl'] = profileImageUrl;

      await _firestore.collection('users').doc(uid).update(updates);
    } on OfflineException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Failed to update user data: $e');
    }
  }
}
