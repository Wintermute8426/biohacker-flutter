import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding/welcome_screen.dart';
import 'screens/hipaa_notice_screen.dart';
import 'services/onboarding_service.dart';
import 'services/notification_service.dart';
import 'services/notification_scheduler.dart';
import 'services/secure_storage_service.dart';
import 'services/biometric_auth_service.dart';
import 'services/subscription_service.dart';
import 'screens/paywall_screen.dart';
import 'theme/colors.dart';

String? _initError;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Try loading .env asset; fall back to dart-define values for release builds.
  // To build for release: flutter build apk --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    if (kDebugMode) {
      print('[main] .env not found as asset, falling back to dart-define: $e');
    }
  }

  // Resolve values: .env takes priority, then dart-define compile-time constants.
  final supabaseUrl = dotenv.env['SUPABASE_URL'] ??
      const String.fromEnvironment('SUPABASE_URL');
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ??
      const String.fromEnvironment('SUPABASE_ANON_KEY');

  // Debug logging
  print('[BIOHACKER INIT] Supabase URL present: ${supabaseUrl.isNotEmpty}');
  print('[BIOHACKER INIT] Supabase key present: ${supabaseAnonKey.isNotEmpty}');
  print('[BIOHACKER INIT] URL length: ${supabaseUrl.length}');
  print('[BIOHACKER INIT] Key length: ${supabaseAnonKey.length}');

  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    _initError =
        'Missing Supabase credentials.\n\nFor development: add .env to pubspec assets and ensure SUPABASE_URL and SUPABASE_ANON_KEY are set.\n\nFor release builds: pass --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...';
    runApp(const ProviderScope(child: MyApp()));
    return;
  }

  try {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  } catch (e) {
    _initError = 'Failed to initialize Supabase: $e';
    runApp(const ProviderScope(child: MyApp()));
    return;
  }

  // Initialize notification service and reschedule any pending notifications
  try {
    await NotificationService().initialize();
    await NotificationService().requestPermissions();
  } catch (e) {
    if (kDebugMode) {
      print('[main] Notification init error (non-fatal): $e');
    }
  }
  // Reschedule runs after auth is resolved (see OnboardingCheck)

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

// Riverpod provider for AuthProvider
final authProviderProvider = ChangeNotifierProvider<AuthProvider>((ref) {
  return AuthProvider();
});

class MyApp extends ConsumerWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (_initError != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: const Color(0xFF0A0A0F),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.error_outline, color: Color(0xFFFF4444), size: 48),
                  const SizedBox(height: 16),
                  const Text(
                    'Initialization Error',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _initError!,
                    style: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 14, height: 1.5),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final authProvider = ref.watch(authProviderProvider);

    return MaterialApp(
      title: 'Biohacker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          surfaceTintColor: AppColors.background,
          elevation: 0,
        ),
      ),
      routes: {
        '/home': (context) => const HomeScreen(),
      },
      home: authProvider.isLoading
          ? Scaffold(
              backgroundColor: AppColors.background,
              body: Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              ),
            )
          : authProvider.user != null
              ? const OnboardingCheck()
              : const LoginScreen(),
    );
  }
}

/// OnboardingCheck determines whether to show HIPAA notice, onboarding, or home screen
class OnboardingCheck extends ConsumerStatefulWidget {
  const OnboardingCheck({Key? key}) : super(key: key);

  @override
  ConsumerState<OnboardingCheck> createState() => _OnboardingCheckState();
}

class _OnboardingCheckState extends ConsumerState<OnboardingCheck> {
  final SecureStorageService _secureStorage = SecureStorageService();
  final BiometricAuthService _biometricAuth = BiometricAuthService();
  bool _checkingHipaa = true;
  bool _hipaaAcknowledged = false;
  bool _checkingBiometric = false;

  @override
  void initState() {
    super.initState();
    _checkHipaaAcknowledgment();
  }

  Future<void> _checkHipaaAcknowledgment() async {
    final acknowledged = await _secureStorage.getHipaaAcknowledged();
    setState(() {
      _hipaaAcknowledged = acknowledged;
      _checkingHipaa = false;
    });

    // If HIPAA acknowledged, check for biometric authentication
    if (acknowledged && mounted) {
      _checkBiometricAuth();
    }
  }

  Future<void> _checkBiometricAuth() async {
    final biometricEnabled = await _biometricAuth.isBiometricEnabled();
    
    if (biometricEnabled) {
      setState(() {
        _checkingBiometric = true;
      });

      final authenticated = await _biometricAuth.authenticate(
        localizedReason: 'Verify your identity to access Biohacker',
      );

      if (!authenticated && mounted) {
        // Biometric failed - logout user
        final authProvider = ref.read(authProviderProvider);
        await authProvider.signOut();
        return;
      }

      setState(() {
        _checkingBiometric = false;
      });
    }

    // Initialize session manager after successful authentication
    if (mounted) {
      final authProvider = ref.read(authProviderProvider);
      authProvider.initializeSessionManager(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingHipaa || _checkingBiometric) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: AppColors.primary,
              ),
              const SizedBox(height: 16),
              Text(
                _checkingBiometric ? 'Authenticating...' : 'Loading...',
                style: TextStyle(
                  color: AppColors.textMid,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Show HIPAA notice if not acknowledged
    if (!_hipaaAcknowledged) {
      return HipaaNoticeScreen(
        onAcknowledged: () {
          setState(() {
            _hipaaAcknowledged = true;
          });
          _checkBiometricAuth();
        },
      );
    }

    // Check onboarding status
    final onboardingStatus = ref.watch(isOnboardingCompletedProvider);

    return onboardingStatus.when(
      data: (isCompleted) {
        // Reschedule notifications for authenticated users
        NotificationScheduler().rescheduleAll();
        if (isCompleted) {
          return const _SubscriptionGate();
        } else {
          return const WelcomeScreen();
        }
      },
      loading: () => Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
          ),
        ),
      ),
      error: (error, stack) {
        if (kDebugMode) {
          print('[OnboardingCheck] Error checking onboarding status: $error');
        }
        // On error, assume onboarding is complete and show home screen
        return const HomeScreen();
      },
    );
  }
}

/// _SubscriptionGate checks subscription status and shows paywall if trial expired
class _SubscriptionGate extends StatefulWidget {
  const _SubscriptionGate({Key? key}) : super(key: key);

  @override
  State<_SubscriptionGate> createState() => _SubscriptionGateState();
}

class _SubscriptionGateState extends State<_SubscriptionGate> {
  bool _checkingSubscription = true;
  bool _shouldShowPaywall = false;

  @override
  void initState() {
    super.initState();
    _checkSubscription();
  }

  Future<void> _checkSubscription() async {
    try {
      final status = await SubscriptionService().getSubscriptionStatus();
      setState(() {
        _shouldShowPaywall = status.isExpired && !status.hasPremiumAccess;
        _checkingSubscription = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('[SubscriptionGate] Error checking subscription: $e');
      }
      // On error, let user proceed (fail open)
      setState(() {
        _checkingSubscription = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingSubscription) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
          ),
        ),
      );
    }

    if (_shouldShowPaywall) {
      return PaywallScreen();
    }

    return const HomeScreen();
  }
}
