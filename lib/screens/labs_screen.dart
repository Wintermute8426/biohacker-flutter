import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../theme/colors.dart';
import '../theme/wintermute_styles.dart';
import '../models/lab_result.dart';
import '../services/labs_database.dart';
import '../services/bloodwork_service.dart';
import '../services/android_file_picker.dart';
import '../widgets/city_background.dart';
import '../widgets/cyberpunk_rain.dart';
import '../widgets/app_header.dart';
import '../widgets/common/empty_state.dart';
import '../widgets/full_screen_modal.dart';
import '../widgets/common/matte_card.dart';
import '../widgets/common/scanlines_painter.dart' as common;

class LabsScreen extends StatefulWidget {
  const LabsScreen({Key? key}) : super(key: key);

  @override
  State<LabsScreen> createState() => _LabsScreenState();
}

class _LabsScreenState extends State<LabsScreen> {
  final LabsDatabase _labsDb = LabsDatabase();
  late String _userId;
  List<LabResult> _labResults = [];
  bool _isUploading = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    _loadLabResultsBackground();
  }

  Future<void> _loadLabResultsBackground() async {
    try {
      final results = await _labsDb.getUserLabResults(_userId);
      if (mounted) {
        setState(() {
          _labResults = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading labs: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadLabResults() async {
    try {
      final results = await _labsDb.getUserLabResults(_userId);
      if (mounted) {
        setState(() => _labResults = results);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _handleUpload() async {
    try {
      final picker = ImagePicker();
      showModalBottomSheet(
        context: context,
        backgroundColor: AppColors.surface,
        builder: (context) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'UPLOAD LAB REPORT',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                subtitle: const Text('Photograph your lab report'),
                onTap: () async {
                  Navigator.pop(context);
                  final image = await picker.pickImage(source: ImageSource.camera);
                  if (image != null) {
                    await _uploadImage(image);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                subtitle: const Text('Upload image from your device'),
                onTap: () async {
                  Navigator.pop(context);
                  final image = await picker.pickImage(source: ImageSource.gallery);
                  if (image != null) {
                    await _uploadImage(image);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf),
                title: const Text('PDF Lab Report'),
                subtitle: const Text('Upload blood test PDF'),
                onTap: () async {
                  Navigator.pop(context);
                  final filePath = await AndroidFilePicker.pickPdfFile();
                  if (filePath != null) {
                    await _uploadPDF(File(filePath));
                  }
                },
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _uploadImage(XFile image) async {
    setState(() => _isUploading = true);
    try {
      final bytes = await image.readAsBytes();
      print('Image upload started: ${image.name}');

      final mockResult = LabResult(
        id: 'lab-${DateTime.now().millisecondsSinceEpoch}',
        userId: _userId,
        pdfPath: image.name,
        uploadDate: DateTime.now(),
        notes: 'Image Upload',
        extractedData: {
          'testosterone': 680,
          'igf1': 210,
          'cortisol': 9,
        },
      );

      if (mounted) {
        setState(() {
          _labResults.insert(0, mockResult);
          _isUploading = false;
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Lab result added successfully'),
            backgroundColor: AppColors.accent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _uploadPDF(File pdfFile) async {
    setState(() => _isUploading = true);
    try {
      print('PDF upload started: ${pdfFile.path}');

      // Read PDF file
      final bytes = await pdfFile.readAsBytes();
      final fileName = pdfFile.path.split('/').last;

      // Send to backend for extraction
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('http://100.71.64.116:9000/api/extract-lab-pdf'),
      );

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: fileName,
        ),
      );

      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final result = jsonDecode(responseData);
        final extractedBiomarkers = Map<String, dynamic>.from(result['biomarkers'] ?? {});

        print('Extracted ${extractedBiomarkers.length} biomarkers from PDF');

        // Save to database
        final labResult = LabResult(
          id: 'lab-${DateTime.now().millisecondsSinceEpoch}',
          userId: _userId,
          pdfPath: pdfFile.path,
          uploadDate: DateTime.now(),
          notes: 'PDF Upload ($fileName)',
          extractedData: extractedBiomarkers,
        );

        // Save to database
        print('[Labs] Saving lab result to database...');
        await _labsDb.saveLabResult(labResult);
        print('[Labs] Lab result saved successfully');

        if (mounted) {
          setState(() {
            _labResults.insert(0, labResult);
            _isUploading = false;
          });
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Extracted ${extractedBiomarkers.length} biomarkers'),
              backgroundColor: AppColors.accent,
            ),
          );
        }
      } else {
        throw Exception('Backend error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error uploading PDF: $e');
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _deleteLabResult(LabResult lab) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Delete Lab Report?', style: TextStyle(color: Colors.white)),
        content: Text(
          'This will permanently delete this lab report and all its biomarkers.',
          style: TextStyle(color: AppColors.textMid),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('CANCEL', style: TextStyle(color: AppColors.textMid)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('DELETE', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Delete from database
      await _labsDb.deleteLabResult(lab.id);

      // Remove from local state
      if (mounted) {
        setState(() {
          _labResults.removeWhere((l) => l.id == lab.id);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lab report deleted'),
            backgroundColor: AppColors.accent,
          ),
        );
      }
    } catch (e) {
      print('Error deleting lab result: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting report: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
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
          Scaffold(
            backgroundColor: Colors.transparent,
            body: Column(
              children: [
                // Header using reusable widget
                AppHeader(
                  icon: Icons.science,
                  iconColor: WintermmuteStyles.colorOrange,
                  title: 'LABS',
                ),
                Expanded(
                  child: Stack(
                    children: [
                      _buildAllResultsView(),
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllResultsView() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Upload section at top
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            borderRadius: BorderRadius.circular(8),
            color: AppColors.surface.withOpacity(0.15),
          ),
          child: Column(
            children: [
              Icon(Icons.upload_file, size: 40, color: AppColors.primary),
              const SizedBox(height: 12),
              Text(
                'UPLOAD LAB REPORT',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Take a photo or upload an image of your lab report',
                style: TextStyle(
                  color: AppColors.textMid,
                  fontSize: 11,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _isUploading ? null : _handleUpload,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _isUploading ? AppColors.textMid : AppColors.primary.withOpacity(0.2),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isUploading) ...[
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(AppColors.primary),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        _isUploading ? 'UPLOADING...' : '📤 UPLOAD NOW',
                        style: TextStyle(
                          color: _isUploading ? AppColors.textMid : AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        if (_labResults.isEmpty) ...[
          const SizedBox(height: 40),
          const EmptyState(
            icon: Icons.science,
            title: 'No lab results yet',
            message: 'Upload your first lab report to start tracking biomarkers',
          ),
        ] else ...[
          const SizedBox(height: 24),
          Text(
            '${_labResults.length} test dates • ${_getTotalMarkerCount()} total markers',
            style: TextStyle(
              color: AppColors.textMid,
              fontSize: 11,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          ..._labResults.map((lab) => _buildLabResultCard(lab)).toList(),
        ],
      ],
    );
  }


  Widget _buildLabResultCard(LabResult lab) {
    return GestureDetector(
      onTap: () => _showLabDetail(lab),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFF00FFFF).withOpacity(0.7),  // Cyan for labs
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00FFFF).withOpacity(0.3),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('M/d/yyyy').format(lab.uploadDate),
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      '${lab.extractedData.length} markers',
                      style: TextStyle(
                        color: AppColors.textMid,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // DELETE BUTTON
                    IconButton(
                      icon: Icon(Icons.delete_outline, size: 18),
                      color: AppColors.error.withOpacity(0.7),
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                      onPressed: () => _deleteLabResult(lab),
                      tooltip: 'Delete report',
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right, color: AppColors.primary, size: 18),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (lab.extractedData.entries.toList()
                ..sort((a, b) => _getBiomarkerPriority(a.key).compareTo(_getBiomarkerPriority(b.key)))
              ).take(6).map((entry) {
                final isOut = _isOutOfRange(entry.key, entry.value);
                final displayValue = entry.value is Map
                  ? (entry.value['value']?.toString() ?? 'N/A')
                  : entry.value.toString();
                final categoryColor = _getCategoryColor(entry.key);

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    border: Border.all(
                      color: isOut ? AppColors.error.withOpacity(0.7) : categoryColor.withOpacity(0.7),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [
                      BoxShadow(
                        color: categoryColor.withOpacity(0.2),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Text(
                    '${_beautifyBiomarkerName(entry.key)}: $displayValue${isOut ? ' [HIGH]' : ''}',
                    style: TextStyle(
                      color: isOut ? AppColors.error : categoryColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }).toList(),
            ),
            if (lab.extractedData.length > 6) ...[
              const SizedBox(height: 8),
              Text(
                '+ ${lab.extractedData.length - 6} more biomarkers',
                style: TextStyle(
                  color: AppColors.textMid,
                  fontSize: 10,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showLabDetail(LabResult lab) {
    FullScreenModal.show(
      context: context,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
        children: [
          // Header section with CRT styling
          Container(
            // Extended padding at bottom to cover the gap and prevent underline
            padding: const EdgeInsets.fromLTRB(20, 40, 20, 44),  // 20 + 24 extra = 44
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.5),
                  const Color(0xFF001a1a),
                  const Color(0xFF001a1a).withOpacity(0.5),  // Fade to semi-transparent
                  Colors.transparent,  // Fully transparent at bottom - no hard edge!
                ],
                stops: [0.0, 0.3, 0.7, 1.0],  // Control where each color appears
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.flash_on, color: const Color(0xFF00FFFF).withOpacity(0.7), size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'BIOMETRIC ANALYSIS',
                      style: TextStyle(
                        color: const Color(0xFF00FFFF).withOpacity(0.7),
                        fontSize: 9,
                        fontFamily: 'monospace',
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  DateFormat('MMM d, yyyy').format(lab.uploadDate).toUpperCase(),
                  style: TextStyle(
                    color: const Color(0xFF00FFFF),
                    fontSize: 18,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),

          // Remove the gap - the header container now has extended padding to cover this space
          // const SizedBox(height: 24),

          // Lab metadata - SOURCE section with icon
          if (lab.notes != null && lab.notes!.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF00FFFF).withOpacity(0.6),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00FFFF).withOpacity(0.3),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Scanlines
                    Positioned.fill(
                      child: CustomPaint(
                        painter: common.ScanlinesPainter(
                          opacity: 0.05,
                          spacing: 3.0,
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.source,
                              color: const Color(0xFF00FFFF),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'SOURCE',
                              style: TextStyle(
                                color: const Color(0xFF00FFFF).withOpacity(0.7),
                                fontSize: 11,
                                fontFamily: 'monospace',
                                letterSpacing: 1,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          lab.notes!,
                          style: TextStyle(
                            color: AppColors.textMid,
                            fontSize: 12,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],

          // All biomarkers header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF00FFFF).withOpacity(0.6),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00FFFF).withOpacity(0.3),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Scanlines
                  Positioned.fill(
                    child: CustomPaint(
                      painter: common.ScanlinesPainter(
                        opacity: 0.05,
                        spacing: 3.0,
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.biotech,
                            color: const Color(0xFF00FFFF),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'ALL BIOMARKERS',
                            style: TextStyle(
                              color: const Color(0xFF00FFFF).withOpacity(0.7),
                              fontSize: 11,
                              fontFamily: 'monospace',
                              letterSpacing: 1,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFF00FFFF).withOpacity(0.8), width: 1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Text(
                          '${lab.extractedData.length} markers',
                          style: TextStyle(
                            color: const Color(0xFF00FFFF).withOpacity(0.9),
                            fontSize: 8,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Individual biomarker cards - SORTED BY PRIORITY
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Builder(
              builder: (context) {
                // Debug logging
                print('[LabsScreen] Biomarkers in report: ${lab.extractedData.keys.toList()}');
                print('[LabsScreen] After normalization: ${lab.extractedData.keys.map(_normalizeBiomarkerKey).toList()}');

                return Column(
                  children: (lab.extractedData.entries.toList()
                    ..sort((a, b) => _getBiomarkerPriority(a.key).compareTo(_getBiomarkerPriority(b.key)))
                  ).map((entry) {
                final isOut = _isOutOfRange(entry.key, entry.value);
                final displayValue = entry.value is Map
                  ? (entry.value['value']?.toString() ?? 'N/A')
                  : entry.value.toString();
                final status = entry.value is Map
                  ? (entry.value['status']?.toString() ?? 'NORMAL')
                  : 'NORMAL';
                final hint = _getBiomarkerHint(entry.key);
                final icon = _getBiomarkerIcon(entry.key);
                final statusColor = _getStatusColor(status);
                final categoryColor = _getCategoryColor(entry.key);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: categoryColor.withOpacity(0.7),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: categoryColor.withOpacity(0.3),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Scanlines
                        Positioned.fill(
                          child: CustomPaint(
                            painter: common.ScanlinesPainter(
                              opacity: 0.05,
                              spacing: 3.0,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            // Left side: Icon + Name + Description
                            Expanded(
                              child: Row(
                                children: [
                                  Icon(
                                    icon,
                                    color: categoryColor,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          _beautifyBiomarkerName(entry.key),
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                            decoration: TextDecoration.none,
                                                      ),
                                        ),
                                        if (hint.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            hint,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: AppColors.textMid,
                                              decoration: TextDecoration.none,
                                                          ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Right side: Value + Unit + Status
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      displayValue,
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: statusColor,
                                        decoration: TextDecoration.none,
                                              ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _getUnitForBiomarker(entry.key),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textMid,
                                        decoration: TextDecoration.none,
                                              ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                // Status badge
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: Text(
                                    status.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: statusColor,
                                      fontWeight: FontWeight.w600,
                                      decoration: TextDecoration.none,
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
                );
              },
            ),
          ),

          const SizedBox(height: 60),
        ],
      ),
    );
  }


  // Normalize biomarker keys to handle variations
  String _normalizeBiomarkerKey(String key) {
    final normalized = key.toLowerCase()
      .replaceAll(' ', '_')
      .replaceAll('-', '_')
      .replaceAll('(', '')
      .replaceAll(')', '')
      .replaceAll(',', '');

    // Handle common variations
    final variations = {
      'vitamin_d_25_hydroxy': 'vitamin_d',
      'vitamin_d_25oh': 'vitamin_d',
      '25_hydroxy_vitamin_d': 'vitamin_d',
      'cholesterol_total': 'total_cholesterol',
      'chol_total': 'total_cholesterol',
      'ldl_cholesterol': 'ldl',
      'ldl_chol': 'ldl',
      'hdl_cholesterol': 'hdl',
      'hdl_chol': 'hdl',
      'triglyceride': 'triglycerides',
      'trig': 'triglycerides',
      'hemoglobin_a1c': 'hba1c',
      'glycated_hemoglobin': 'hba1c',
      'free_test': 'free_testosterone',
      'testosterone_free': 'free_testosterone',
      'estrogen': 'estradiol',
      'e2': 'estradiol',
      'white_blood_cell': 'wbc',
      'white_blood_cells': 'wbc',
      'red_blood_cell': 'rbc',
      'red_blood_cells': 'rbc',
      'platelet_count': 'platelets',
      'glomerular_filtration_rate': 'egfr',
      'estimated_gfr': 'egfr',
      'c_reactive_protein': 'crp',
      'hs_crp': 'crp',
      'apolipoprotein_b': 'apob',
      'lipoprotein_a': 'lp_a',
      'thyroxine': 't4',
      'free_t4': 't4',
      'dheas': 'dhea',
      'dhea_sulfate': 'dhea',
      'fasting_insulin': 'insulin_fasting',
      'vitamin_b12': 'b12',
      'vitamin_b_12': 'b12',
      'serum_b12': 'b12',
      'methylcobalamin': 'cobalamin',
      'hydroxocobalamin': 'cobalamin',
      'serum_cobalamin': 'cobalamin',
    };
    
    return variations[normalized] ?? normalized;
  }

  String _beautifyBiomarkerName(String key) {
    final normalizedKey = _normalizeBiomarkerKey(key);

    final names = {
      // Hormones
      'testosterone': 'Testosterone',
      'free_testosterone': 'Free Testosterone',
      'estradiol': 'Estradiol',
      'progesterone': 'Progesterone',
      'dhea': 'DHEA',
      'cortisol': 'Cortisol',
      'prolactin': 'Prolactin',

      // Thyroid
      'tsh': 'TSH',
      't3': 'T3',
      't4': 'T4',

      // Growth factors
      'igf1': 'IGF-1',
      'hgh': 'HGH',

      // Metabolic + Lipids (HIGH PRIORITY)
      'vitamin_d': 'Vitamin D',
      'hba1c': 'HbA1c',
      'total_cholesterol': 'Total Cholesterol',
      'ldl': 'LDL',
      'hdl': 'HDL',
      'triglycerides': 'Triglycerides',
      'glucose': 'Glucose',
      'insulin': 'Insulin',
      'insulin_fasting': 'Insulin (Fasting)',
      'apob': 'ApoB',
      'apolipoprotein_b': 'ApoB',
      'lp_a': 'Lp(a)',
      'lipoprotein_a': 'Lp(a)',
      'vldl': 'VLDL',

      // Minerals
      'magnesium': 'Magnesium',
      'zinc': 'Zinc',
      'calcium': 'Calcium',
      'b12': 'Vitamin B12',
      'cobalamin': 'Vitamin B12',
      'cyanocobalamin': 'Vitamin B12',

      // Liver
      'alt': 'ALT',
      'ast': 'AST',
      'ggt': 'GGT',

      // Kidney
      'creatinine': 'Creatinine',
      'bun': 'BUN',
      'egfr': 'eGFR',

      // Inflammation
      'crp': 'CRP',
      'esr': 'ESR',
      'homocysteine': 'Homocysteine',

      // CBC
      'wbc': 'WBC',
      'rbc': 'RBC',
      'hemoglobin': 'Hemoglobin',
      'hematocrit': 'Hematocrit',
      'platelets': 'Platelets',
      'neutrophils': 'Neutrophils',
      'lymphocytes': 'Lymphocytes',
      'basophils': 'Basophils',
      'eosinophils': 'Eosinophils',
      'ferritin': 'Ferritin',

      // Other
      'psa': 'PSA',
    };

    // If not found, create readable name from key
    if (!names.containsKey(normalizedKey)) {
      // Convert underscores to spaces and capitalize words
      return normalizedKey
        .split('_')
        .map((word) => word.isNotEmpty ? (word[0].toUpperCase() + word.substring(1)) : '')
        .join(' ');
    }

    return names[normalizedKey]!;
  }

  String _getBiomarkerCategory(String key) {
    final categories = {
      'testosterone': 'Hormones',
      'free_testosterone': 'Hormones',
      'estradiol': 'Hormones',
      'cortisol': 'Hormones',
      'prolactin': 'Hormones',
      'tsh': 'Thyroid',
      't3': 'Thyroid',
      't4': 'Thyroid',
      'igf1': 'Growth Factors',
      'hgh': 'Growth Factors',
      'crp': 'Inflammation',
      'hdl': 'Lipids',
      'ldl': 'Lipids',
      'total_cholesterol': 'Lipids',
      'triglycerides': 'Lipids',
      'glucose': 'Metabolic',
      'insulin': 'Metabolic',
      'hemoglobin_a1c': 'Metabolic',
      'alt': 'Liver',
      'ast': 'Liver',
      'psa': 'Prostate',
      'basophils': 'Blood Count',
      'eosinophils': 'Blood Count',
      'ferritin': 'Blood Count',
      'hematocrit': 'Blood Count',
      'hemoglobin': 'Blood Count',
    };
    return categories[key.toLowerCase()] ?? 'Other';
  }

  String _getBiomarkerHint(String key) {
    final normalizedKey = _normalizeBiomarkerKey(key);

    final hints = {
      // Hormones
      'testosterone': 'Primary male sex hormone',
      'free_testosterone': 'Bioavailable testosterone',
      'estradiol': 'Primary female sex hormone',
      'cortisol': 'Stress hormone',
      'prolactin': 'Milk production hormone',
      'progesterone': 'Female sex hormone',
      'dhea': 'Adrenal hormone',

      // Thyroid
      'tsh': 'Thyroid function',
      't3': 'Active thyroid hormone',
      't4': 'Thyroid hormone',

      // Metabolic + Lipids
      'vitamin_d': 'Bone health & immunity',
      'hba1c': '3-month glucose average',
      'total_cholesterol': 'Overall cholesterol',
      'ldl': 'Bad cholesterol',
      'hdl': 'Good cholesterol',
      'triglycerides': 'Fat in blood',
      'glucose': 'Blood sugar',
      'insulin': 'Blood sugar regulation',
      'insulin_fasting': 'Fasting insulin',
      'igf1': 'Growth & recovery factor',
      'hgh': 'Human growth hormone',
      'apob': 'Cholesterol particles',
      'apolipoprotein_b': 'Cholesterol particles',
      'lp_a': 'Cardiovascular risk',
      'lipoprotein_a': 'Cardiovascular risk',
      'vldl': 'Very low density lipid',

      // Minerals
      'magnesium': 'Muscle & nerve function',
      'zinc': 'Immune & metabolism',
      'calcium': 'Bone & muscle health',
      'b12': 'Energy & nervous system',
      'cobalamin': 'Energy & nervous system',
      'cyanocobalamin': 'Energy & nervous system',

      // Liver
      'alt': 'Liver enzyme',
      'ast': 'Liver enzyme',
      'ggt': 'Liver enzyme',

      // Kidney
      'creatinine': 'Kidney function',
      'bun': 'Kidney function',
      'egfr': 'Kidney filtration rate',

      // Inflammation
      'crp': 'Inflammation marker',
      'esr': 'Inflammation marker',
      'homocysteine': 'Cardiovascular inflammation',

      // CBC
      'wbc': 'White blood cells',
      'rbc': 'Red blood cells',
      'hemoglobin': 'Oxygen carrier',
      'hematocrit': 'Blood volume %',
      'platelets': 'Clotting cells',
      'neutrophils': 'Infection fighters',
      'lymphocytes': 'Immune cells',
      'basophils': 'Allergy cells',
      'eosinophils': 'Parasite fighters',
      'ferritin': 'Iron storage',

      // Other
      'psa': 'Prostate marker',
    };
    return hints[normalizedKey] ?? '';
  }

  IconData _getBiomarkerIcon(String key) {
    final normalizedKey = _normalizeBiomarkerKey(key);

    final icons = {
      // Hormones - fitness/health icons
      'testosterone': Icons.male,
      'free_testosterone': Icons.male,
      'estradiol': Icons.female,
      'progesterone': Icons.female,
      'dhea': Icons.bolt,
      'cortisol': Icons.psychology,
      'prolactin': Icons.health_and_safety,

      // Thyroid - heart/health icons
      'tsh': Icons.monitor_heart,
      't3': Icons.monitor_heart,
      't4': Icons.monitor_heart,

      // Growth factors - trending/growth
      'igf1': Icons.trending_up,
      'hgh': Icons.trending_up,

      // Inflammation - fire
      'crp': Icons.local_fire_department,
      'esr': Icons.local_fire_department,
      'homocysteine': Icons.local_fire_department,

      // Lipids (cholesterol) - heart/water
      'vitamin_d': Icons.wb_sunny,
      'hdl': Icons.trending_up,
      'ldl': Icons.trending_down,
      'total_cholesterol': Icons.favorite,
      'triglycerides': Icons.water_drop,
      'apob': Icons.biotech,
      'apolipoprotein_b': Icons.biotech,
      'lp_a': Icons.warning,
      'lipoprotein_a': Icons.warning,
      'vldl': Icons.water_drop,

      // Metabolic - food/medication
      'glucose': Icons.energy_savings_leaf,
      'insulin': Icons.water_drop,
      'insulin_fasting': Icons.water_drop,
      'hba1c': Icons.calendar_month,

      // Minerals
      'magnesium': Icons.category,
      'zinc': Icons.shield,
      'calcium': Icons.grain,
      'b12': Icons.energy_savings_leaf,
      'cobalamin': Icons.energy_savings_leaf,
      'cyanocobalamin': Icons.energy_savings_leaf,

      // Liver - healing
      'alt': Icons.healing,
      'ast': Icons.healing,
      'ggt': Icons.healing,

      // Kidney - filter/water
      'creatinine': Icons.water,
      'bun': Icons.water,
      'egfr': Icons.filter_alt,

      // Prostate
      'psa': Icons.health_and_safety,

      // Blood count - shield/blood type/waves
      'wbc': Icons.shield,
      'rbc': Icons.bloodtype,
      'basophils': Icons.shield,
      'eosinophils': Icons.shield,
      'neutrophils': Icons.shield,
      'lymphocytes': Icons.shield,
      'ferritin': Icons.bloodtype,
      'hematocrit': Icons.waves,
      'hemoglobin': Icons.opacity,
      'platelets': Icons.healing,
    };
    return icons[normalizedKey] ?? Icons.science;
  }

  String _getUnitForBiomarker(String key) {
    final normalizedKey = _normalizeBiomarkerKey(key);

    final units = {
      // Hormones
      'testosterone': 'ng/dL',
      'free_testosterone': 'pg/mL',
      'estradiol': 'pg/mL',
      'progesterone': 'ng/mL',
      'dhea': 'µg/dL',
      'cortisol': 'µg/dL',
      'prolactin': 'ng/mL',

      // Thyroid
      'tsh': 'mIU/L',
      't3': 'pg/mL',
      't4': 'ng/dL',

      // Growth factors
      'igf1': 'ng/mL',
      'hgh': 'ng/mL',

      // Metabolic + Lipids
      'vitamin_d': 'ng/mL',
      'hba1c': '%',
      'total_cholesterol': 'mg/dL',
      'ldl': 'mg/dL',
      'hdl': 'mg/dL',
      'triglycerides': 'mg/dL',
      'glucose': 'mg/dL',
      'insulin': 'mIU/L',
      'insulin_fasting': 'mIU/L',
      'apob': 'mg/dL',
      'apolipoprotein_b': 'mg/dL',
      'lp_a': 'mg/dL',
      'lipoprotein_a': 'mg/dL',
      'vldl': 'mg/dL',

      // Minerals
      'magnesium': 'mg/dL',
      'zinc': 'µg/dL',
      'calcium': 'mg/dL',
      'b12': 'pg/mL',
      'cobalamin': 'pg/mL',
      'cyanocobalamin': 'pg/mL',

      // Liver
      'alt': 'U/L',
      'ast': 'U/L',
      'ggt': 'U/L',

      // Kidney
      'creatinine': 'mg/dL',
      'bun': 'mg/dL',
      'egfr': 'mL/min',

      // Inflammation
      'crp': 'mg/L',
      'esr': 'mm/hr',
      'homocysteine': 'µmol/L',

      // CBC
      'wbc': 'K/µL',
      'rbc': 'M/µL',
      'hemoglobin': 'g/dL',
      'hematocrit': '%',
      'platelets': 'K/µL',
      'neutrophils': '%',
      'lymphocytes': '%',
      'basophils': '%',
      'eosinophils': '%',
      'ferritin': 'ng/mL',

      // Other
      'psa': 'ng/mL',
    };
    return units[normalizedKey] ?? '';
  }

  int _getTotalMarkerCount() {
    return _labResults.fold<int>(0, (sum, lab) => sum + lab.extractedData.length);
  }

  bool _isOutOfRange(String biomarker, dynamic value) {
    // Extract numeric value (handle both direct values and nested objects)
    double? numValue;
    if (value is num) {
      numValue = value.toDouble();
    } else if (value is Map) {
      final val = value['value'];
      if (val is num) numValue = val.toDouble();
    }

    if (numValue == null) return false;

    final ranges = {
      'testosterone': (300.0, 900.0),
      'igf1': (100.0, 300.0),
      'cortisol': (5.0, 20.0),
    };
    final range = ranges[biomarker.toLowerCase()];
    if (range == null) return false;
    return numValue < range.$1 || numValue > range.$2;
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'NORMAL':
      case 'OPTIMAL':
        return const Color(0xFF10b981); // Green
      case 'BORDERLINE':
      case 'SUBOPTIMAL':
        return const Color(0xFFFF6B00); // Orange
      case 'HIGH':
      case 'LOW':
      case 'OUT OF RANGE':
        return const Color(0xFFFF0040); // Red
      default:
        return AppColors.primary; // Cyan fallback
    }
  }

  // Biomarker priority order (lower = more important, shown first)
  int _getBiomarkerPriority(String key) {
    final normalizedKey = _normalizeBiomarkerKey(key);

    const priorities = {
      // Hormones - Core (10-15)
      'testosterone': 10,
      'free_testosterone': 11,
      'estradiol': 12,
      'tsh': 13,
      'progesterone': 14,
      'dhea': 15,  // MOVED UP from 30 - key adrenal hormone

      // Metabolic + Key Lipids (20-29) - HIGH PRIORITY
      'hba1c': 20,
      'vitamin_d': 21,
      'total_cholesterol': 22,
      'ldl': 23,
      'hdl': 24,
      'triglycerides': 25,
      'glucose': 26,

      // Hormones - Secondary (30-34)
      // dhea moved to 15
      't4': 31,
      'cortisol': 32,
      'insulin': 33,
      'insulin_fasting': 33,

      // Minerals (35-39) - MOVED UP
      'magnesium': 35,
      'zinc': 36,
      'calcium': 37,
      'b12': 38,
      'cobalamin': 38,
      'cyanocobalamin': 38,

      // Advanced Lipids (40-49) - MOVED UP
      'apob': 40,
      'lp_a': 41,
      'apolipoprotein_b': 40,
      'lipoprotein_a': 41,
      'vldl': 42,

      // Growth factors (50-59)
      'igf1': 50,
      'hgh': 51,
      't3': 52,
      'prolactin': 53,

      // Liver (70-79)
      'alt': 70,
      'ast': 71,
      'ggt': 72,

      // Kidney (75-79)
      'creatinine': 75,
      'bun': 76,
      'egfr': 77,

      // Inflammation (90-99)
      'crp': 90,
      'esr': 91,
      'homocysteine': 92,

      // CBC (200+)
      'wbc': 200,
      'rbc': 201,
      'hemoglobin': 202,
      'hematocrit': 203,
      'platelets': 204,
      'neutrophils': 205,
      'lymphocytes': 206,
      'basophils': 207,
      'eosinophils': 208,
      'ferritin': 209,
    };

    return priorities[normalizedKey] ?? 999; // Unknowns go to bottom
  }

  // Get category color for biomarker
  Color _getCategoryColor(String key) {
    final normalizedKey = _normalizeBiomarkerKey(key);

    // Hormones - Purple/Magenta
    if (['testosterone', 'free_testosterone', 'estradiol', 'progesterone', 'dhea',
         'cortisol', 'tsh', 't3', 't4', 'prolactin'].contains(normalizedKey)) {
      return const Color(0xFFB388FF); // Light purple
    }

    // Metabolic - Orange
    if (['glucose', 'insulin', 'insulin_fasting', 'hba1c', 'igf1'].contains(normalizedKey)) {
      return const Color(0xFFFF9100); // Orange
    }

    // Lipids - Blue (includes vitamin D)
    if (['total_cholesterol', 'ldl', 'hdl', 'triglycerides', 'apob', 'apolipoprotein_b',
         'lp_a', 'lipoprotein_a', 'vldl', 'vitamin_d'].contains(normalizedKey)) {
      return const Color(0xFF448AFF); // Blue
    }

    // Minerals - Yellow/Gold
    if (['magnesium', 'zinc', 'calcium'].contains(normalizedKey)) {
      return const Color(0xFFFFD740); // Gold
    }

    // Liver/Kidney - Green
    if (['alt', 'ast', 'ggt', 'creatinine', 'bun', 'egfr'].contains(normalizedKey)) {
      return const Color(0xFF69F0AE); // Green
    }

    // Inflammation - Red
    if (['crp', 'esr', 'homocysteine'].contains(normalizedKey)) {
      return const Color(0xFFFF5252); // Red
    }

    // CBC - Cyan (default)
    return AppColors.primary; // Cyan
  }
}

// Scanlines painter for CRT effect
class _ScanlinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.textDim.withOpacity(0.07)
      ..strokeWidth = 1;

    for (double i = 0; i < size.height; i += 3) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
