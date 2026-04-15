import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/secure_storage_service.dart';
import '../services/session_manager.dart';
import 'package:flutter/foundation.dart';

class AuthProvider with ChangeNotifier {
  final supabase = Supabase.instance.client;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final SecureStorageService _secureStorage = SecureStorageService();
  final SessionManager _sessionManager = SessionManager();
  
  User? _user;
  bool _isLoading = true;
  StreamSubscription<AuthState>? _authSubscription;

  User? get user => _user;
  bool get isLoading => _isLoading;

  AuthProvider() {
    _initAuth();
  }

  Future<void> _initAuth() async {
    try {
      final session = supabase.auth.currentSession;
      _user = session?.user;
      
      // Store session token securely if logged in
      if (session?.accessToken != null) {
        await _secureStorage.setSessionToken(session!.accessToken);
      }
      
      _isLoading = false;
      notifyListeners();

      _authSubscription = supabase.auth.onAuthStateChange.listen((data) {
        _user = data.session?.user;
        
        if (kDebugMode) {
          print('[AuthProvider] Auth state changed: event=${data.event}, user=${_user?.email}');
        }
        
        // Update secure storage with new session token
        if (data.session?.accessToken != null) {
          _secureStorage.setSessionToken(data.session!.accessToken);
        }
        
        // Always notify on any auth state change so the UI stays in sync
        notifyListeners();
      });
    } catch (e) {
      if (kDebugMode) {
        print('Auth init error: $e');
      }
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signUp(String email, String password, String firstName) async {
    try {
      _isLoading = true;
      notifyListeners();

      await supabase.auth.signUp(
        email: email,
        password: password,
        data: {'first_name': firstName},
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> signIn(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      // Explicitly set user from response to guarantee navigation
      _user = response.user;
      _isLoading = false;
      
      // Notify immediately so navigation happens before storage operations
      notifyListeners();
      
      // Store token in background (don't block navigation on this)
      if (response.session?.accessToken != null) {
        _secureStorage.setSessionToken(response.session!.accessToken);
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Sign in with Google using Supabase's OAuth.
      // Deep linking scheme com.biohacker.app is configured in AndroidManifest.xml
      // and ios/Runner/Info.plist. Also register this URL in the Supabase dashboard
      // under Authentication > URL Configuration > Redirect URLs.
      final response = await supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'com.biohacker.app://login-callback',
      );

      // Note: OAuth flow is async and will complete via deep link callback
      // The auth state listener will handle user updates automatically
      _isLoading = false;
      notifyListeners();

      // If OAuth URL was not opened, throw error
      if (response == false) {
        throw Exception('Failed to open Google sign-in');
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      // Clear session manager
      _sessionManager.dispose();
      
      // Clear session-specific secure storage (preserve HIPAA ack + biometric prefs)
      await _secureStorage.clearSessionToken();
      await _secureStorage.clearLastActivityTimestamp();
      
      // Sign out from Supabase and Google
      await supabase.auth.signOut();
      await _googleSignIn.signOut();
      
      _user = null;
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }
  
  /// Initialize session manager after successful login
  void initializeSessionManager(BuildContext context) {
    _sessionManager.initialize(
      onSessionExpired: () {
        signOut();
      },
      context: context,
    );
  }
  
  /// Record user activity for session timeout tracking
  void recordActivity() {
    _sessionManager.resetActivity();
  }
  
  /// Get session manager instance
  SessionManager get sessionManager => _sessionManager;

  @override
  void dispose() {
    _authSubscription?.cancel();
    _sessionManager.dispose();
    super.dispose();
  }
}
