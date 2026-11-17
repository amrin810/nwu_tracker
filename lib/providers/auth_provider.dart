import 'package:flutter/foundation.dart';
import '../core/utils/app_logger.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';

/// Provider managing authentication state, active user profile and roles
class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;

  AppUser? _user;
  bool _isLoading = false;
  String? _errorMessage;

  AuthProvider({AuthRepository? authRepository})
      : _authRepository = authRepository ?? AuthRepository();

  AppUser? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;

  UserRole get currentRole => _user?.role ?? UserRole.student;
  bool get isAdmin => currentRole == UserRole.admin;
  bool get isDriver => currentRole == UserRole.driver;
  bool get isConductor => currentRole == UserRole.conductor;
  bool get isStudent => currentRole == UserRole.student;

  /// Check active user session on startup
  Future<void> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      _user = await _authRepository.getCurrentUser();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sign In
  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _authRepository.signIn(email: email, password: password);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Sign In with Google
  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _authRepository.signInWithGoogle();
      _isLoading = false;
      notifyListeners();
      return _user != null;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Sign Up
  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
    String? userId,
    String? studentId,
    String? phone,
    UserRole role = UserRole.student,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _authRepository.signUp(
        email: email,
        password: password,
        fullName: fullName,
        userId: userId ?? studentId,
        studentId: studentId ?? userId,
        phone: phone,
        role: role,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Sign Out
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    await _authRepository.signOut();
    _user = null;
    _isLoading = false;
    notifyListeners();
  }

  /// Demo helper to quickly switch role during viva presentation
  void switchDemoRole(UserRole role) {
    _authRepository.switchDemoRole(role);
    checkAuthStatus();
  }

  /// Update active user's profile details in memory and persist to storage
  Future<bool> updateProfile({
    required String fullName,
    required String email,
    String? studentId,
    String? phone,
    String? department,
    String? university,
    Uint8List? profileImageBytes,
    bool clearProfileImage = false,
  }) async {
    if (_user == null) return false;
    _user = _user!.copyWith(
      fullName: fullName,
      email: email,
      studentId: studentId,
      phone: phone,
      department: department,
      university: university,
      profileImageBytes: profileImageBytes,
      clearProfileImage: clearProfileImage,
    );
    notifyListeners();

    try {
      await _authRepository.saveUserProfile(_user!);
      return true;
    } catch (e) {
      AppLogger.error('Failed to save profile to persistent storage', e);
      return false;
    }
  }
}
