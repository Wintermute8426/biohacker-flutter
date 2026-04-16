import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
import 'models/subscription_status.dart';
import 'screens/paywall_screen.dart';
import 'theme/colors.dart';

/// Global navigator key for notification tap routing
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

String? _initError;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Credentials injected at build time via --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
  // Never bundled as assets. See FIXES_APPLIED.md for the correct build command.
  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  // Debug logging
  if (kDebugMode) {
    print('[BIOHACKER INIT] Supabase URL present: ${supabaseUrl.isNotEmpty}');
  }
  if (kDebugMode) {
    print('[BIOHACKER INIT] Supabase key present: ${supabaseAnonKey.isNotEmpty}');
  }
  if (kDebugMode) {
    print('[BIOHACKER INIT] URL length: ${supabaseUrl.length}');
  }
  if (kDebugMode) {
    print('[BIOHACKER INIT] Key length: ${supabaseAnonKey.length}');
  }

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
    print('[MAIN] MyApp.build: isLoading=${authProvider.isLoading}, user=${authProvider.user?.email}');

    return MaterialApp(
      title: 'Biohacker',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
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
    print('[ONBOARDING] _checkHipaaAcknowledgment() started');
    bool acknowledged = false;
    try {
      acknowledged = await _secureStorage.getHipaaAcknowledged();
      print('[ONBOARDING] HIPAA acknowledged: $acknowledged');
    } catch (e) {
      // flutter_secure_storage can throw PlatformException on some Android
      // devices on first use. Default to false (show HIPAA notice).
      print('[ONBOARDING] SecureStorage error reading HIPAA ack: $e');
    }
    if (!mounted) return;
    setState(() {
      _hipaaAcknowledged = acknowledged;
      _checkingHipaa = false;
    });

    // If HIPAA acknowledged, check for biometric authentication
    if (acknowledged && mounted) {
      _checkBiometricAuth();
    } else {
      print('[ONBOARDING] HIPAA not acknowledged — showing HipaaNoticeScreen');
    }
  }

  Future<void> _checkBiometricAuth() async {
    try {
      final biometricEnabled = await _biometricAuth.isBiometricEnabled();
    
      if (biometricEnabled && mounted) {
        setState(() {
          _checkingBiometric = true;
        });

        final authenticated = await _biometricAuth.authenticate(
          localizedReason: 'Verify your identity to access Biohacker',
        );

        if (!authenticated && mounted) {
          // Biometric failed or cancelled - just skip biometric, don't log out
          if (kDebugMode) print('[OnboardingCheck] Biometric failed/cancelled, proceeding without biometric');
        }

        if (mounted) {
          setState(() {
            _checkingBiometric = false;
          });
        }
      }
    } catch (e) {
      if (kDebugMode) print('[OnboardingCheck] Biometric check error (non-fatal): $e');
      if (mounted) setState(() { _checkingBiometric = false; });
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
      final subscriptionService = SubscriptionService();
      SubscriptionStatus? status = await subscriptionService.getSubscriptionStatus();

      // Auto-start trial for new users who have no subscription data at all
      if (status == null || (status.tier == 'free' && status.subscriptionStartsAt == null)) {
        try {
          await subscriptionService.startFreeTrial();
          status = await subscriptionService.getSubscriptionStatus();
        } catch (trialError) {
          if (kDebugMode) {
            print('[SubscriptionGate] Auto-trial start failed (non-fatal): $trialError');
          }
          // Fail open: proceed without trial if it can't be started
        }
      }

      final shouldShowPaywall = status?.isExpired == true && status?.hasPremiumAccess != true;

      if (!mounted) return;
      setState(() {
        _shouldShowPaywall = shouldShowPaywall;
        _checkingSubscription = false;
      });

      if (shouldShowPaywall && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => PaywallScreen()),
          );
          if (mounted) {
            _checkSubscription();
          }
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('[SubscriptionGate] Error checking subscription: $e');
      }
      // On error, let user proceed (fail open)
      if (!mounted) return;
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

    return const HomeScreen();
  }
}
