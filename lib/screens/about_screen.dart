import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/colors.dart';
import '../theme/wintermute_styles.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'ABOUT',
          style: WintermmuteStyles.subHeaderStyle.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        centerTitle: true,
      ),
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Logo
            Center(
              child: Column(
                children: [
                  // Vectorized Neon Cyberpunk Brain Logo
                  Image.asset(
                    'assets/logo/biohacker-neon-logo-vectorized.png',
                    width: 300,
                    height: 280,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'BIOHACKER',
                    style: WintermmuteStyles.titleStyle.copyWith(
                      fontSize: 28,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'PEPTIDE TRACKING & HEALTH OPTIMIZATION',
                    style: WintermmuteStyles.smallStyle.copyWith(
                      color: AppColors.amber,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Mission
            _buildSection(
              title: 'MISSION',
              content:
                  'Biohacker is a personal health tracking tool for biohackers, athletes, and health enthusiasts who want to optimize their bodies through peptide protocols, supplementation, and data-driven decision making.\n\nWe believe health optimization should be personalized, transparent, and backed by your own lab data.',
            ),
            const SizedBox(height: 24),

            // Features
            _buildSection(
              title: 'KEY FEATURES',
              content: null,
              items: [
                'Track peptide cycles with precise dosing',
                'Upload and analyze lab results',
                'AI-powered health insights via Claude',
                'Correlate lab results with protocols',
                'Monitor biomarker trends over time',
                'Offline-capable, privacy-first design',
              ],
            ),
            const SizedBox(height: 24),

            // Privacy & Security
            _buildSection(
              title: 'PRIVACY & SECURITY',
              content:
                  'Your health data is sensitive. We handle it that way:\n\n• End-to-end encrypted cloud storage (Supabase)\n• HIPAA-aligned security practices\n• No data selling (ever)\n• Full user control over data deletion\n• Transparent third-party use (Claude API, Firebase)',
            ),
            const SizedBox(height: 24),

            // Medical Disclaimer
            _buildSection(
              title: 'IMPORTANT DISCLAIMER',
              content:
                  'Biohacker is NOT a medical device and does NOT provide medical advice, diagnosis, or treatment.\n\nIt is a personal information tracking tool for educational purposes only.\n\nAlways consult qualified healthcare professionals before starting, stopping, or modifying any health protocol.\n\nYou assume full responsibility for your health decisions.',
            ),
            const SizedBox(height: 24),

            // Version Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: WintermmuteStyles.cardDecoration,
              child: Row(
                children: [
                  Container(
                    width: 3,
                    height: 100,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'APP INFORMATION',
                          style: WintermmuteStyles.smallStyle.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow('Version:', '1.0.0'),
                        const SizedBox(height: 8),
                        _buildInfoRow('Release:', 'March 2026'),
                        const SizedBox(height: 8),
                        _buildInfoRow('Platform:', 'Android & iOS'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Legal Links
            Container(
              padding: const EdgeInsets.all(16),
              decoration: WintermmuteStyles.cardDecoration,
              child: Row(
                children: [
                  Container(
                    width: 3,
                    height: 80,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'LEGAL',
                          style: WintermmuteStyles.smallStyle.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildLegalLink('Privacy Policy', 'View our privacy and data handling practices'),
                        const SizedBox(height: 8),
                        _buildLegalLink('Terms of Service', 'Read our terms and health disclaimers'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Footer
            Center(
              child: Column(
                children: const [
                  Text(
                    '\u00A9 2026 Biohacker',
                    style: WintermmuteStyles.tinyStyle,
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Built for health optimization',
                    style: WintermmuteStyles.tinyStyle,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: WintermmuteStyles.smallStyle.copyWith(
            color: AppColors.textLight,
            fontSize: 11,
          ),
        ),
        Text(
          value,
          style: WintermmuteStyles.smallStyle.copyWith(
            color: AppColors.amber,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    String? content,
    List<String>? items,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: WintermmuteStyles.cardDecoration,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 3,
            constraints: const BoxConstraints(minHeight: 40),
            color: AppColors.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: WintermmuteStyles.smallStyle.copyWith(
                    color: AppColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 12),
                if (content != null)
                  Text(
                    content,
                    style: WintermmuteStyles.smallStyle.copyWith(
                      color: AppColors.textLight,
                      height: 1.6,
                    ),
                  ),
                if (items != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: items
                        .map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '\u25AA ',
                                  style: WintermmuteStyles.smallStyle.copyWith(
                                    color: AppColors.amber,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    item,
                                    style: WintermmuteStyles.smallStyle.copyWith(
                                      color: AppColors.textLight,
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegalLink(String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: const BoxDecoration(
        border: Border(
          left: BorderSide(
            color: AppColors.amber,
            width: 2,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: WintermmuteStyles.smallStyle.copyWith(
              color: AppColors.amber,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: WintermmuteStyles.tinyStyle.copyWith(
              color: AppColors.textMid,
            ),
          ),
        ],
      ),
    );
  }
}
