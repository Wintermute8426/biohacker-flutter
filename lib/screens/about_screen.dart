import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/colors.dart';
import '../widgets/cyberpunk_background.dart';
import 'legal_screen.dart';
import '../assets/legal_documents.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({Key? key}) : super(key: key);

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color cyan = AppColors.primary;
    const Color magenta = AppColors.secondary;

    return CyberpunkBackground(
      cityOpacity: 0.25,
      rainOpacity: 0.2,
      rainParticleCount: 50,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Stack(
            children: [
              // Content
              ListView(
                padding: const EdgeInsets.fromLTRB(16, 80, 16, 40),
                children: [
                  // Logo
                  Center(
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: cyan.withOpacity(0.3),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/images/biohacker_logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Title
                  Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: cyan.withOpacity(0.6), width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: cyan.withOpacity(0.2),
                                blurRadius: 20,
                              ),
                            ],
                          ),
                          child: Text(
                            'BIOHACKER SYSTEMS',
                            style: TextStyle(
                              color: cyan,
                              fontSize: 22,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                              letterSpacing: 3,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '> PEPTIDE PROTOCOL TRACKING',
                          style: TextStyle(
                            color: AppColors.amber,
                            fontSize: 11,
                            fontFamily: 'monospace',
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '> HEALTH OPTIMIZATION PLATFORM',
                          style: TextStyle(
                            color: AppColors.accent,
                            fontSize: 11,
                            fontFamily: 'monospace',
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Mission Statement
                  _buildTerminalSection(
                    title: 'MISSION DIRECTIVE',
                    icon: Icons.flag,
                    color: cyan,
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Biohacker is a personal health tracking tool for biohackers, athletes, and health enthusiasts who want to optimize their bodies through peptide protocols, supplementation, and data-driven decision making.',
                          style: TextStyle(
                            color: AppColors.textLight,
                            fontSize: 13,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            border: Border(left: BorderSide(color: AppColors.accent, width: 4)),
                          ),
                          child: Text(
                            'We believe health optimization should be personalized, transparent, and backed by your own lab data.',
                            style: TextStyle(
                              color: AppColors.accent,
                              fontSize: 12,
                              fontFamily: 'monospace',
                              fontStyle: FontStyle.italic,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Version Info
                  _buildTerminalSection(
                    title: 'SYSTEM INFO',
                    icon: Icons.info,
                    color: AppColors.amber,
                    content: Column(
                      children: [
                        _buildInfoRow('VERSION', '2.0.0'),
                        const SizedBox(height: 8),
                        _buildInfoRow('RELEASE', 'March 2026'),
                        const SizedBox(height: 8),
                        _buildInfoRow('PLATFORM', 'Android & iOS'),
                        const SizedBox(height: 8),
                        _buildInfoRow('BACKEND', 'Supabase + Claude'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Links
                  _buildTerminalSection(
                    title: 'EXTERNAL LINKS',
                    icon: Icons.link,
                    color: magenta,
                    content: Column(
                      children: [
                        _buildLinkButton(
                          'WEBSITE',
                          'https://biohacker.systems',
                          Icons.language,
                          magenta,
                          () => _launchUrl('https://biohacker.systems'),
                        ),
                        const SizedBox(height: 8),
                        _buildLinkButton(
                          'GITHUB',
                          'Source code & contributions',
                          Icons.code,
                          cyan,
                          () => _launchUrl('https://github.com'),
                        ),
                        const SizedBox(height: 8),
                        _buildLinkButton(
                          'CONTACT',
                          'hello@biohacker.systems',
                          Icons.email,
                          AppColors.accent,
                          () => _launchUrl('mailto:hello@biohacker.systems'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Legal
                  _buildTerminalSection(
                    title: 'LEGAL',
                    icon: Icons.gavel,
                    color: AppColors.error,
                    content: Column(
                      children: [
                        _buildLegalLink(
                          context,
                          'PRIVACY POLICY',
                          'Data handling practices & HIPAA compliance',
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => LegalScreen(
                                title: 'PRIVACY POLICY',
                                content: LegalDocuments.privacyPolicy,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildLegalLink(
                          context,
                          'TERMS OF SERVICE',
                          'Usage terms & health disclaimers',
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => LegalScreen(
                                title: 'TERMS OF SERVICE',
                                content: LegalDocuments.termsOfService,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Footer
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 100,
                          height: 1,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                cyan.withOpacity(0.6),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '© 2026 BIOHACKER SYSTEMS',
                          style: TextStyle(
                            color: AppColors.textDim,
                            fontFamily: 'monospace',
                            fontSize: 9,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'BUILT FOR HEALTH OPTIMIZATION',
                          style: TextStyle(
                            color: AppColors.textDim,
                            fontFamily: 'monospace',
                            fontSize: 8,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Header with back button
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(8, 12, 16, 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.9),
                    border: Border(
                      bottom: BorderSide(color: cyan.withOpacity(0.3), width: 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back, color: cyan, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Container(width: 3, height: 16, color: cyan),
                      const SizedBox(width: 10),
                      Icon(Icons.info_outline, color: cyan, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'ABOUT',
                        style: TextStyle(
                          color: cyan,
                          fontSize: 13,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Scanlines overlay
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
      ),
    );
  }

  Widget _buildTerminalSection({
    required String title,
    required IconData icon,
    required Color color,
    required Widget content,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A).withOpacity(0.9),
        border: Border.all(color: color.withOpacity(0.15), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: color, width: 4),
                bottom: BorderSide(color: color.withOpacity(0.2), width: 1),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 14),
                const SizedBox(width: 8),
                Text(
                  '> $title',
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: content,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.textDim,
            fontFamily: 'monospace',
            fontSize: 10,
            letterSpacing: 1,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: AppColors.textLight,
            fontFamily: 'monospace',
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildLinkButton(
    String label,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black,
          border: Border(left: BorderSide(color: color, width: 3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontFamily: 'monospace',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppColors.textMid,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.textDim, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildLegalLink(
    BuildContext context,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black,
          border: Border(left: BorderSide(color: AppColors.error, width: 3)),
        ),
        child: Row(
          children: [
            Icon(Icons.description, color: AppColors.error, size: 16),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppColors.error,
                      fontFamily: 'monospace',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppColors.textMid,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.textDim, size: 16),
          ],
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
