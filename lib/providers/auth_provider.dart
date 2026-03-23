import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthProvider with ChangeNotifier {
  final supabase = Supabase.instance.client;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  User? _user;
  bool _isLoading = true;

  User? get user => _user;
  bool get isLoading => _isLoading;

  AuthProvider() {
    _initAuth();
  }

  Future<void> _initAuth() async {
    try {
      final session = supabase.auth.currentSession;
      _user = session?.user;
      _isLoading = false;
      notifyListeners();

      supabase.auth.onAuthStateChange.listen((data) {
        _user = data.session?.user;
        notifyListeners();
      });
    } catch (e) {
      print('Auth init error: $e');
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

      await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      _isLoading = false;
      notifyListeners();
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
      await supabase.auth.signOut();
      await _googleSignIn.signOut();
      _user = null;
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }
}
