import 'package:flutter/material.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://dfiewtwbxqfrrmyiqhqo.supabase.co',
    anonKey: 'sb_publishable_swGU8s8l_FgSo2GuKbGkfA_00Wd9zIV',
  );

  // Initialize notification service and reschedule any pending notifications
  await NotificationService().initialize();
  await NotificationService().requestPermissions();
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
        print('[OnboardingCheck] Error checking onboarding status: $error');
        // On error, assume onboarding is complete and show home screen
        return const HomeScreen();
      },
    );
  }
}
