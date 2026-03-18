import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/colors.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00FFFF)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'ABOUT',
          style: TextStyle(
            color: Color(0xFF00FFFF),
            fontFamily: 'Courier New',
            fontSize: 14,
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
                  // Logo Icon
                  SvgPicture.asset(
                    'assets/logo/biohacker-icon.svg',
                    width: 80,
                    height: 80,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'BIOHACKER',
                    style: const TextStyle(
                      color: Color(0xFF00FFFF),
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Courier New',
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'PEPTIDE TRACKING & HEALTH OPTIMIZATION',
                    style: const TextStyle(
                      color: Color(0xFFFF9800),
                      fontSize: 12,
                      fontFamily: 'Courier New',
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
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF00FFFF).withOpacity(0.3), width: 1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'APP INFORMATION',
                    style: const TextStyle(
                      color: Color(0xFF00FFFF),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Courier New',
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Version:',
                        style: const TextStyle(
                          color: Color(0xFFCCCCCC),
                          fontSize: 11,
                          fontFamily: 'Courier New',
                        ),
                      ),
                      Text(
                        '1.0.0',
                        style: const TextStyle(
                          color: Color(0xFFFF9800),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Courier New',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Release:',
                        style: const TextStyle(
                          color: Color(0xFFCCCCCC),
                          fontSize: 11,
                          fontFamily: 'Courier New',
                        ),
                      ),
                      Text(
                        'March 2026',
                        style: const TextStyle(
                          color: Color(0xFFFF9800),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Courier New',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Platform:',
                        style: const TextStyle(
                          color: Color(0xFFCCCCCC),
                          fontSize: 11,
                          fontFamily: 'Courier New',
                        ),
                      ),
                      Text(
                        'Android & iOS',
                        style: const TextStyle(
                          color: Color(0xFFFF9800),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Courier New',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Legal Links
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF00FFFF).withOpacity(0.3), width: 1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'LEGAL',
                    style: const TextStyle(
                      color: Color(0xFF00FFFF),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Courier New',
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

            const SizedBox(height: 32),

            // Footer
            Center(
              child: Column(
                children: [
                  Text(
                    '© 2026 Biohacker',
                    style: const TextStyle(
                      color: Color(0xFF666666),
                      fontSize: 10,
                      fontFamily: 'Courier New',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Built with ❤️ for health optimization',
                    style: const TextStyle(
                      color: Color(0xFF666666),
                      fontSize: 10,
                      fontFamily: 'Courier New',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    String? content,
    List<String>? items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF00FFFF),
            fontSize: 13,
            fontWeight: FontWeight.bold,
            fontFamily: 'Courier New',
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        if (content != null)
          Text(
            content,
            style: const TextStyle(
              color: Color(0xFFCCCCCC),
              fontSize: 12,
              fontFamily: 'Courier New',
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
                          '▪ ',
                          style: const TextStyle(
                            color: Color(0xFFFF9800),
                            fontSize: 12,
                            fontFamily: 'Courier New',
                          ),
                        ),
                        Expanded(
                          child: Text(
                            item,
                            style: const TextStyle(
                              color: Color(0xFFCCCCCC),
                              fontSize: 12,
                              fontFamily: 'Courier New',
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
    );
  }

  Widget _buildLegalLink(String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: const Color(0xFFFF9800),
            width: 2,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFFF9800),
              fontSize: 11,
              fontWeight: FontWeight.bold,
              fontFamily: 'Courier New',
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFF888888),
              fontSize: 10,
              fontFamily: 'Courier New',
            ),
          ),
        ],
      ),
    );
  }
}
