import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/colors.dart';
import '../theme/wintermute_styles.dart';
import '../services/user_profile_service.dart';
import 'onboarding_screen.dart';
import 'dashboard_screen.dart';
import 'cycles_screen.dart';
import 'research_screen.dart';
import 'protocols_screen.dart';
import 'labs_screen.dart';
import 'reports_screen.dart';
import 'calendar_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const CyclesScreen(),
    const LabsScreen(),
    const ReportsScreen(),
    const CalendarScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _showHamburgerMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (context) => _buildHamburgerMenu(context),
    );
  }

  Widget _buildHamburgerMenu(BuildContext context) {
    return Container(
      color: AppColors.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile & Settings'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.book),
            title: const Text('Research'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ResearchScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About'),
            onTap: () {
              Navigator.pop(context);
              // Show about dialog
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Biohacker'),
                  content: const Text('Version 1.0.0\n\nPeptide tracking & optimization'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            textColor: AppColors.error,
            iconColor: AppColors.error,
            onTap: () {
              Navigator.pop(context);
              // Logout logic
              Supabase.instance.client.auth.signOut();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Check if onboarding is completed
    final onboardingCompleted = ref.watch(onboardingCompletedProvider);

    return onboardingCompleted.when(
      data: (completed) {
        if (!completed) {
          // Show onboarding if not completed
          return const OnboardingScreen();
        }
        
        // Show main app
        return Scaffold(
          appBar: AppBar(
            backgroundColor: AppColors.background,
            elevation: 0,
            title: Text(
              'BIOHACKER',
              style: WintermmuteStyles.titleStyle.copyWith(fontSize: 18),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => _showHamburgerMenu(context),
                color: AppColors.primary,
              ),
            ],
          ),
          body: Stack(
            children: [
              _screens[_selectedIndex],
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _ScanlinesPainter(),
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            backgroundColor: AppColors.surface,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: AppColors.textMid,
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Dashboard',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.schedule),
                label: 'Cycles',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.science),
                label: 'Labs',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.analytics),
                label: 'Reports',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.calendar_month),
                label: 'Calendar',
              ),
            ],
          ),
        );
      },
      loading: () => Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (err, stack) => Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Text(
            'Error loading profile',
            style: WintermmuteStyles.bodyStyle,
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
