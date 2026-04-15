import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import '../theme/colors.dart';
import '../theme/wintermute_styles.dart';
import '../theme/wintermute_background.dart';
import '../widgets/cyberpunk_background.dart';
import '../utils/user_feedback.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _firstNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _showPassword = false;
  bool _isGoogleLoading = false;
  bool _disclaimerAcknowledged = false;
  String? _error;

  // Rate limiting
  int _failedAttempts = 0;
  bool _isLockedOut = false;
  int _lockoutSecondsRemaining = 0;
  Timer? _lockoutTimer;

  @override
  void initState() {
    super.initState();
    _loadDisclaimerState();
  }

  Future<void> _loadDisclaimerState() async {
    final prefs = await SharedPreferences.getInstance();
    final acknowledged = prefs.getBool('personal_use_acknowledged') ?? false;
    if (acknowledged && mounted) {
      setState(() => _disclaimerAcknowledged = true);
    }
  }

  Future<void> _saveDisclaimerAcknowledged() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('personal_use_acknowledged', true);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _lockoutTimer?.cancel();
    super.dispose();
  }

  void _startLockout() {
    _lockoutSecondsRemaining = 30;
    _isLockedOut = true;
    _lockoutTimer?.cancel();
    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) { timer.cancel(); return; }
      setState(() {
        _lockoutSecondsRemaining--;
        if (_lockoutSecondsRemaining <= 0) {
          _isLockedOut = false;
          _failedAttempts = 0;
          timer.cancel();
        }
      });
    });
  }

  Future<void> _handleSignUp() async {
    setState(() => _error = null);

    // Validate all fields are filled
    if (_firstNameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      setState(() => _error = 'Please fill in all fields');
      return;
    }

    // Validate email format with regex
    final email = _emailController.text.trim().toLowerCase();
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      setState(() => _error = 'Please enter a valid email address');
      return;
    }

    // Validate passwords match
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _error = 'Passwords do not match');
      return;
    }

    // Strengthen password validation - minimum 8 characters
    final password = _passwordController.text;
    if (password.length < 8) {
      setState(() => _error = 'Password must be at least 8 characters');
      return;
    }

    // Check for uppercase letter
    if (!password.contains(RegExp(r'[A-Z]'))) {
      setState(() => _error = 'Password must contain at least one uppercase letter');
      return;
    }

    // Check for lowercase letter
    if (!password.contains(RegExp(r'[a-z]'))) {
      setState(() => _error = 'Password must contain at least one lowercase letter');
      return;
    }

    // Check for number
    if (!password.contains(RegExp(r'[0-9]'))) {
      setState(() => _error = 'Password must contain at least one number');
      return;
    }

    if (!_disclaimerAcknowledged) {
      setState(() => _error = 'You must acknowledge the personal use disclaimer to continue');
      return;
    }

    try {
      await _saveDisclaimerAcknowledged();
      // FUNC-006: trim whitespace from email and name before passing to signUp
      await ref.read(authProviderProvider).signUp(
        _emailController.text.trim().toLowerCase(),
        _passwordController.text,
        _firstNameController.text.trim(),
      );

      _failedAttempts = 0;
      if (mounted) {
        UserFeedback.showSuccess(
          context,
          'Account created successfully! Check your email to verify.',
        );
        Navigator.pop(context);
      }
    } catch (e) {
      final friendlyMessage = UserFeedback.getFriendlyErrorMessage(e);
      setState(() {
        _error = friendlyMessage;
        _failedAttempts++;
        if (_failedAttempts >= 5) _startLockout();
      });
    }
  }

  Widget _buildDisclaimerBox() {
    const amber = Color(0xFFFFB300);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1200),
        border: Border.all(color: amber, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '⚠ PERSONAL USE ONLY',
            style: TextStyle(
              color: amber,
              fontFamily: 'monospace',
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'This app is a personal health tracking tool, not a medical device or clinical service. It is not HIPAA-covered software and should not be used to store clinical or insurance-related health records.\n\nBy continuing, you confirm this app is for your own personal biometric tracking only.',
            style: TextStyle(
              color: amber.withOpacity(0.85),
              fontFamily: 'monospace',
              fontSize: 11,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => setState(() => _disclaimerAcknowledged = !_disclaimerAcknowledged),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    border: Border.all(color: amber, width: 1.5),
                    color: _disclaimerAcknowledged ? amber : Colors.transparent,
                  ),
                  child: _disclaimerAcknowledged
                      ? const Icon(Icons.check, color: Colors.black, size: 14)
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'I understand this is for personal use only',
                    style: TextStyle(
                      color: amber,
                      fontFamily: 'monospace',
                      fontSize: 11,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _error = null;
      _isGoogleLoading = true;
    });

    try {
      await ref.read(authProviderProvider).signInWithGoogle();
      // Success is handled by navigation in main.dart via auth state change
    } catch (e) {
      final friendlyMessage = UserFeedback.getFriendlyErrorMessage(e);
      setState(() {
        _error = friendlyMessage;
        _isGoogleLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WintermmuteBackground(
      child: CyberpunkBackground(
        cityOpacity: 0.5,
        rainOpacity: 0.35,
        rainParticleCount: 60,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: const Text('CREATE ACCOUNT'),
            backgroundColor: AppColors.background,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.primary),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SafeArea(
            child: Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
              // First Name Field
              TextField(
                controller: _firstNameController,
                style: const TextStyle(color: AppColors.textLight),
                decoration: InputDecoration(
                  labelText: 'First Name',
                  labelStyle: const TextStyle(color: AppColors.textMid),
                  hintText: 'Your name',
                  hintStyle: const TextStyle(color: AppColors.textDim),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                ),
              ),
              const SizedBox(height: 16),

              // Email Field
              TextField(
                controller: _emailController,
                style: const TextStyle(color: AppColors.textLight),
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: const TextStyle(color: AppColors.textMid),
                  hintText: 'user@example.com',
                  hintStyle: const TextStyle(color: AppColors.textDim),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                ),
              ),
              const SizedBox(height: 16),

              // Password Field
              TextField(
                controller: _passwordController,
                style: const TextStyle(color: AppColors.textLight),
                obscureText: !_showPassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: const TextStyle(color: AppColors.textMid),
                  hintText: '••••••••',
                  hintStyle: const TextStyle(color: AppColors.textDim),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showPassword ? Icons.visibility : Icons.visibility_off,
                      color: AppColors.textMid,
                    ),
                    onPressed: () => setState(() => _showPassword = !_showPassword),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Confirm Password Field
              TextField(
                controller: _confirmPasswordController,
                style: const TextStyle(color: AppColors.textLight),
                obscureText: !_showPassword,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  labelStyle: const TextStyle(color: AppColors.textMid),
                  hintText: '••••••••',
                  hintStyle: const TextStyle(color: AppColors.textDim),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                ),
              ),
              const SizedBox(height: 24),

              // Compliance Disclaimer
              _buildDisclaimerBox(),
              const SizedBox(height: 20),

              // Error Message
              if (_error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    border: Border.all(color: AppColors.error),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: AppColors.error, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 24),

              // Sign Up Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLockedOut ? null : _handleSignUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isLockedOut ? AppColors.error.withOpacity(0.3) : AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLockedOut
                      ? Text(
                          'TRY AGAIN IN ${_lockoutSecondsRemaining}s',
                          style: const TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            letterSpacing: 1,
                          ),
                        )
                      : const Text(
                          'CREATE ACCOUNT',
                          style: TextStyle(
                            color: AppColors.background,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: 1,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 32),

              // Divider with OR text
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 1,
                      color: AppColors.border,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'OR',
                      style: TextStyle(
                        color: AppColors.textMid,
                        fontSize: 12,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 1,
                      color: AppColors.border,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Google Sign-In Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: _isGoogleLoading ? null : _handleGoogleSignIn,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primary, width: 1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    backgroundColor: Colors.transparent,
                  ),
                  child: _isGoogleLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // SEC-004: local Google icon — no external CDN dependency
                            _GoogleIcon(size: 20),
                            const SizedBox(width: 12),
                            const Text(
                              'CONTINUE WITH GOOGLE',
                              style: TextStyle(
                                color: AppColors.textLight,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
                  ],
                ),
              ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _ScanlinesPainter(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Inline Google "G" icon — avoids external CDN dependency (SEC-004).
/// Replace with a bundled SVG asset once the Google SVG is added to assets/.
class _GoogleIcon extends StatelessWidget {
  final double size;
  const _GoogleIcon({this.size = 20});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size / 5),
      ),
      child: Center(
        child: Text(
          'G',
          style: TextStyle(
            color: const Color(0xFF4285F4),
            fontSize: size * 0.72,
            fontWeight: FontWeight.bold,
            height: 1,
          ),
        ),
      ),
    );
  }
}

class _ScanlinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withOpacity(0.07)
      ..strokeWidth = 1;

    for (double y = 0; y < size.height; y += 3) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
