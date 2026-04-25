import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/profile_repository.dart';
import '../../stores/user_state_store.dart';

class AuthController extends ChangeNotifier {
  AuthController(
    this._authRepository, {
    required UserStateStore userStateStore,
    ProfileRepository? profileRepository,
  })  : _userStateStore = userStateStore,
        _profileRepository = profileRepository {
    _currentUser = _authRepository.currentUser;
    if (kDebugMode) {
      debugPrint(
        '[auth] initial auth state: ${_currentUser != null ? 'signedIn' : 'signedOut'}',
      );
    }

    _authSubscription =
        _authRepository.authStateChanges.listen(_handleAuthState);
    _finishSessionCheck();
    if (_currentUser != null) {
      unawaited(_syncCurrentUserProfile(reason: 'controller_init'));
    }
  }

  final AuthRepository _authRepository;
  final UserStateStore _userStateStore;
  final ProfileRepository? _profileRepository;
  StreamSubscription<AuthState>? _authSubscription;

  User? _currentUser;
  bool _isLoading = false;
  bool _isCheckingSession = true;
  bool _isSyncingProfile = false;
  String? _errorMessage;
  String? _noticeMessage;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isCheckingSession => _isCheckingSession;
  String? get errorMessage => _errorMessage;
  String? get noticeMessage => _noticeMessage;
  bool get isAuthenticated => _currentUser != null;

  void clearError() {
    if (_errorMessage == null && _noticeMessage == null) return;
    _errorMessage = null;
    _noticeMessage = null;
    notifyListeners();
  }

  Future<AuthResponse?> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim();
    if (!_isValidEmail(normalizedEmail)) {
      _setError('Please enter a valid email address.');
      return null;
    }
    if (password.isEmpty) {
      _setError('Email or password is incorrect.');
      return null;
    }

    _setLoading(true);
    _setError(null);
    _setNotice(null);
    if (kDebugMode) {
      debugPrint('[auth] sign in started: $normalizedEmail');
    }

    try {
      final response = await _authRepository.signInWithEmailPassword(
        email: normalizedEmail,
        password: password,
      );
      _currentUser = _authRepository.currentUser ?? response.user;
      if (_currentUser == null) {
        _setError('Email or password is incorrect.');
        return null;
      }

      if (kDebugMode) {
        debugPrint('[auth] sign in succeeded: userId=${_currentUser!.id}');
        debugPrint('[auth] currentUser after sign in: yes');
      }
      await _verifyProfileBootstrapRows();
      await _syncCurrentUserProfile(reason: 'sign_in');
      notifyListeners();
      return response;
    } on AuthException catch (error) {
      if (kDebugMode) {
        debugPrint('[auth] sign in failed (AuthException): ${error.message}');
      }
      _setError(_mapAuthError(error.message, isSignIn: true));
      return null;
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[auth] sign in failed (unexpected): $error');
      }
      _setError('Connection error. Please try again.');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<AuthResponse?> signUpWithEmailPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final normalizedEmail = email.trim();
    if (!_isValidEmail(normalizedEmail)) {
      _setError('Please enter a valid email address.');
      return null;
    }
    if (password.length < 6) {
      _setError('Password must be at least 6 characters.');
      return null;
    }

    _setLoading(true);
    _setError(null);
    _setNotice(null);
    if (kDebugMode) {
      debugPrint('[auth] sign up started: $normalizedEmail');
    }

    try {
      final response = await _authRepository.signUpWithEmailPassword(
        email: normalizedEmail,
        password: password,
        displayName: displayName,
      );
      _currentUser = response.session?.user ?? _authRepository.currentUser;
      if (_currentUser == null && response.user != null) {
        _setNotice(
          'Account created. Please check your email to confirm your account.',
        );
        if (kDebugMode) {
          debugPrint(
            '[auth] sign up created user without session; email confirmation is likely enabled.',
          );
          debugPrint('[auth] currentUser after sign up: no');
        }
        return response;
      }

      if (_currentUser == null) {
        _setError('Authentication failed. Please try again.');
        return null;
      }

      await _verifyProfileBootstrapRows();
      await _syncCurrentUserProfile(reason: 'sign_up');

      if (kDebugMode) {
        debugPrint('[auth] sign up succeeded: userId=${_currentUser!.id}');
        debugPrint('[auth] currentUser after sign up: yes');
      }
      notifyListeners();
      return response;
    } on AuthException catch (error) {
      if (kDebugMode) {
        debugPrint('[auth] sign up failed (AuthException): ${error.message}');
      }
      _setError(_mapAuthError(error.message, isSignIn: false));
      return null;
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[auth] sign up failed (unexpected): $error');
      }
      _setError('Connection error. Please try again.');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    _setLoading(true);
    _setError(null);
    _setNotice(null);
    try {
      await _authRepository.signOut();
      _currentUser = null;
      await _userStateStore.clearSupabaseIdentity();
      notifyListeners();
      if (kDebugMode) {
        debugPrint('[auth] sign out succeeded');
        debugPrint('[auth] sign out cleared/updated user state');
      }
    } on AuthException catch (error) {
      if (kDebugMode) {
        debugPrint('[auth] sign out failed (AuthException): ${error.message}');
      }
      _setError(_mapAuthError(error.message, isSignIn: true));
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[auth] sign out failed (unexpected): $error');
      }
      _setError('Connection error. Please try again.');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _verifyProfileBootstrapRows() async {
    final profileRepository = _profileRepository;
    if (profileRepository == null || !kDebugMode) return;

    try {
      final profile = await profileRepository.fetchCurrentUserProfile();
      if (profile == null) {
        debugPrint(
          '[auth] Profile row not found for current Supabase user.',
        );
      } else {
        debugPrint('[auth] profile verification succeeded');
      }

      final progress = await profileRepository.fetchCurrentUserProgress();
      if (progress == null) {
        debugPrint(
          '[auth] warning: Supabase user created but user_progress row was not found. Check database trigger.',
        );
      } else {
        debugPrint('[auth] user_progress verification succeeded');
      }
    } catch (error) {
      debugPrint('[auth] warning: profile trigger verification failed: $error');
    }
  }

  void _handleAuthState(AuthState state) {
    _currentUser = state.session?.user ?? _authRepository.currentUser;
    if (kDebugMode) {
      debugPrint(
        '[auth] auth state changed: ${_currentUser != null ? 'signedIn' : 'signedOut'} (event=${state.event.name})',
      );
    }
    if (_currentUser != null) {
      unawaited(
          _syncCurrentUserProfile(reason: 'auth_state_${state.event.name}'));
    } else {
      unawaited(_userStateStore.clearSupabaseIdentity());
      if (kDebugMode) {
        debugPrint('[auth] sign out cleared/updated user state');
      }
    }
    _finishSessionCheck();
    notifyListeners();
  }

  Future<void> _syncCurrentUserProfile({required String reason}) async {
    if (_isSyncingProfile) return;

    final user = _currentUser ?? _authRepository.currentUser;
    if (user == null) return;

    _isSyncingProfile = true;
    Map<String, dynamic>? profile;

    if (kDebugMode) {
      debugPrint('[auth] profile fetch started ($reason)');
    }

    try {
      if (_userStateStore.state == null && !_userStateStore.isLoading) {
        await _userStateStore.load();
      }

      profile = await _profileRepository?.fetchCurrentUserProfile();
      if (profile == null && kDebugMode) {
        debugPrint('[auth] Profile row not found for current Supabase user.');
      }

      final remoteDisplayName = _normalizedValue(profile?['display_name']);
      final metadataDisplayName =
          _normalizedValue(user.userMetadata?['display_name']);
      final metadataName = _normalizedValue(user.userMetadata?['name']);
      final emailPrefix = _emailPrefix(user.email);
      final existingLocalName = _normalizedValue(_userStateStore.displayName);
      final resolvedDisplayName = _firstNonEmpty(<String?>[
            remoteDisplayName,
            metadataDisplayName,
            metadataName,
            emailPrefix,
            existingLocalName,
          ]) ??
          '';

      final resolvedEmail = _firstNonEmpty(<String?>[
        _normalizedValue(profile?['email']),
        _normalizedValue(user.email),
        _normalizedValue(_userStateStore.authEmail),
      ]);

      final fallbackSource = _displayNameFallbackSource(
        hasProfileDisplayName: remoteDisplayName.isNotEmpty,
        metadataDisplayName: metadataDisplayName,
        metadataName: metadataName,
        emailPrefix: emailPrefix,
        existingLocalName: existingLocalName,
      );

      if (kDebugMode) {
        debugPrint(
          '[auth] profile fetch succeeded with hasDisplayName: ${remoteDisplayName.isNotEmpty ? 'yes' : 'no'}',
        );
        if (fallbackSource != null) {
          debugPrint('[auth] fallback used: $fallbackSource');
        }
      }

      await _userStateStore.applySupabaseIdentity(
        userId: user.id,
        email: resolvedEmail,
        displayName: resolvedDisplayName,
        avatarUrl: _normalizedValue(profile?['avatar_url']),
      );

      if (kDebugMode) {
        debugPrint('[auth] display name applied to UserStateStore');
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[auth] warning: profile sync failed: $error');
      }
    } finally {
      _isSyncingProfile = false;
    }
  }

  String? _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      final normalized = _normalizedValue(value);
      if (normalized.isNotEmpty) return normalized;
    }
    return null;
  }

  String _normalizedValue(dynamic value) => (value ?? '').toString().trim();

  String _emailPrefix(String? email) {
    final normalizedEmail = _normalizedValue(email);
    if (normalizedEmail.isEmpty) return '';
    final atIndex = normalizedEmail.indexOf('@');
    if (atIndex <= 0) return '';
    return normalizedEmail.substring(0, atIndex).trim();
  }

  String? _displayNameFallbackSource({
    required bool hasProfileDisplayName,
    required String metadataDisplayName,
    required String metadataName,
    required String emailPrefix,
    required String existingLocalName,
  }) {
    if (hasProfileDisplayName) {
      return null;
    }
    if (metadataDisplayName.isNotEmpty) {
      return 'auth user_metadata.display_name';
    }
    if (metadataName.isNotEmpty) {
      return 'auth user_metadata.name';
    }
    if (emailPrefix.isNotEmpty) {
      return 'email prefix';
    }
    if (existingLocalName.isNotEmpty) {
      return 'existing local/default Rutio name';
    }
    return 'none';
  }

  void _finishSessionCheck() {
    if (!_isCheckingSession) return;
    _isCheckingSession = false;
    notifyListeners();
  }

  void _setLoading(bool value) {
    if (_isLoading == value) return;
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? value) {
    if (_errorMessage == value) return;
    _errorMessage = value;
    notifyListeners();
  }

  void _setNotice(String? value) {
    if (_noticeMessage == value) return;
    _noticeMessage = value;
    notifyListeners();
  }

  bool _isValidEmail(String value) {
    final email = value.trim();
    if (email.isEmpty) return false;
    final regex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return regex.hasMatch(email);
  }

  String _mapAuthError(
    String rawMessage, {
    required bool isSignIn,
  }) {
    final message = rawMessage.toLowerCase();

    if (message.contains('network') ||
        message.contains('socket') ||
        message.contains('connection') ||
        message.contains('timeout')) {
      return 'Connection error. Please try again.';
    }

    if (message.contains('invalid email') ||
        message.contains('email address') ||
        message.contains('email format')) {
      return 'Please enter a valid email address.';
    }

    if (message.contains('password') &&
        (message.contains('weak') ||
            message.contains('short') ||
            message.contains('at least'))) {
      return 'Password must be at least 6 characters.';
    }

    if (!isSignIn &&
        (message.contains('already registered') ||
            message.contains('already exists') ||
            message.contains('user already registered') ||
            message.contains('duplicate key'))) {
      return 'An account with this email may already exist. Try signing in instead.';
    }

    if (isSignIn) {
      return 'Email or password is incorrect.';
    }

    return 'Authentication failed. Please try again.';
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _authSubscription = null;
    super.dispose();
  }
}
