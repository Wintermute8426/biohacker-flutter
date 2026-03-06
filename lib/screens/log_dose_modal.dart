import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/colors.dart';
import '../theme/wintermute_styles.dart';
import '../services/dose_logs_service.dart';

class LogDoseModal extends StatefulWidget {
  final String cycleId;
  final String? scheduleId;
  final String peptideName;
  final double defaultDoseAmount;
  final String defaultRoute;

  const LogDoseModal({
    Key? key,
    required this.cycleId,
    this.scheduleId,
    required this.peptideName,
    required this.defaultDoseAmount,
    required this.defaultRoute,
  }) : super(key: key);

  @override
  State<LogDoseModal> createState() => _LogDoseModalState();
}

class _LogDoseModalState extends State<LogDoseModal> {
  late TextEditingController _doseController;
  late TextEditingController _notesController;
  String _selectedRoute = '';
  DateTime _selectedDateTime = DateTime.now();
  bool _isLoading = false;

  final _routes = ['IM', 'SC', 'IV', 'PO', 'Intranasal'];

  @override
  void initState() {
    super.initState();
    _doseController = TextEditingController(text: widget.defaultDoseAmount.toString());
    _notesController = TextEditingController();
    _selectedRoute = widget.defaultRoute;
  }

  @override
  void dispose() {
    _doseController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  bool _isValid() {
    return _doseController.text.isNotEmpty &&
        double.tryParse(_doseController.text) != null &&
        _selectedRoute.isNotEmpty;
  }

  Future<void> _submitLog() async {
    if (!_isValid()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Color(0xFFFF0040),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final service = DoseLogsService(Supabase.instance.client);

      print('[DEBUG] Logging dose for cycle: ${widget.cycleId}');
      
      await service.logDose(
        userId: userId,
        cycleId: widget.cycleId,
        scheduleId: widget.scheduleId,
        peptideName: widget.peptideName,
        doseAmount: double.parse(_doseController.text),
        route: _selectedRoute,
        injectionSite: null,
        loggedAt: _selectedDateTime,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      print('[DEBUG] Dose logged successfully');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ ${widget.peptideName} logged'),
            backgroundColor: AppColors.primary,
            duration: const Duration(seconds: 2),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      print('[ERROR] Failed to log dose: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.primary,
              surface: AppColors.surface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
        builder: (context, child) {
          return Theme(
            data: ThemeData.dark().copyWith(
              colorScheme: ColorScheme.dark(
                primary: AppColors.primary,
                surface: AppColors.surface,
              ),
            ),
            child: child!,
          );
        },
      );

      if (time != null) {
        setState(() {
          _selectedDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print('[DEBUG MODAL] Building LogDoseModal for ${widget.peptideName}');
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'LOG ${widget.peptideName.toUpperCase()}',
          style: WintermmuteStyles.headerStyle.copyWith(fontSize: 16),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),

            // Dose Amount
            Text(
              'Dose Amount (mg)',
              style: WintermmuteStyles.headerStyle.copyWith(fontSize: 12),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _doseController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: '${widget.defaultDoseAmount}',
                hintStyle: TextStyle(color: AppColors.textDim),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Route
            Text(
              'Route',
              style: WintermmuteStyles.headerStyle.copyWith(fontSize: 12),
            ),
            const SizedBox(height: 8),
            DropdownButton<String>(
              value: _selectedRoute,
              isExpanded: true,
              dropdownColor: AppColors.surface,
              style: const TextStyle(color: Colors.white),
              items: _routes.map((route) {
                return DropdownMenuItem(
                  value: route,
                  child: Text(route),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedRoute = value);
                }
              },
            ),
            const SizedBox(height: 16),

            // DateTime Picker
            Text(
              'Logged At',
              style: WintermmuteStyles.headerStyle.copyWith(fontSize: 12),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickDateTime,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('MMM dd, yyyy HH:mm').format(_selectedDateTime),
                      style: const TextStyle(color: Colors.white),
                    ),
                    Icon(Icons.calendar_today, color: AppColors.primary, size: 18),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Notes
            Text(
              'Notes (optional)',
              style: WintermmuteStyles.headerStyle.copyWith(fontSize: 12),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'e.g., "Good absorption, no pain"',
                hintStyle: TextStyle(color: AppColors.textDim),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitLog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        'LOG DOSE',
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
