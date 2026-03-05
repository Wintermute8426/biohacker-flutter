import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/colors.dart';
import '../theme/wintermute_styles.dart';
import '../services/dose_schedule_service.dart';

class DoseScheduleForm extends ConsumerStatefulWidget {
  final String cycleId;
  final String peptideName;
  final double defaultDoseAmount;

  const DoseScheduleForm({
    Key? key,
    required this.cycleId,
    required this.peptideName,
    required this.defaultDoseAmount,
  }) : super(key: key);

  @override
  ConsumerState<DoseScheduleForm> createState() => _DoseScheduleFormState();
}

class _DoseScheduleFormState extends ConsumerState<DoseScheduleForm> {
  late TextEditingController _doseController;
  late TextEditingController _timeController;
  String _route = 'IM';
  final List<int> _selectedDays = [];
  DateTime? _startDate;
  DateTime? _endDate;
  String? _notes;

  final List<String> _routes = ['IM', 'SC', 'IV', 'PO'];
  final List<String> _dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  @override
  void initState() {
    super.initState();
    _doseController = TextEditingController(text: widget.defaultDoseAmount.toString());
    _timeController = TextEditingController(text: '08:00');
    _startDate = DateTime.now();
  }

  @override
  void dispose() {
    _doseController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: 8, minute: 0),
      builder: (context, child) => Theme(
        data: ThemeData.dark(),
        child: child!,
      ),
    );

    if (time != null) {
      setState(() {
        _timeController.text = time.format(context);
      });
    }
  }

  Future<void> _selectDate(bool isStart) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate ?? DateTime.now() : _endDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: ThemeData.dark(),
        child: child!,
      ),
    );

    if (date != null) {
      setState(() {
        if (isStart) {
          _startDate = date;
        } else {
          _endDate = date;
        }
      });
    }
  }

  void _toggleDay(int day) {
    setState(() {
      if (_selectedDays.contains(day)) {
        _selectedDays.remove(day);
      } else {
        _selectedDays.add(day);
      }
    });
  }

  bool _isValid() {
    return _doseController.text.isNotEmpty &&
        double.tryParse(_doseController.text) != null &&
        _selectedDays.isNotEmpty &&
        _startDate != null;
  }

  void _save() {
    if (!_isValid()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    Navigator.pop(context, {
      'peptideName': widget.peptideName,
      'doseAmount': double.parse(_doseController.text),
      'route': _route,
      'scheduledTime': _timeController.text,
      'daysOfWeek': _selectedDays,
      'startDate': _startDate,
      'endDate': _endDate,
      'notes': _notes,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'SCHEDULE: ${widget.peptideName.toUpperCase()}',
          style: WintermmuteStyles.titleStyle.copyWith(fontSize: 16),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dose Amount
            Text(
              'Dose Amount (mg)',
              style: WintermmuteStyles.headerStyle.copyWith(fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _doseController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: '5.0',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(color: AppColors.primary.withOpacity(0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(color: AppColors.primary.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
                filled: true,
                fillColor: AppColors.surface,
              ),
              style: const TextStyle(color: AppColors.textLight),
            ),
            const SizedBox(height: 24),

            // Route
            Text(
              'Injection Route',
              style: WintermmuteStyles.headerStyle.copyWith(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _routes.map((route) {
                final isSelected = _route == route;
                return GestureDetector(
                  onTap: () => setState(() => _route = route),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withOpacity(0.2)
                          : AppColors.surface,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.primary.withOpacity(0.2),
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      route,
                      style: WintermmuteStyles.bodyStyle.copyWith(
                        color: isSelected ? AppColors.primary : AppColors.textLight,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Time
            Text(
              'Injection Time',
              style: WintermmuteStyles.headerStyle.copyWith(fontSize: 14),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _selectTime,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _timeController.text,
                      style: WintermmuteStyles.bodyStyle.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    Icon(Icons.access_time, color: AppColors.primary, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Days of Week
            Text(
              'Days of Week *',
              style: WintermmuteStyles.headerStyle.copyWith(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(7, (i) {
                final isSelected = _selectedDays.contains(i);
                return GestureDetector(
                  onTap: () => _toggleDay(i),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withOpacity(0.2)
                          : AppColors.surface,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.primary.withOpacity(0.2),
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Center(
                      child: Text(
                        _dayNames[i],
                        style: WintermmuteStyles.bodyStyle.copyWith(
                          color: isSelected ? AppColors.primary : AppColors.textLight,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),

            // Start Date
            Text(
              'Start Date *',
              style: WintermmuteStyles.headerStyle.copyWith(fontSize: 14),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _selectDate(true),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _startDate?.toString().split(' ')[0] ?? 'Select date',
                      style: WintermmuteStyles.bodyStyle.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    Icon(Icons.calendar_today, color: AppColors.primary, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // End Date (optional)
            Text(
              'End Date (optional)',
              style: WintermmuteStyles.headerStyle.copyWith(fontSize: 14),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _selectDate(false),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _endDate?.toString().split(' ')[0] ?? 'No end date',
                      style: WintermmuteStyles.bodyStyle.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _endDate == null ? AppColors.textMid : AppColors.primary,
                      ),
                    ),
                    Icon(Icons.calendar_today, color: AppColors.primary, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Notes
            Text(
              'Notes (optional)',
              style: WintermmuteStyles.headerStyle.copyWith(fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextField(
              onChanged: (val) => _notes = val,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'e.g., "Rotate injection sites"',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(color: AppColors.primary.withOpacity(0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(color: AppColors.primary.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
                filled: true,
                fillColor: AppColors.surface,
              ),
              style: const TextStyle(color: AppColors.textLight),
            ),
            const SizedBox(height: 32),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isValid() ? _save : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  'SAVE SCHEDULE',
                  style: WintermmuteStyles.bodyStyle.copyWith(
                    color: AppColors.background,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
