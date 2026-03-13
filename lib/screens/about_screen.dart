import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:io' show Platform;
import '../theme/colors.dart';
import '../theme/wintermute_styles.dart';
import '../widgets/city_background.dart';
import '../widgets/cyberpunk_rain.dart';
import '../widgets/cyberpunk_animations.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({Key? key}) : super(key: key);

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _appVersion = 'Loading...';
  String _buildNumber = '';

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = packageInfo.version;
        _buildNumber = packageInfo.buildNumber;
      });
    } catch (e) {
      setState(() {
        _appVersion = 'Unknown';
        _buildNumber = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('ABOUT'),
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // City background layer
          const Positioned.fill(
            child: CityBackground(
              enabled: true,
              animateLights: true,
              opacity: 0.3,
            ),
          ),
          // Rain effect layer
          const Positioned.fill(
            child: CyberpunkRain(
              enabled: true,
              particleCount: 40,
              opacity: 0.25,
            ),
          ),
          // Data stream overlay
          const Positioned.fill(
            child: DataStreamOverlay(
              enabled: true,
              streamCount: 3,
              opacity: 0.2,
            ),
          ),
          // Scanning line
          const Positioned.fill(
            child: ScanningLine(
              enabled: true,
              opacity: 0.15,
            ),
          ),
          // Main content
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // App Logo/Title Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: WintermmuteStyles.cardDecoration,
                  child: Column(
                    children: [
                      // Cyberpunk logo effect
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primary.withOpacity(0.3),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.1),
                              blurRadius: 8,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            Icons.biotech,
                            size: 40,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      GlitchText(
                        text: 'BIOHACKER',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                          letterSpacing: 3,
                        ),
                        enabled: true,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Peptide Cycle Management System',
                        style: TextStyle(
                          color: AppColors.textMid,
                          fontSize: 12,
                          fontFamily: 'monospace',
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 16),
                      StatusIndicators(
                        colors: const [
                          AppColors.accent,
                          AppColors.primary,
                          AppColors.secondary,
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Version Info
                _buildInfoCard(
                  'SYSTEM INFO',
                  [
                    _buildInfoRow('VERSION', 'v$_appVersion'),
                    if (_buildNumber.isNotEmpty)
                      _buildInfoRow('BUILD', _buildNumber),
                    _buildInfoRow('PLATFORM', Platform.operatingSystem.toUpperCase()),
                    _buildInfoRow('STATUS', 'OPERATIONAL'),
                  ],
                ),
                const SizedBox(height: 16),

                // Features
                _buildInfoCard(
                  'FEATURES',
                  [
                    _buildFeatureItem('Cycle Management', Icons.calendar_today),
                    _buildFeatureItem('Dose Tracking', Icons.medication),
                    _buildFeatureItem('Side Effect Logging', Icons.warning_amber),
                    _buildFeatureItem('Lab Results Integration', Icons.science),
                    _buildFeatureItem('Weight Tracking', Icons.monitor_weight),
                    _buildFeatureItem('Insights & Analytics', Icons.analytics),
                  ],
                ),
                const SizedBox(height: 16),

                // Credits
                _buildInfoCard(
                  'CREDITS',
                  [
                    _buildTextRow('DEVELOPED BY', 'Wintermute'),
                    _buildTextRow('DESIGN SYSTEM', 'Cyberpunk Terminal'),
                    _buildTextRow('DATABASE', 'Supabase'),
                    _buildTextRow('FRAMEWORK', 'Flutter'),
                  ],
                ),
                const SizedBox(height: 16),

                // Disclaimer
                _buildInfoCard(
                  'DISCLAIMER',
                  [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'This application is for educational and tracking purposes only. '
                        'Always consult with healthcare professionals before starting any peptide protocol. '
                        'The developers are not responsible for any health outcomes.',
                        style: TextStyle(
                          color: AppColors.textMid,
                          fontSize: 11,
                          fontFamily: 'monospace',
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Terminal-style footer
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: WintermmuteStyles.cardDecoration,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '>> ',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'SYSTEM STATUS: ALL SYSTEMS NOMINAL',
                            style: TextStyle(
                              color: AppColors.accent,
                              fontFamily: 'monospace',
                              fontSize: 10,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '© 2024 BIOHACKER v2 • WINTERMUTE TERMINAL',
                        style: TextStyle(
                          color: AppColors.textDim,
                          fontFamily: 'monospace',
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: WintermmuteStyles.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.textMid,
              fontSize: 11,
              fontFamily: 'monospace',
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: AppColors.textLight,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.textDim,
              fontSize: 9,
              fontFamily: 'monospace',
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: AppColors.textLight,
              fontSize: 12,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: AppColors.accent,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: AppColors.textLight,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          ),
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: AppColors.accent,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withOpacity(0.1),
                  blurRadius: 3,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
