import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding/welcome_screen.dart';
import 'services/onboarding_service.dart';
import 'services/notification_service.dart';
import 'services/notification_scheduler.dart';
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

/// OnboardingCheck determines whether to show onboarding or home screen
class OnboardingCheck extends ConsumerWidget {
  const OnboardingCheck({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardingStatus = ref.watch(isOnboardingCompletedProvider);

    return onboardingStatus.when(
      data: (isCompleted) {
        // Reschedule notifications for authenticated users
        NotificationScheduler().rescheduleAll();
        if (isCompleted) {
          return const HomeScreen();
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
