import 'package:flutter/material.dart';
import '../services/secure_storage_service.dart';
import '../theme/colors.dart';

/// HIPAA notice and acknowledgment screen
/// Shown on first app launch and when privacy policy updates
class HipaaNoticeScreen extends StatefulWidget {
  final VoidCallback onAcknowledged;

  const HipaaNoticeScreen({
    Key? key,
    required this.onAcknowledged,
  }) : super(key: key);

  @override
  State<HipaaNoticeScreen> createState() => _HipaaNoticeScreenState();
}

class _HipaaNoticeScreenState extends State<HipaaNoticeScreen> {
  bool _acknowledged = false;
  final SecureStorageService _secureStorage = SecureStorageService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.security,
                    color: AppColors.primary,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'HIPAA Notice',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Scrollable legal notice
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Privacy & Data Protection'),
                      _buildBodyText(
                        'Biohacker is designed to help you track and optimize your health protocols. '
                        'The app handles Protected Health Information (PHI) in accordance with HIPAA regulations.',
                      ),
                      const SizedBox(height: 16),

                      _buildSectionTitle('What Information We Collect'),
                      _buildBulletPoint('Health metrics and lab results'),
                      _buildBulletPoint('Peptide dosing schedules and logs'),
                      _buildBulletPoint('Profile information (age, weight, health goals)'),
                      _buildBulletPoint('Authentication data (email, session tokens)'),
                      const SizedBox(height: 16),

                      _buildSectionTitle('How We Protect Your Data'),
                      _buildBulletPoint('End-to-end encryption for data in transit'),
                      _buildBulletPoint('Encrypted storage at rest (AES-256)'),
                      _buildBulletPoint('Secure authentication with optional biometric login'),
                      _buildBulletPoint('Automatic session timeout after 30 minutes of inactivity'),
                      _buildBulletPoint('No data sharing with third parties'),
                      const SizedBox(height: 16),

                      _buildSectionTitle('Your Rights'),
                      _buildBulletPoint('Access, modify, or delete your data at any time'),
                      _buildBulletPoint('Export your complete health records'),
                      _buildBulletPoint('Request data breach notifications'),
                      _buildBulletPoint('Opt out of optional features'),
                      const SizedBox(height: 16),

                      _buildSectionTitle('Security Best Practices'),
                      _buildBodyText(
                        'To maintain the security of your health data:\n\n'
                        '• Enable biometric authentication\n'
                        '• Use a strong password\n'
                        '• Keep your device OS updated\n'
                        '• Do not share your account credentials\n'
                        '• Log out when using shared devices',
                      ),
                      const SizedBox(height: 16),

                      _buildSectionTitle('Data Retention'),
                      _buildBodyText(
                        'Your data is stored securely until you delete your account. '
                        'Upon account deletion, all PHI is permanently removed from our systems within 30 days.',
                      ),
                      const SizedBox(height: 16),

                      _buildSectionTitle('Contact & Support'),
                      _buildBodyText(
                        'For privacy questions or to exercise your rights:\n'
                        'Email: privacy@biohacker.app\n\n'
                        'For security incidents:\n'
                        'Email: security@biohacker.app',
                      ),
                      const SizedBox(height: 24),

                      // Version information
                      Text(
                        'Last updated: March 26, 2026\nVersion: 1.0',
                        style: TextStyle(
                          color: AppColors.textMid,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Acknowledgment checkbox
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _acknowledged ? AppColors.primary : const Color(0xFF2A2A3E),
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Checkbox(
                      value: _acknowledged,
                      onChanged: (value) {
                        setState(() {
                          _acknowledged = value ?? false;
                        });
                      },
                      activeColor: AppColors.primary,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'I acknowledge that I have read and understood this HIPAA notice',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Continue button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _acknowledged ? _handleAcknowledge : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: const Color(0xFF2A2A3E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          color: AppColors.primary,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildBodyText(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFFCCCCCC),
        fontSize: 14,
        height: 1.5,
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 14,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFFCCCCCC),
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAcknowledge() async {
    await _secureStorage.setHipaaAcknowledged(true);
    widget.onAcknowledged();
  }
}
