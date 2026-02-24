import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/services.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import '../models/user.dart' as app_user;
import 'backend_auth_service.dart';

/// Custom exception for offline state
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

  // ✅ Get backend auth service
  BackendAuthService get backendAuth => _backendAuth;

  // ✅ helper: check internet (real connection)
  Future<void> _requireInternet() async {
    final hasInternet = await InternetConnectionChecker().hasConnection;
    if (!hasInternet) throw OfflineException();
  }

  // ✅ Convert Firebase errors -> user friendly messages
  String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'network-request-failed':
        return 'No internet connection. Please connect and try again.';
      case 'user-not-found':
        return 'No user found for that email.';
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

  // ✅ Google Sign-In with Backend Sync
  Future<app_user.User?> signInWithGoogle() async {
    try {
      print('🔍 Starting Google Sign-In...');
      await _requireInternet();
      await _googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        print('❌ Google sign-in cancelled by user');
        return null;
      }

      print('✅ Google user selected: ${googleUser.email}');

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      if (googleAuth.idToken == null) {
        throw Exception('Missing Google idToken');
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      print('🔐 Signing in to Firebase with Google credential...');

      User? firebaseUser;

      try {
        final UserCredential userCredential =
            await _auth.signInWithCredential(credential);
        firebaseUser = userCredential.user;
      } on TypeError catch (e) {
        print('⚠️ Firebase platform TypeError: $e');
        await Future.delayed(const Duration(milliseconds: 600));
        firebaseUser = _auth.currentUser;
      } on FirebaseAuthException catch (e) {
        throw Exception(_mapAuthError(e));
      }

      if (firebaseUser == null) {
        throw Exception('Authentication failed');
      }

      print('✅ Firebase auth successful: ${firebaseUser.uid}');

      // Firestore sync - Use DateTime.now() instead of serverTimestamp
      final userRef = _firestore.collection('users').doc(firebaseUser.uid);
      final now = DateTime.now();

      try {
        await userRef.set({
          'uid': firebaseUser.uid,
          'email': firebaseUser.email ?? '',
          'name': firebaseUser.displayName ?? 'User',
          'phone': firebaseUser.phoneNumber ?? '',
          'photoUrl': firebaseUser.photoURL ?? '',
          'updated_at': Timestamp.fromDate(now),
        }, SetOptions(merge: true));

        final doc = await userRef.get();
        final data = doc.data() ?? {};
        if (data['created_at'] == null) {
          await userRef.set({
            'created_at': Timestamp.fromDate(now),
          }, SetOptions(merge: true));
        }
      } catch (firestoreError) {
        print('⚠️ Firestore error (non-critical): $firestoreError');
      }

      final finalDoc = await userRef.get();
      final finalData = finalDoc.data() ?? {};

      // ✅ SYNC WITH BACKEND - CRITICAL PART
      print('🔄 Starting backend sync...');
      try {
        await _backendAuth.syncWithBackend(
          firebaseUid: firebaseUser.uid,
          email: finalData['email'] ?? (firebaseUser.email ?? ''),
          name: finalData['name'] ?? (firebaseUser.displayName ?? 'User'),
          phone: finalData['phone'],
        );
        print('✅ Backend sync completed successfully');
      } catch (e) {
        print('⚠️ Backend sync failed (non-critical): $e');
        // Continue even if backend sync fails
      }

      return app_user.User(
        uid: firebaseUser.uid,
        email: finalData['email'] ?? (firebaseUser.email ?? ''),
        name: finalData['name'] ?? (firebaseUser.displayName ?? 'User'),
        phone: finalData['phone'] ?? (firebaseUser.phoneNumber ?? ''),
        createdAt:
            (finalData['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
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

  // ✅ Sign Up with Backend Sync
  Future<app_user.User?> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    try {
      print('📝 Starting sign up for: $email');
      await _requireInternet();

      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = result.user;
      if (user == null) return null;

      print('✅ Firebase user created: ${user.uid}');

      // ✅ USE DateTime.now() INSTEAD OF serverTimestamp() to avoid Firestore bug
      final now = DateTime.now();

      try {
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': email,
          'name': name,
          'phone': phone,
          'created_at': Timestamp.fromDate(now),
          'updated_at': Timestamp.fromDate(now),
        });
        print('✅ Firestore document created');
      } catch (firestoreError) {
        print('⚠️ Firestore error: $firestoreError');
        // Continue anyway - Firestore not critical for login
      }

      // ✅ SYNC WITH BACKEND - This is what matters!
      print('🔄 Starting backend sync...');
      try {
        await _backendAuth.syncWithBackend(
          firebaseUid: user.uid,
          email: email,
          name: name,
          phone: phone,
        );
        print('✅ Backend sync completed successfully');
      } catch (e) {
        print('⚠️ Backend sync failed (non-critical): $e');
      }

      return app_user.User(
        uid: user.uid,
        email: email,
        name: name,
        phone: phone,
        createdAt: now,
      );
    } on OfflineException catch (e) {
      throw Exception(e.message);
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapAuthError(e));
    } catch (e) {
      print('❌ Sign up error: $e');

      // ✅ If user was created, try to recover and sync backend
      final currentUser = _auth.currentUser;
      if (currentUser != null && currentUser.email == email) {
        print('⚠️ User created despite error, attempting backend sync...');

        try {
          await _backendAuth.syncWithBackend(
            firebaseUid: currentUser.uid,
            email: email,
            name: name,
            phone: phone,
          );
          print('✅ Backend sync successful');

          return app_user.User(
            uid: currentUser.uid,
            email: email,
            name: name,
            phone: phone,
            createdAt: DateTime.now(),
          );
        } catch (syncError) {
          print('⚠️ Backend sync also failed: $syncError');
        }
      }

      throw Exception('Sign up failed: $e');
    }
  }

  // ✅ Sign In with Backend Sync
  Future<app_user.User?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      print('📧 Starting sign in for: $email');
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
            'You are offline. Connect to internet to log in the first time.');
      }

      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = result.user;
      if (user == null) return null;

      print('✅ Firebase sign in successful: ${user.uid}');

      final userData = await getUserData(user.uid);

      // ✅ SYNC WITH BACKEND
      if (userData != null) {
        print('🔄 Starting backend sync...');
        try {
          await _backendAuth.syncWithBackend(
            firebaseUid: user.uid,
            email: userData.email,
            name: userData.name,
            phone: userData.phone,
          );
          print('✅ Backend sync completed successfully');
        } catch (e) {
          print('⚠️ Backend sync failed (non-critical): $e');
        }
      }

      return userData;
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapAuthError(e));
    } catch (e) {
      print('❌ Sign in error: $e');
      throw Exception('Sign in failed: $e');
    }
  }

  // ✅ Sign Out with Backend Clear
  Future<void> signOut() async {
    try {
      print('👋 Signing out...');
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
        _backendAuth.clearBackendToken(),
      ]);
      print('✅ Sign out successful');
    } catch (e) {
      print('❌ Error during sign out: $e');
    }
  }

  // ✅ Get User Data (fallback to cache when offline)
  Future<app_user.User?> getUserData(String uid,
      {bool preferCache = false}) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get(GetOptions(
          source: preferCache ? Source.cache : Source.serverAndCache));

      if (!doc.exists) return null;

      final data = doc.data() ?? {};

      return app_user.User(
        uid: uid,
        email: data['email'] ?? '',
        name: data['name'] ?? '',
        phone: data['phone'] ?? '',
        createdAt:
            (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
    } catch (e) {
      if (!preferCache) {
        try {
          final cacheDoc = await _firestore
              .collection('users')
              .doc(uid)
              .get(const GetOptions(source: Source.cache));
          if (cacheDoc.exists) {
            final data = cacheDoc.data() ?? {};
            return app_user.User(
              uid: uid,
              email: data['email'] ?? '',
              name: data['name'] ?? '',
              phone: data['phone'] ?? '',
              createdAt: (data['created_at'] as Timestamp?)?.toDate() ??
                  DateTime.now(),
            );
          }
        } catch (_) {}
      }
      print('❌ Error getting user data: $e');
      return null;
    }
  }

  // ✅ Update User Data (needs internet)
  Future<void> updateUserData({
    required String uid,
    required String name,
    required String phone,
  }) async {
    try {
      await _requireInternet();

      final now = DateTime.now();
      await _firestore.collection('users').doc(uid).update({
        'name': name,
        'phone': phone,
        'updated_at': Timestamp.fromDate(now),
      });

      print('✅ User data updated successfully');
    } on OfflineException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      print('❌ Failed to update user data: $e');
      throw Exception('Failed to update user data: $e');
    }
  }
}
