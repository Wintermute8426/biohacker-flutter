import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/colors.dart';
import '../../theme/wintermute_styles.dart';
import '../../services/onboarding_service.dart';
import '../../services/user_profile_service.dart';
import '../home_screen.dart';
import 'onboarding_scaffold.dart';

class ProfileDetailsScreen extends ConsumerStatefulWidget {
  final OnboardingData data;

  const ProfileDetailsScreen({Key? key, required this.data}) : super(key: key);

  @override
  ConsumerState<ProfileDetailsScreen> createState() => _ProfileDetailsScreenState();
}

class _ProfileDetailsScreenState extends ConsumerState<ProfileDetailsScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  int _heightFeet = 5;
  int _heightInches = 10;
  String _gender = 'prefer_not_to_say';
  bool _isLoading = false;
  bool _showSuccess = false;

  static const List<Map<String, String>> _genderOptions = [
    {'value': 'male', 'label': 'MALE'},
    {'value': 'female', 'label': 'FEMALE'},
    {'value': 'other', 'label': 'OTHER'},
    {'value': 'prefer_not_to_say', 'label': 'DECLINE'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.data.displayName != null) {
      _nameController.text = widget.data.displayName!;
    }
    if (widget.data.age != null) {
      _ageController.text = widget.data.age.toString();
    }
    if (widget.data.weight != null) {
      _weightController.text = widget.data.weight!.toStringAsFixed(0);
    }
    if (widget.data.heightFeet != null) _heightFeet = widget.data.heightFeet!;
    if (widget.data.heightInches != null) _heightInches = widget.data.heightInches!;
    if (widget.data.gender != null) _gender = widget.data.gender!;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _complete() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      _showError('User session not found. Please log in again.');
      return;
    }

    // Populate data
    final name = _nameController.text.trim();
    widget.data.displayName = name.isNotEmpty ? name : null;

    final ageText = _ageController.text.trim();
    if (ageText.isNotEmpty) {
      final age = int.tryParse(ageText);
      if (age == null || age < 13 || age > 120) {
        _showError('Age must be between 13 and 120');
        return;
      }
      widget.data.age = age;
    }

    final weightText = _weightController.text.trim();
    if (weightText.isNotEmpty) {
      final weight = double.tryParse(weightText);
      if (weight == null || weight < 50 || weight > 500) {
        _showError('Weight must be between 50 and 500 lbs');
        return;
      }
      widget.data.weight = weight;
    }

    widget.data.heightFeet = _heightFeet;
    widget.data.heightInches = _heightInches;
    widget.data.gender = _gender;

    setState(() => _isLoading = true);

    try {
      final service = ref.read(onboardingServiceProvider);
      final success = await service.completeOnboarding(userId, widget.data);

      if (!success) throw Exception('Failed to save onboarding data');

      ref.invalidate(userProfileProvider);
      ref.invalidate(isOnboardingCompletedProvider);

      if (mounted) {
        setState(() {
          _isLoading = false;
          _showSuccess = true;
        });

        // Brief success flash then navigate
        await Future.delayed(const Duration(milliseconds: 1500));

        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError('Error saving profile: $e');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: WintermmuteStyles.smallStyle),
        backgroundColor: AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_showSuccess) {
      return _buildSuccessScreen();
    }

    return OnboardingScaffold(
      currentStep: 6,
      stepLabel: 'OPERATOR_PROFILE',
      onNext: _complete,
      onBack: () => Navigator.pop(context),
      nextLabel: 'INITIALIZE PROTOCOL',
      isLoading: _isLoading,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            GlitchText(
              text: 'OPERATOR PROFILE',
              style: WintermmuteStyles.headerStyle.copyWith(
                fontSize: 18,
                letterSpacing: 2,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              'Biometric registration // all fields optional',
              style: WintermmuteStyles.tinyStyle.copyWith(
                color: AppColors.textDim,
              ),
            ),

            const SizedBox(height: 24),

            // Name
            _buildLabel('CALLSIGN', AppColors.primary),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _nameController,
              hint: 'Sovereign User',
              keyboardType: TextInputType.text,
            ),

            const SizedBox(height: 20),

            // Age
            _buildLabel('AGE', AppColors.primary),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _ageController,
              hint: '30',
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 20),

            // Weight
            _buildLabel('WEIGHT (LBS)', AppColors.primary),
            const SizedBox(height: 4),
            Text(
              'Used for dosing calculations',
              style: WintermmuteStyles.tinyStyle.copyWith(color: AppColors.textDim),
            ),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _weightController,
              hint: '185',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),

            const SizedBox(height: 20),

            // Height
            _buildLabel('HEIGHT', AppColors.primary),
            const SizedBox(height: 10),
            Row(
              children: [
                // Feet
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.25),
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _heightFeet,
                        dropdownColor: AppColors.surface,
                        style: WintermmuteStyles.bodyStyle,
                        items: List.generate(5, (i) => i + 4).map((ft) {
                          return DropdownMenuItem(
                            value: ft,
                            child: Text('$ft ft'),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _heightFeet = val);
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Inches
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.25),
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _heightInches,
                        dropdownColor: AppColors.surface,
                        style: WintermmuteStyles.bodyStyle,
                        items: List.generate(12, (i) => i).map((inch) {
                          return DropdownMenuItem(
                            value: inch,
                            child: Text('$inch in'),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _heightInches = val);
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Gender / Sex
            _buildLabel('SEX / GENDER', AppColors.primary),
            const SizedBox(height: 4),
            Text(
              'For lab reference ranges',
              style: WintermmuteStyles.tinyStyle.copyWith(color: AppColors.textDim),
            ),
            const SizedBox(height: 10),
            Row(
              children: _genderOptions.map((opt) {
                final isSelected = _gender == opt['value'];
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _gender = opt['value']!),
                    child: Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withOpacity(0.12)
                            : AppColors.surface,
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.primary.withOpacity(0.2),
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Center(
                        child: Text(
                          opt['label']!,
                          style: WintermmuteStyles.tinyStyle.copyWith(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textMid,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 32),

            // Summary box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(
                  color: AppColors.accent.withOpacity(0.2),
                ),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '// PROTOCOL SUMMARY',
                    style: WintermmuteStyles.tinyStyle.copyWith(
                      color: AppColors.accent,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildSummaryLine('CLEARANCE', widget.data.experienceLevel.toUpperCase()),
                  _buildSummaryLine('VECTORS', '${widget.data.healthGoals.length} selected'),
                  _buildSummaryLine('CYCLE', widget.data.cycleStatus == 'active_cycle' ? 'ACTIVE' : 'OFFLINE'),
                  _buildSummaryLine('BLOODWORK', widget.data.bloodworkFrequency.replaceAll('_', ' ').toUpperCase()),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text, Color color) {
    return Text(
      text,
      style: WintermmuteStyles.smallStyle.copyWith(
        color: color,
        letterSpacing: 1.5,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: WintermmuteStyles.bodyStyle,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: WintermmuteStyles.bodyStyle.copyWith(
          color: AppColors.textDim,
        ),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(2),
          borderSide: BorderSide(color: AppColors.primary.withOpacity(0.25)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(2),
          borderSide: BorderSide(color: AppColors.primary.withOpacity(0.25)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(2),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildSummaryLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: WintermmuteStyles.tinyStyle.copyWith(
              color: AppColors.textDim,
              letterSpacing: 1,
            ),
          ),
          Text(
            value,
            style: WintermmuteStyles.tinyStyle.copyWith(
              color: AppColors.accent,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessScreen() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Scanlines
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: ScanlinesPainter(opacity: 0.05),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Success icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppColors.accent,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: const Icon(
                    Icons.check,
                    color: AppColors.accent,
                    size: 48,
                  ),
                ),

                const SizedBox(height: 24),

                GlitchText(
                  text: 'PROTOCOL INITIALIZED',
                  style: WintermmuteStyles.titleStyle.copyWith(
                    fontSize: 20,
                    letterSpacing: 3,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                Text(
                  'SYSTEM ONLINE // ALL MODULES ACTIVE',
                  style: WintermmuteStyles.tinyStyle.copyWith(
                    color: AppColors.accent,
                    letterSpacing: 2,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  'Redirecting to command center...',
                  style: WintermmuteStyles.tinyStyle.copyWith(
                    color: AppColors.textDim,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
