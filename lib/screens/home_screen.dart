import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/colors.dart';
import '../theme/wintermute_styles.dart';
import '../services/user_profile_service.dart';
import '../widgets/city_background.dart';
import '../widgets/cyberpunk_rain.dart';
import '../widgets/subscription_banner.dart';
import '../main.dart';
import 'onboarding_screen.dart';
import 'dashboard_screen.dart';
import 'cycles_screen.dart';
import 'research_screen.dart';
import 'protocols_screen.dart';
import 'labs_screen.dart';
import 'reports_screen.dart';
import 'calendar_screen.dart';
import 'profile_screen.dart';
import 'about_screen.dart';

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

  bool _isLoggingOut = false;
  String _userName = '';
  String? _profilePhotoUrl;

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _loadProfilePhoto();
  }

  /// Record user activity for session timeout tracking
  void _recordActivity() {
    final authProvider = ref.read(authProviderProvider);
    authProvider.recordActivity();
  }

  Future<void> _loadUserName() async {
    try {
      // First try to get from Supabase auth metadata
      final user = Supabase.instance.client.auth.currentUser;
      String? displayName;
      
      if (user != null) {
        // Try first_name from metadata
        displayName = user.userMetadata?['first_name']?.toString();
        
        // Fallback to email prefix
        if (displayName == null || displayName.isEmpty) {
          displayName = user.email?.split('@')[0].toUpperCase();
        }
        
        print('[Drawer] User: ${user.email}, DisplayName: $displayName');
      }
      
      // Fallback to SharedPreferences if Supabase doesn't have it
      if (displayName == null || displayName.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        displayName = prefs.getString('user_name') ?? '';
      }
      
      setState(() {
        _userName = displayName ?? '';
      });
    } catch (e) {
      print('[HomeScreen] Error loading user name: $e');
    }
  }

  Future<void> _loadProfilePhoto() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;
      
      // Load from database (persists across reinstalls)
      final profileService = ref.read(userProfileServiceProvider);
      final profile = await profileService.getUserProfile(userId);
      
      String? photoUrl = profile?.photoUrl;
      
      // Fallback to SharedPreferences for backwards compatibility
      if (photoUrl == null || photoUrl.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        photoUrl = prefs.getString('profile_photo_url');
      }
      
      if (mounted) {
        setState(() {
          _profilePhotoUrl = photoUrl;
        });
      }
    } catch (e) {
      print('[HomeScreen] Error loading profile photo: $e');
    }
  }

  void _showHamburgerMenu(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Menu',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
          )),
          child: Align(
            alignment: Alignment.centerRight,
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.75,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.background,
                ),
                child: _buildHamburgerMenu(context),
              ),
            ),
          ),
        );
      },
    );
  }

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  Widget _buildHamburgerMenu(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final userEmail = user?.email;

    return Stack(
      children: [
        // City background
        Positioned.fill(
          child: CityBackground(enabled: true, opacity: 0.3),
        ),
        // Rain effect
        Positioned.fill(
          child: CyberpunkRain(enabled: true, opacity: 0.2),
        ),
        // Scanlines overlay
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _ScanlinesPainter(),
            ),
          ),
        ),
        // Content
        SafeArea(
          child: Column(
            children: [
              // Header with logo and terminal-style user info
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.background.withOpacity(0.9),
                  border: Border(
                    bottom: BorderSide(
                      color: AppColors.primary.withOpacity(0.6),
                      width: 2,
                    ),
                    left: BorderSide(
                      color: AppColors.primary,
                      width: 4,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.2),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo row
                    Row(
                      children: [
                        Image.asset(
                          'assets/logo/biohacker_logo.png',
                          height: 48,
                          width: 48,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '> BIOHACKER',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                                fontFamily: 'monospace',
                              ),
                            ),
                            Text(
                              'SYSTEM V2.0',
                              style: TextStyle(
                                color: AppColors.primary.withOpacity(0.6),
                                fontSize: 10,
                                letterSpacing: 1.5,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Terminal-style user info
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A0A0A),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Profile picture with initials
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: AppColors.primary.withOpacity(0.15),
                            backgroundImage: _profilePhotoUrl != null && _profilePhotoUrl!.isNotEmpty
                              ? (_profilePhotoUrl!.startsWith('http') 
                                  ? NetworkImage(_profilePhotoUrl!) as ImageProvider
                                  : FileImage(File(_profilePhotoUrl!)) as ImageProvider)
                              : null,
                            child: _profilePhotoUrl == null || _profilePhotoUrl!.isEmpty
                              ? Text(
                                  _getInitials(_userName),
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'monospace',
                                  ),
                                )
                              : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _userName.isNotEmpty ? _userName.toUpperCase() : "USER",
                                  style: TextStyle(
                                    color: AppColors.textLight,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  userEmail ?? 'Loading...',
                                  style: TextStyle(
                                    color: AppColors.textMid,
                                    fontSize: 11,
                                    fontFamily: 'monospace',
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // Menu sections with terminal-style PREFIX
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildMenuItem(
                      context,
                      icon: Icons.biotech,
                      iconColor: WintermmuteStyles.colorGreen,
                      label: 'Protocols',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ProtocolsScreen()),
                        );
                      },
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.article,
                      iconColor: WintermmuteStyles.colorOrange,
                      label: 'Research',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ResearchScreen()),
                        );
                      },
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.person,
                      iconColor: AppColors.primary,
                      label: 'Profile',
                      onTap: () async {
                        Navigator.pop(context);
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ProfileScreen()),
                        );
                        _loadUserName();
                        _loadProfilePhoto();
                      },
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.info,
                      iconColor: WintermmuteStyles.colorMagenta,
                      label: 'About',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AboutScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ),
              
              // Divider before logout
              Container(
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      AppColors.error.withOpacity(0.5),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              
              // Logout button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildMenuItem(
                  context,
                  icon: _isLoggingOut ? null : Icons.logout,
                  iconColor: AppColors.error,
                  label: _isLoggingOut ? 'Logging out...' : 'Logout',
                  isLoading: _isLoggingOut,
                  isDanger: true,
                  enabled: !_isLoggingOut,
                  onTap: () async {
                    if (_isLoggingOut) return;

                    setState(() => _isLoggingOut = true);
                    Navigator.pop(context);

                    try {
                      await Supabase.instance.client.auth.signOut();
                    } catch (e) {
                      if (mounted) {
                        setState(() => _isLoggingOut = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to logout: ${e.toString()}'),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    }
                  },
                ),
              ),
              const SizedBox(height: 16),
              
              // Footer with version info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: AppColors.primary.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      '◆ SOVEREIGN PROTOCOL ◆',
                      style: TextStyle(
                        color: AppColors.primary.withOpacity(0.6),
                        fontSize: 10,
                        fontFamily: 'monospace',
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'BIOHACKER V2.0 • BUILD 2026',
                      style: TextStyle(
                        color: AppColors.textDim,
                        fontSize: 9,
                        fontFamily: 'monospace',
                        letterSpacing: 1,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 12,
            color: AppColors.primary,
          ),
          const SizedBox(width: 8),
          Text(
            '> $title',
            style: TextStyle(
              color: AppColors.primary.withOpacity(0.8),
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    IconData? icon,
    required Color iconColor,
    required String label,
    required VoidCallback onTap,
    bool isLoading = false,
    bool isDanger = false,
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.zero,
          splashColor: (isDanger ? AppColors.error : iconColor).withOpacity(0.1),
          highlightColor: (isDanger ? AppColors.error : iconColor).withOpacity(0.05),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF0A0A0A).withOpacity(0.7),
              border: Border(
                left: BorderSide(
                  color: isDanger ? AppColors.error : iconColor,
                  width: 4,
                ),
                top: BorderSide(
                  color: (isDanger ? AppColors.error : iconColor).withOpacity(0.15),
                  width: 1,
                ),
                bottom: BorderSide(
                  color: (isDanger ? AppColors.error : iconColor).withOpacity(0.15),
                  width: 1,
                ),
                right: BorderSide(
                  color: (isDanger ? AppColors.error : iconColor).withOpacity(0.15),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Text(
                  '>',
                  style: TextStyle(
                    color: (isDanger ? AppColors.error : iconColor).withOpacity(0.8),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(width: 12),
                if (isLoading)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(iconColor),
                    ),
                  )
                else if (icon != null)
                  Icon(icon, color: iconColor.withOpacity(0.9), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label.toUpperCase(),
                    style: TextStyle(
                      color: isDanger ? AppColors.error : AppColors.textLight,
                      fontSize: 13,
                      fontFamily: 'monospace',
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (!isLoading)
                  Text(
                    '→',
                    style: TextStyle(
                      color: (isDanger ? AppColors.error : iconColor).withOpacity(0.5),
                      fontSize: 16,
                      fontFamily: 'monospace',
                    ),
                  ),
              ],
            ),
          ),
        ),
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
        
        // Show main app wrapped in GestureDetector for activity tracking
        return GestureDetector(
          onTap: _recordActivity,
          onPanUpdate: (_) => _recordActivity(),
          behavior: HitTestBehavior.translucent,
          child: Scaffold(
          appBar: AppBar(
            backgroundColor: AppColors.background,
            elevation: 0,
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/logo/biohacker-brain-vectorized.png',
                  height: 28,
                  width: 28,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 8),
                Text(
                  'BIOHACKER',
                  style: WintermmuteStyles.titleStyle.copyWith(fontSize: 18),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => _showHamburgerMenu(context),
                color: AppColors.primary,
              ),
            ],
          ),
          body: Column(
            children: [
              SubscriptionBanner(),
              Expanded(
                child: Stack(
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
            showUnselectedLabels: true,
            iconSize: 22,
            selectedFontSize: 10,
            unselectedFontSize: 10,
            items: [
              BottomNavigationBarItem(
                icon: Icon(
                  Icons.dashboard,
                  color: _selectedIndex == 0
                      ? WintermmuteStyles.colorCyan
                      : WintermmuteStyles.colorCyan.withOpacity(0.4),
                ),
                label: 'Dashboard',
              ),
              BottomNavigationBarItem(
                icon: Icon(
                  Icons.autorenew,
                  color: _selectedIndex == 1
                      ? WintermmuteStyles.colorGreen
                      : WintermmuteStyles.colorGreen.withOpacity(0.4),
                ),
                label: 'Cycles',
              ),
              BottomNavigationBarItem(
                icon: Icon(
                  Icons.science,
                  color: _selectedIndex == 2
                      ? WintermmuteStyles.colorOrange
                      : WintermmuteStyles.colorOrange.withOpacity(0.4),
                ),
                label: 'Labs',
              ),
              BottomNavigationBarItem(
                icon: Icon(
                  Icons.analytics,
                  color: _selectedIndex == 3
                      ? WintermmuteStyles.colorMagenta
                      : WintermmuteStyles.colorMagenta.withOpacity(0.4),
                ),
                label: 'Reports',
              ),
              BottomNavigationBarItem(
                icon: Icon(
                  Icons.calendar_month,
                  color: _selectedIndex == 4
                      ? WintermmuteStyles.colorCyan
                      : WintermmuteStyles.colorCyan.withOpacity(0.4),
                ),
                label: 'Calendar',
              ),
            ],
          ),
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
