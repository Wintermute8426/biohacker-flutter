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

      // Sign in with Google using Supabase's OAuth
      await supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'com.example.biohacker://login-callback',
      );

      _isLoading = false;
      notifyListeners();
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
