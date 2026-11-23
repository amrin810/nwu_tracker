import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/utils/app_logger.dart';
import '../models/user_model.dart';

/// Repository managing user authentication and profiles with Firebase
class AuthRepository {
  static const String _userProfileStorageKey = 'user_profile';

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseDatabase _database;

  AuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseDatabase? database,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _database = database ?? FirebaseDatabase.instance;

  /// Persists the user profile to local SharedPreferences and syncs to Cloud Firestore
  Future<void> saveUserProfile(AppUser user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(user.toJson());
      await prefs.setString(_userProfileStorageKey, jsonString);

      // Sync to Cloud Firestore: users/{uid}
      try {
        await _firestore.collection('users').doc(user.id).set(
          user.toJson()..['updatedAt'] = FieldValue.serverTimestamp(),
          SetOptions(merge: true),
        );
        AppLogger.info('User profile synced to Cloud Firestore: users/${user.id}');
      } catch (e) {
        AppLogger.warning('Cloud Firestore profile sync skipped: $e');
      }

      AppLogger.info('User profile saved successfully to local storage');
    } catch (e) {
      AppLogger.error('Failed to save user profile', e);
      rethrow;
    }
  }

  /// Loads any previously saved profile from SharedPreferences
  Future<AppUser?> loadSavedUserProfile({AppUser? fallback}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_userProfileStorageKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        final Map<String, dynamic> data =
            jsonDecode(jsonString) as Map<String, dynamic>;
        return AppUser.fromJson(data, fallback: fallback);
      }
    } catch (e) {
      AppLogger.warning('Failed to parse saved user profile: $e');
    }
    return null;
  }

  /// Checks whether a given ID is already registered for the specified role.
  /// Validates across Cloud Firestore ('users' collection).
  Future<bool> isIdAlreadyRegistered({
    required UserRole role,
    required String userId,
  }) async {
    final cleanId = userId.trim();
    if (cleanId.isEmpty) return false;

    try {
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: role.name)
          .where('userId', isEqualTo: cleanId)
          .limit(1)
          .get();
      if (snapshot.docs.isNotEmpty) return true;
    } catch (e) {
      AppLogger.warning('Firestore ID uniqueness check skipped: $e');
    }

    return false;
  }

  /// Returns the currently authenticated user, or null if no active session
  Future<AppUser?> getCurrentUser() async {
    try {
      final fbUser = _auth.currentUser;
      if (fbUser == null) {
        return null;
      }

      // Fetch latest profile from Cloud Firestore
      try {
        final doc = await _firestore.collection('users').doc(fbUser.uid).get();
        if (doc.exists && doc.data() != null) {
          final user = AppUser.fromJson(doc.data()!);
          await saveUserProfile(user);
          return user;
        }
      } catch (e) {
        AppLogger.warning('Failed to fetch Firestore doc for current user: $e');
      }

      // Fall back to locally persisted profile
      final savedProfile = await loadSavedUserProfile();
      if (savedProfile != null && savedProfile.id == fbUser.uid) {
        return savedProfile;
      }

      // Fall back to Firebase user object
      final user = AppUser(
        id: fbUser.uid,
        email: fbUser.email ?? '',
        fullName: fbUser.displayName ?? 'University Student',
        role: UserRole.student,
      );
      await saveUserProfile(user);
      return user;
    } catch (e) {
      AppLogger.warning('Firebase Auth session check notice: $e');
      return null;
    }
  }

  /// Sign in with email and password using Firebase Authentication
  Future<AppUser?> signIn({
    required String email,
    required String password,
  }) async {
    final userCredential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final fbUser = userCredential.user;
    if (fbUser == null) {
      throw Exception('Authentication failed. User not found.');
    }

    // Load profile from Firestore
    try {
      final doc = await _firestore.collection('users').doc(fbUser.uid).get();
      if (doc.exists && doc.data() != null) {
        final appUser = AppUser.fromJson(doc.data()!);
        await saveUserProfile(appUser);
        return appUser;
      }
    } catch (e) {
      AppLogger.warning('Failed to fetch user from Firestore: $e');
    }

    final saved = await loadSavedUserProfile();
    if (saved != null && saved.id == fbUser.uid) {
      return saved;
    }

    final appUser = AppUser(
      id: fbUser.uid,
      email: fbUser.email ?? email.trim(),
      fullName: fbUser.displayName ?? 'University Student',
      role: UserRole.student,
    );
    await saveUserProfile(appUser);
    return appUser;
  }

  /// Sign in with Google using Firebase Authentication
  Future<AppUser?> signInWithGoogle() async {
    UserCredential userCredential;

    if (kIsWeb) {
      final googleProvider = GoogleAuthProvider();
      googleProvider.addScope('email');
      googleProvider.addScope('profile');
      userCredential = await _auth.signInWithPopup(googleProvider);
    } else {
      final googleSignIn = GoogleSignIn(
        serverClientId:
            '549545881513-679kpsfia08fi52gdquuga6q1869q68v.apps.googleusercontent.com',
        scopes: ['email', 'profile'],
      );
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) return null; // Cancelled by user
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      userCredential = await _auth.signInWithCredential(credential);
    }

    final fbUser = userCredential.user;
    if (fbUser == null) return null;

    // Check if user already exists in Cloud Firestore
    try {
      final doc = await _firestore.collection('users').doc(fbUser.uid).get();
      if (doc.exists && doc.data() != null) {
        final existingUser = AppUser.fromJson(doc.data()!);
        await saveUserProfile(existingUser);
        return existingUser;
      }
    } catch (e) {
      AppLogger.warning('Could not load user doc from Firestore: $e');
    }

    // New Google User -> create profile
    final newUser = AppUser(
      id: fbUser.uid,
      email: fbUser.email ?? '',
      fullName: fbUser.displayName ?? 'University Student',
      role: UserRole.student,
    );

    try {
      await _firestore.collection('users').doc(newUser.id).set(
        newUser.toJson()..['createdAt'] = FieldValue.serverTimestamp(),
        SetOptions(merge: true),
      );
    } catch (e) {
      AppLogger.warning('Failed to save Google user to Firestore: $e');
    }

    await saveUserProfile(newUser);
    return newUser;
  }

  /// Register a new user with Firebase Authentication and persist to Firestore + RTDB
  Future<AppUser?> signUp({
    required String email,
    required String password,
    required String fullName,
    String? userId,
    String? studentId,
    String? phone,
    UserRole role = UserRole.student,
  }) async {
    final effectiveId = (userId ?? studentId)?.trim();

    // Check ID uniqueness within the chosen role before creating account
    if (effectiveId != null && effectiveId.isNotEmpty) {
      final alreadyExists = await isIdAlreadyRegistered(
        role: role,
        userId: effectiveId,
      );
      if (alreadyExists) {
        throw Exception(
          'This ${role.toFormattedString()} ID "$effectiveId" is already registered. Please check your ID or sign in.',
        );
      }
    }

    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final fbUser = userCredential.user;
    if (fbUser == null) {
      throw Exception('Failed to create Firebase user account');
    }

    await fbUser.updateDisplayName(fullName.trim());
    final newUser = AppUser(
      id: fbUser.uid,
      email: email.trim(),
      fullName: fullName.trim(),
      userId: effectiveId,
      phone: phone?.trim(),
      role: role,
    );

    // 2. Persist user record to Cloud Firestore: users/{id}
    try {
      await _firestore.collection('users').doc(newUser.id).set(
        newUser.toJson()..['createdAt'] = FieldValue.serverTimestamp(),
        SetOptions(merge: true),
      );
      AppLogger.info('Saved user profile to Cloud Firestore: users/${newUser.id}');
    } catch (e) {
      AppLogger.warning('Cloud Firestore user write skipped: $e');
    }

    // 3. Save user record to Firebase Realtime Database: users/{id}
    try {
      final userRef = _database.ref('users/${newUser.id}');
      await userRef.set(newUser.toFirebaseMap());
      AppLogger.info('Saved user record to Firebase RTDB for ${newUser.email}');
    } catch (e) {
      AppLogger.warning('Firebase RTDB user write skipped: $e');
    }

    await saveUserProfile(newUser);
    return newUser;
  }

  /// Sign out current user
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      if (!kIsWeb) {
        await GoogleSignIn().signOut();
      }
    } catch (e) {
      AppLogger.warning('Firebase signOut notice: $e');
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userProfileStorageKey);
    } catch (_) {}
  }
}
