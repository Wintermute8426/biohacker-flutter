import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'theme/colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://dfiewtwbxqfrrmyiqhqo.supabase.co',
    anonKey: 'sb_publishable_swGU8s8l_FgSo2GuKbGkfA_00Wd9zIV',
  );

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
              ? const HomeScreen()
              : const LoginScreen(),
    );
  }
}
