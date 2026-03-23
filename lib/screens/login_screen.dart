import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../main.dart';
import '../theme/colors.dart';
import '../theme/wintermute_styles.dart';
import '../theme/wintermute_background.dart';
import '../widgets/cyberpunk_rain.dart';
import '../widgets/city_background.dart';
import '../utils/user_feedback.dart';
import 'signup_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _showPassword = false;
  bool _isGoogleLoading = false;
  bool _isLoading = false;
  String? _error;

  // Boot sequence
  int _bootStep = 0;
  bool _loginSuccess = false;
  Timer? _bootTimer;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  static const List<String> _bootMessages = [
    'INITIATING PROTOCOL...',
    'VERIFYING CREDENTIALS...',
    'ACCESSING SOVEREIGN NETWORK...',
    'CLEARANCE GRANTED',
  ];

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    )..repeat(reverse: true);
    _glowAnimation =
        Tween<double>(begin: 0.4, end: 1.0).animate(_glowController);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _bootTimer?.cancel();
    _glowController.dispose();
    super.dispose();
  }

  void _startBootSequence() {
    setState(() {
      _bootStep = 0;
      _loginSuccess = false;
    });
    _bootTimer?.cancel();
    _bootTimer =
        Timer.periodic(const Duration(milliseconds: 650), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_bootStep < _bootMessages.length - 2) {
          _bootStep++;
        }
      });
    });
  }

  void _completeBootSequence(bool success) {
    _bootTimer?.cancel();
    if (mounted) {
      setState(() {
        _bootStep = success ? _bootMessages.length - 1 : 0;
        _loginSuccess = success;
      });
    }
  }

  Future<void> _handleLogin() async {
    setState(() {
      _error = null;
      _isLoading = true;
    });

    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() {
        _error = 'AUTHENTICATION FAILED: Missing credentials';
        _isLoading = false;
      });
      return;
    }

    _startBootSequence();

    try {
      await ref.read(authProviderProvider).signIn(
            _emailController.text,
            _passwordController.text,
          );
      _completeBootSequence(true);
      // Success is handled by navigation in main.dart via auth state change
    } catch (e) {
      _completeBootSequence(false);
      final friendlyMessage = UserFeedback.getFriendlyErrorMessage(e);
      if (mounted) {
        setState(() {
          _error = 'ACCESS DENIED: $friendlyMessage';
          _isLoading = false;
        });
      }
    }
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
      if (mounted) {
        setState(() {
          _error = 'OAUTH ERROR: $friendlyMessage';
          _isGoogleLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WintermmuteBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Stack(
            children: [
              // City background layer
              const Positioned.fill(
                child: CityBackground(
                  enabled: true,
                  animateLights: true,
                  opacity: 0.5,
                ),
              ),
              // Rain effect layer
              const Positioned.fill(
                child: CyberpunkRain(
                  enabled: true,
                  particleCount: 60,
                  opacity: 0.35,
                ),
              ),
              SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                        height: MediaQuery.of(context).size.height * 0.03),

                    // Logo
                    Center(
                      child: Image.asset(
                        'assets/logo/biohacker-neon-logo-vectorized.png',
                        width: 280,
                        height: 260,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Email Field
                    _buildFieldLabel('> EMAIL_ADDRESS:'),
                    const SizedBox(height: 4),
                    _buildInputField(
                      controller: _emailController,
                      hint: 'operator@nexus.net',
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),

                    // Password Field
                    _buildFieldLabel('> ACCESS_CODE:'),
                    const SizedBox(height: 4),
                    _buildInputField(
                      controller: _passwordController,
                      hint: '••••••••••••',
                      obscureText: !_showPassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _showPassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: AppColors.textMid,
                          size: 18,
                        ),
                        onPressed: () =>
                            setState(() => _showPassword = !_showPassword),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Reset password row
                    // FUNC-002: "Remember Me" toggle removed — session persistence
                    // not yet implemented. Supabase default session behaviour applies.
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: AppColors.surface,
                              content: Text(
                                '[SYS]: Password reset link sent to registered email',
                                style: TextStyle(
                                  fontFamily: 'JetBrains Mono',
                                  fontSize: 12,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'RESET ACCESS',
                          style: TextStyle(
                            color: AppColors.primary.withOpacity(0.65),
                            fontSize: 11,
                            fontFamily: 'JetBrains Mono',
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Error display - terminal style
                    if (_error != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.07),
                          border:
                              Border.all(color: AppColors.error.withOpacity(0.6)),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.error_outline,
                                color: AppColors.error, size: 14),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _error!,
                                style: const TextStyle(
                                  color: AppColors.error,
                                  fontSize: 12,
                                  fontFamily: 'JetBrains Mono',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Login Button / Boot sequence
                    _buildLoginButton(),
                    const SizedBox(height: 12),

                    // Register button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton(
                        onPressed: _isLoading
                            ? null
                            : () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                      builder: (_) => const SignUpScreen()),
                                ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: AppColors.primary.withOpacity(0.45),
                            width: 1,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        child: Text(
                          'REGISTER NEW OPERATOR',
                          style: TextStyle(
                            color: AppColors.primary.withOpacity(0.75),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            fontFamily: 'JetBrains Mono',
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Divider
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 1,
                            color: AppColors.primary.withOpacity(0.18),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Text(
                            '// OR //',
                            style: TextStyle(
                              color: AppColors.textDim,
                              fontSize: 11,
                              fontFamily: 'JetBrains Mono',
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            height: 1,
                            color: AppColors.primary.withOpacity(0.18),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // Google OAuth button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton(
                        onPressed: _isGoogleLoading || _isLoading
                            ? null
                            : _handleGoogleSignIn,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: AppColors.primary.withOpacity(0.35),
                            width: 1,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          backgroundColor: Colors.transparent,
                        ),
                        child: _isGoogleLoading
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.primary),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // SEC-004: local Google icon — no external CDN dependency
                                  _GoogleIcon(size: 18),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'OAUTH // GOOGLE',
                                    style: TextStyle(
                                      color: AppColors.textLight,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      fontFamily: 'JetBrains Mono',
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
              // Scanlines overlay
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
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        color: AppColors.primary.withOpacity(0.75),
        fontSize: 11,
        fontFamily: 'JetBrains Mono',
        letterSpacing: 1,
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        boxShadow: WintermmuteStyles.cyanGlowShadow,
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(
          color: AppColors.textLight,
          fontFamily: 'JetBrains Mono',
          fontSize: 14,
        ),
        keyboardType: keyboardType,
        obscureText: obscureText,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            color: AppColors.textDim,
            fontFamily: 'JetBrains Mono',
            fontSize: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: AppColors.primary),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(4),
            borderSide:
                BorderSide(color: AppColors.primary.withOpacity(0.45)),
          ),
          filled: true,
          fillColor: AppColors.surface,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    if (_isLoading) {
      final isSuccess = _loginSuccess;
      return AnimatedBuilder(
        animation: _glowAnimation,
        builder: (context, child) {
          final glowColor = isSuccess ? AppColors.accent : AppColors.primary;
          return Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(
                color: glowColor.withOpacity(0.6 + _glowAnimation.value * 0.4),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: glowColor.withOpacity(0.15 + _glowAnimation.value * 0.1),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _bootMessages[_bootStep.clamp(0, _bootMessages.length - 1)],
                  style: TextStyle(
                    color: glowColor,
                    fontSize: 13,
                    fontFamily: 'JetBrains Mono',
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: 160,
                  child: LinearProgressIndicator(
                    backgroundColor: glowColor.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(
                        glowColor.withOpacity(0.8)),
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        boxShadow: WintermmuteStyles.cyanGlowShadow,
      ),
      child: ElevatedButton(
        onPressed: _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        child: const Text(
          'AUTHENTICATE',
          style: TextStyle(
            color: AppColors.background,
            fontWeight: FontWeight.bold,
            fontSize: 16,
            fontFamily: 'JetBrains Mono',
            letterSpacing: 2,
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
