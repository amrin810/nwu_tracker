import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/demo_data.dart';
import '../core/services/supabase_service.dart';
import '../core/utils/app_logger.dart';
import '../models/user_model.dart';

/// Repository managing user authentication and profiles
class AuthRepository {
  final SupabaseService _supabaseService;

  static const String _userProfileStorageKey = 'user_profile';

  AuthRepository({SupabaseService? supabaseService})
      : _supabaseService = supabaseService ?? SupabaseService.instance;

  bool get _isSupabaseActive => _supabaseService.isInitialized;

  // Registered users cache (initialized with demo accounts for demo/offline resilience)
  static final List<AppUser> _registeredUsers = List<AppUser>.from(DemoData.demoUsers);

  // Local demo session cache
  AppUser? _currentDemoUser = _registeredUsers.first; // Default to student

  /// Persists the user profile to local SharedPreferences and syncs to Cloud Firestore
  Future<void> saveUserProfile(AppUser user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(user.toJson());
      await prefs.setString(_userProfileStorageKey, jsonString);
      _currentDemoUser = user;
      final idx = _registeredUsers.indexWhere((u) => u.id == user.id);
      if (idx >= 0) {
        _registeredUsers[idx] = user;
      } else {
        _registeredUsers.add(user);
      }

      // Sync to Cloud Firestore: users/{uid}
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.id).set(
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
      AppLogger.warning('Failed to parse saved user profile, falling back: $e');
    }
    return null;
  }

  /// Checks whether a given ID is already registered for the specified role.
  /// Validates across Cloud Firestore, Firebase Realtime Database, and local records.
  Future<bool> isIdAlreadyRegistered({
    required UserRole role,
    required String userId,
  }) async {
    final cleanId = userId.trim();
    if (cleanId.isEmpty) return false;

    // 1. Check in Cloud Firestore ('users' collection)
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: role.name)
          .where('userId', isEqualTo: cleanId)
          .limit(1)
          .get();
      if (snapshot.docs.isNotEmpty) return true;
    } catch (e) {
      AppLogger.warning('Firestore ID uniqueness check skipped: $e');
    }

    // 2. Check in Firebase Realtime Database under 'users' node
    try {
      final snapshot = await FirebaseDatabase.instance.ref('users').get();
      if (snapshot.exists && snapshot.value is Map) {
        final data = Map<dynamic, dynamic>.from(snapshot.value as Map);
        for (final entry in data.values) {
          if (entry is Map) {
            final existingRole = entry['role']?.toString().toLowerCase();
            final existingId = (entry['userId'] ??
                    entry['student_id'] ??
                    entry['studentId'] ??
                    entry['user_id'])
                ?.toString()
                .trim();
            if (existingRole == role.name.toLowerCase() &&
                existingId != null &&
                existingId.toLowerCase() == cleanId.toLowerCase()) {
              return true;
            }
          }
        }
      }
    } catch (e) {
      AppLogger.warning('Firebase Realtime Database uniqueness check skipped: $e');
    }

    // 3. Check in-memory registered users list
    for (final user in _registeredUsers) {
      if (user.role == role &&
          user.userId != null &&
          user.userId!.trim().toLowerCase() == cleanId.toLowerCase()) {
        return true;
      }
    }

    return false;
  }

  /// Returns the currently authenticated user
  Future<AppUser?> getCurrentUser() async {
    AppUser? baseUser;

    // 1. Check Firebase Auth session
    try {
      final fbUser = FirebaseAuth.instance.currentUser;
      if (fbUser != null) {
        try {
          final doc = await FirebaseFirestore.instance
              .collection('users')
              .doc(fbUser.uid)
              .get();
          if (doc.exists && doc.data() != null) {
            baseUser = AppUser.fromJson(doc.data()!);
          }
        } catch (e) {
          AppLogger.warning('Failed to fetch Firestore doc for current user: $e');
        }

        baseUser ??= AppUser(
          id: fbUser.uid,
          email: fbUser.email ?? '',
          fullName: fbUser.displayName ?? 'University Student',
          role: UserRole.student,
        );
      }
    } catch (e) {
      AppLogger.warning('Firebase Auth session check notice: $e');
    }

    if (baseUser == null && _isSupabaseActive) {
      try {
        final session = _supabaseService.client!.auth.currentSession;
        if (session != null) {
          final userId = session.user.id;
          final response = await _supabaseService.client!
              .from('profiles')
              .select()
              .eq('id', userId)
              .maybeSingle();

          if (response != null) {
            baseUser = AppUser.fromJson(response);
          }
        }
      } catch (e) {
        AppLogger.error('Failed to get Supabase session user', e);
      }
    }

    baseUser ??= _currentDemoUser;

    // Load any locally persisted edits from SharedPreferences
    final savedProfile = await loadSavedUserProfile(fallback: baseUser);
    if (savedProfile != null) {
      if (baseUser == null || savedProfile.id == baseUser.id || baseUser.id == 'student-001') {
        _currentDemoUser = savedProfile;
        return savedProfile;
      }
    }

    return baseUser;
  }

  /// Sign in with email and password using Firebase Authentication (with fallback to demo mode)
  Future<AppUser?> signIn({
    required String email,
    required String password,
  }) async {
    // 1. Try Firebase Authentication
    try {
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final fbUser = userCredential.user;
      if (fbUser != null) {
        try {
          final doc = await FirebaseFirestore.instance
              .collection('users')
              .doc(fbUser.uid)
              .get();
          if (doc.exists && doc.data() != null) {
            final appUser = AppUser.fromJson(doc.data()!);
            await saveUserProfile(appUser);
            _currentDemoUser = appUser;
            return appUser;
          }
        } catch (e) {
          AppLogger.warning('Failed to fetch user from Firestore: $e');
        }

        final appUser = AppUser(
          id: fbUser.uid,
          email: fbUser.email ?? email,
          fullName: fbUser.displayName ?? 'University Student',
          role: UserRole.student,
        );
        await saveUserProfile(appUser);
        _currentDemoUser = appUser;
        return appUser;
      }
    } catch (e) {
      AppLogger.warning('Firebase signIn attempt: $e');
      final isDemoEmail = _registeredUsers.any(
        (u) => u.email.toLowerCase() == email.trim().toLowerCase(),
      );
      if (!isDemoEmail && e is FirebaseAuthException) {
        rethrow;
      }
    }

    if (_isSupabaseActive) {
      try {
        final response = await _supabaseService.client!.auth.signInWithPassword(
          email: email,
          password: password,
        );
        if (response.user != null) {
          final profile = await _supabaseService.client!
              .from('profiles')
              .select()
              .eq('id', response.user!.id)
              .single();
          return AppUser.fromJson(profile);
        }
      } catch (e) {
        AppLogger.error('Supabase signIn error', e);
        rethrow;
      }
    }

    // Demo Mode Sign In: Matches any registered user by email, or creates a demo student
    final matchingDemo = _registeredUsers.firstWhere(
      (u) => u.email.toLowerCase() == email.trim().toLowerCase(),
      orElse: () => AppUser(
        id: 'student-custom',
        email: email,
        fullName: 'University Student',
        userId: 'CSE-22-0099',
        role: UserRole.student,
      ),
    );

    // If there is a saved profile matching this user, restore it
    final savedProfile = await loadSavedUserProfile(fallback: matchingDemo);
    if (savedProfile != null && savedProfile.id == matchingDemo.id) {
      _currentDemoUser = savedProfile;
      return savedProfile;
    }

    _currentDemoUser = matchingDemo;
    return matchingDemo;
  }

  /// Sign in with Google using Firebase Authentication
  Future<AppUser?> signInWithGoogle() async {
    try {
      UserCredential userCredential;

      if (kIsWeb) {
        final googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        userCredential = await FirebaseAuth.instance.signInWithPopup(googleProvider);
      } else {
        final googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
        final googleUser = await googleSignIn.signIn();
        if (googleUser == null) return null; // Cancelled by user
        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      }

      final fbUser = userCredential.user;
      if (fbUser == null) return null;

      // Check if user already exists in Cloud Firestore
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(fbUser.uid)
            .get();
        if (doc.exists && doc.data() != null) {
          final existingUser = AppUser.fromJson(doc.data()!);
          await saveUserProfile(existingUser);
          _currentDemoUser = existingUser;
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
        await FirebaseFirestore.instance.collection('users').doc(newUser.id).set(
          newUser.toJson()..['createdAt'] = FieldValue.serverTimestamp(),
          SetOptions(merge: true),
        );
      } catch (e) {
        AppLogger.warning('Failed to save Google user to Firestore: $e');
      }

      await saveUserProfile(newUser);
      _currentDemoUser = newUser;
      return newUser;
    } catch (e) {
      AppLogger.error('Google Sign-In error', e);
      rethrow;
    }
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

    AppUser newUser;

    // 1. Try Firebase Authentication
    try {
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final fbUser = userCredential.user;
      if (fbUser != null) {
        await fbUser.updateDisplayName(fullName.trim());
        newUser = AppUser(
          id: fbUser.uid,
          email: email.trim(),
          fullName: fullName.trim(),
          userId: effectiveId,
          phone: phone?.trim(),
          role: role,
        );
      } else {
        throw Exception('Failed to create Firebase user account');
      }
    } catch (e) {
      AppLogger.warning('Firebase Auth signUp failed / offline: $e');
      if (e is FirebaseAuthException) {
        rethrow;
      }

      // Offline / Demo Mode Registration fallback
      newUser = AppUser(
        id: 'usr-${DateTime.now().millisecondsSinceEpoch}',
        email: email,
        fullName: fullName,
        userId: effectiveId,
        phone: phone,
        role: role,
      );
    }

    // 2. Persist user record to Cloud Firestore: users/{id}
    try {
      await FirebaseFirestore.instance.collection('users').doc(newUser.id).set(
        newUser.toJson()..['createdAt'] = FieldValue.serverTimestamp(),
        SetOptions(merge: true),
      );
      AppLogger.info('Saved user profile to Cloud Firestore: users/${newUser.id}');
    } catch (e) {
      AppLogger.warning('Cloud Firestore user write skipped: $e');
    }

    // 3. Save user record to Firebase Realtime Database: users/{id}
    try {
      final userRef = FirebaseDatabase.instance.ref('users/${newUser.id}');
      await userRef.set(newUser.toFirebaseMap());
      AppLogger.info('Saved user record to Firebase RTDB for ${newUser.email}');
    } catch (e) {
      AppLogger.warning('Firebase RTDB user write skipped (offline/demo mode): $e');
    }

    await saveUserProfile(newUser);
    return newUser;
  }

  /// Sign out current user
  Future<void> signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (!kIsWeb) {
        await GoogleSignIn().signOut();
      }
    } catch (e) {
      AppLogger.warning('Firebase signOut notice: $e');
    }

    if (_isSupabaseActive) {
      try {
        await _supabaseService.client!.auth.signOut();
      } catch (e) {
        AppLogger.error('Supabase signOut error', e);
      }
    }
    _currentDemoUser = null;
  }

  /// Switch user role for testing / viva demo presentation
  void switchDemoRole(UserRole role) {
    _currentDemoUser = _registeredUsers.firstWhere(
      (u) => u.role == role,
      orElse: () => _registeredUsers.first,
    );
  }
}
