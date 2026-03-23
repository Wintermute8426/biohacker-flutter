import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../theme/colors.dart';
import '../theme/wintermute_styles.dart';
import '../utils/user_feedback.dart';
import '../models/lab_result.dart';
import '../services/labs_database.dart';
import '../services/android_file_picker.dart';
import '../widgets/city_background.dart';
import '../widgets/cyberpunk_rain.dart';
import '../widgets/app_header.dart';
import '../widgets/common/empty_state.dart';
import '../widgets/full_screen_modal.dart';

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
      if (kDebugMode) print('Error loading labs: $e');
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
          SnackBar(
            content: Text(UserFeedback.getFriendlyErrorMessage(e)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _handleUpload() async {
    try {
      final picker = ImagePicker();
      showModalBottomSheet(
        context: context,
        backgroundColor: const Color(0xFF0A0A0A),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
          side: BorderSide(color: Color(0xFF39FF14), width: 0),
        ),
        builder: (context) => Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0A0A0A),
            border: Border(top: BorderSide(color: AppColors.accent.withOpacity(0.4), width: 1)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Terminal header
              Row(
                children: [
                  Container(width: 3, height: 14, color: AppColors.accent),
                  const SizedBox(width: 8),
                  Icon(Icons.upload_file, color: AppColors.accent, size: 14),
                  const SizedBox(width: 8),
                  Text(
                    '> SELECT INPUT SOURCE',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontFamily: 'monospace',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildUploadOption(
                context,
                icon: Icons.camera_alt,
                label: 'CAMERA CAPTURE',
                sublabel: 'Photograph lab report',
                onTap: () async {
                  Navigator.pop(context);
                  final image = await picker.pickImage(source: ImageSource.camera);
                  if (image != null) await _uploadImage(image);
                },
              ),
              const SizedBox(height: 8),
              _buildUploadOption(
                context,
                icon: Icons.photo_library,
                label: 'GALLERY IMPORT',
                sublabel: 'Upload image from device',
                onTap: () async {
                  Navigator.pop(context);
                  final image = await picker.pickImage(source: ImageSource.gallery);
                  if (image != null) await _uploadImage(image);
                },
              ),
              const SizedBox(height: 8),
              _buildUploadOption(
                context,
                icon: Icons.picture_as_pdf,
                label: 'PDF DOCUMENT',
                sublabel: 'Upload blood test PDF',
                onTap: () async {
                  Navigator.pop(context);
                  final filePath = await AndroidFilePicker.pickPdfFile();
                  if (filePath != null) await _uploadPDF(File(filePath));
                },
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(UserFeedback.getFriendlyErrorMessage(e)),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _uploadImage(XFile image) async {
    setState(() => _isUploading = true);
    try {
      if (kDebugMode) print('Image upload started: ${image.name}');

      // TODO: Call real extraction API once available.
      // For now, save a stub record so the entry persists across app restarts.
      final result = LabResult(
        id: 'lab-${DateTime.now().millisecondsSinceEpoch}',
        userId: _userId,
        pdfPath: image.name,
        uploadDate: DateTime.now(),
        notes: 'Image Upload - Pending Extraction',
        extractedData: {}, // Empty until extraction API is integrated
      );

      // Persist to database so the record survives app restarts (FUNC-001)
      await _labsDb.saveLabResult(result);

      if (mounted) {
        setState(() {
          _labResults.insert(0, result);
          _isUploading = false;
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lab result added successfully'),
            backgroundColor: AppColors.accent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(UserFeedback.getFriendlyErrorMessage(e)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _uploadPDF(File pdfFile) async {
    // SEC-001: PDF endpoint must be a production HTTPS URL.
    // Set LAB_PDF_ENDPOINT in .env before enabling this feature in production.
    // Never use a plaintext HTTP or private-IP endpoint in production.
    final endpoint = dotenv.env['LAB_PDF_ENDPOINT'] ?? '';
    if (endpoint.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF upload is not yet available — coming soon'),
          backgroundColor: AppColors.surface,
        ),
      );
      return;
    }

    setState(() => _isUploading = true);
    try {
      if (kDebugMode) print('PDF upload started: ${pdfFile.path}');

      // Read PDF file
      final bytes = await pdfFile.readAsBytes();
      final fileName = pdfFile.path.split('/').last;

      // Send to backend for extraction (HTTPS endpoint loaded from env)
      final request = http.MultipartRequest('POST', Uri.parse(endpoint));

      request.headers['Authorization'] = 'Bearer ${dotenv.env['LAB_PDF_API_KEY'] ?? ''}';

      request.files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: fileName),
      );

      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final result = jsonDecode(responseData);
        final extractedBiomarkers = Map<String, dynamic>.from(result['biomarkers'] ?? {});

        if (kDebugMode) print('Extracted ${extractedBiomarkers.length} biomarkers from PDF');

        final labResult = LabResult(
          id: 'lab-${DateTime.now().millisecondsSinceEpoch}',
          userId: _userId,
          pdfPath: pdfFile.path,
          uploadDate: DateTime.now(),
          notes: 'PDF Upload ($fileName)',
          extractedData: extractedBiomarkers,
        );

        if (kDebugMode) print('[Labs] Saving lab result to database...');
        await _labsDb.saveLabResult(labResult);
        if (kDebugMode) print('[Labs] Lab result saved successfully');

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
      if (kDebugMode) print('Error uploading PDF: $e');
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(UserFeedback.getFriendlyErrorMessage(e)),
            backgroundColor: AppColors.error,
          ),
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
        title: Text('Delete Lab Report?', style: TextStyle(color: AppColors.textLight)),
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
      if (kDebugMode) print('Error deleting lab result: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(UserFeedback.getFriendlyErrorMessage(e)),
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

    const Color labGreen = AppColors.accent;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // > UPLOAD NEW LAB
        _buildLabSection(
          '> UPLOAD NEW LAB',
          Icons.upload_file,
          labGreen,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SUBMIT BLOODWORK PDF OR IMAGE FOR BIOMARKER EXTRACTION',
                style: TextStyle(
                  color: AppColors.textDim,
                  fontSize: 9,
                  fontFamily: 'monospace',
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: _isUploading ? null : _handleUpload,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: _isUploading ? Colors.transparent : labGreen.withOpacity(0.08),
                    border: Border.all(
                      color: _isUploading ? AppColors.textDim : labGreen.withOpacity(0.5),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isUploading) ...[
                        SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(labGreen),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ] else ...[
                        Icon(Icons.add, color: labGreen, size: 13),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        _isUploading ? 'PROCESSING...' : 'UPLOAD REPORT',
                        style: TextStyle(
                          color: _isUploading ? AppColors.textDim : labGreen,
                          fontSize: 11,
                          fontFamily: 'monospace',
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
        const SizedBox(height: 16),

        if (_labResults.isEmpty) ...[
          const SizedBox(height: 24),
          const EmptyState(
            icon: Icons.science,
            title: 'No lab results yet',
            message: 'Upload your first lab report to start tracking biomarkers',
          ),
        ] else ...[
          // > LAB HISTORY header
          Row(
            children: [
              Container(width: 3, height: 14, color: labGreen),
              const SizedBox(width: 8),
              Icon(Icons.history, color: labGreen, size: 13),
              const SizedBox(width: 8),
              Text(
                '> LAB HISTORY',
                style: TextStyle(
                  color: labGreen,
                  fontFamily: 'monospace',
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const Spacer(),
              Text(
                '${_labResults.length} DATES  ·  ${_getTotalMarkerCount()} MARKERS',
                style: TextStyle(
                  color: AppColors.textDim,
                  fontSize: 9,
                  fontFamily: 'monospace',
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._labResults.map((lab) => _buildLabResultCard(lab)).toList(),
        ],
      ],
    );
  }


  Widget _buildLabResultCard(LabResult lab) {
    const Color labGreen = AppColors.accent;
    final markerCount = lab.extractedData.length;
    final outOfRangeCount = lab.extractedData.entries
        .where((e) => _isOutOfRange(e.key, e.value))
        .length;

    return GestureDetector(
      onTap: () => _showLabDetail(lab),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0A0A0A),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: outOfRangeCount > 0
                ? AppColors.error.withOpacity(0.4)
                : labGreen.withOpacity(0.25),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                // Left accent bar
                Container(width: 3, height: 14, color: labGreen),
                const SizedBox(width: 8),
                Text(
                  DateFormat('MMM d, yyyy').format(lab.uploadDate).toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.textLight,
                    fontFamily: 'monospace',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    decoration: TextDecoration.none,
                  ),
                ),
                const Spacer(),
                // Marker count badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: labGreen.withOpacity(0.08),
                    border: Border.all(color: labGreen.withOpacity(0.3), width: 1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text(
                    '$markerCount MARKERS',
                    style: TextStyle(
                      color: labGreen.withOpacity(0.9),
                      fontSize: 9,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
                if (outOfRangeCount > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      border: Border.all(color: AppColors.error.withOpacity(0.5), width: 1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Text(
                      '$outOfRangeCount OUT',
                      style: TextStyle(
                        color: AppColors.error,
                        fontSize: 9,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: 8),
                // Delete button
                GestureDetector(
                  onTap: () => _deleteLabResult(lab),
                  child: Icon(Icons.delete_outline, color: AppColors.textDim, size: 16),
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right, color: AppColors.textDim, size: 16),
              ],
            ),
            if (markerCount > 0) ...[
              const SizedBox(height: 12),
              // Biomarker preview chips
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: (lab.extractedData.entries.toList()
                  ..sort((a, b) => _getBiomarkerPriority(a.key).compareTo(_getBiomarkerPriority(b.key)))
                ).take(6).map((entry) {
                  final isOut = _isOutOfRange(entry.key, entry.value);
                  final displayValue = entry.value is Map
                    ? (entry.value['value']?.toString() ?? 'N/A')
                    : entry.value.toString();
                  final categoryColor = _getCategoryColor(entry.key);
                  final chipColor = isOut ? AppColors.error : categoryColor;

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: chipColor.withOpacity(0.07),
                      border: Border.all(color: chipColor.withOpacity(0.35), width: 1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Text(
                      '${_beautifyBiomarkerName(entry.key)}: $displayValue${isOut ? ' ▲' : ''}',
                      style: TextStyle(
                        color: chipColor.withOpacity(0.9),
                        fontSize: 9,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  );
                }).toList(),
              ),
              if (markerCount > 6) ...[
                const SizedBox(height: 6),
                Text(
                  '+ ${markerCount - 6} MORE BIOMARKERS',
                  style: TextStyle(
                    color: AppColors.textDim,
                    fontSize: 9,
                    fontFamily: 'monospace',
                    letterSpacing: 0.5,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  void _showLabDetail(LabResult lab) {
    const Color labGreen = AppColors.accent;
    final outOfRangeCount = lab.extractedData.entries
        .where((e) => _isOutOfRange(e.key, e.value))
        .length;

    FullScreenModal.show(
      context: context,
      title: 'Lab Analysis',
      borderColor: labGreen,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 80),
        children: [
          // > LAB OVERVIEW section
          _buildLabSection(
            '> LAB OVERVIEW',
            Icons.biotech,
            labGreen,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('DATE', DateFormat('MMM d, yyyy').format(lab.uploadDate).toUpperCase()),
                _buildDetailRow('MARKERS', '${lab.extractedData.length}'),
                if (outOfRangeCount > 0)
                  _buildDetailRow('OUT OF RANGE', '$outOfRangeCount', valueColor: AppColors.error),
                if (lab.notes != null && lab.notes!.isNotEmpty)
                  _buildDetailRow('SOURCE', lab.notes!),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // > BIOMARKERS section header
          if (lab.extractedData.isNotEmpty) ...[
            Row(
              children: [
                Container(width: 3, height: 14, color: labGreen),
                const SizedBox(width: 8),
                Icon(Icons.science, color: labGreen, size: 13),
                const SizedBox(width: 8),
                Text(
                  '> BIOMARKERS',
                  style: TextStyle(
                    color: labGreen,
                    fontFamily: 'monospace',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    decoration: TextDecoration.none,
                  ),
                ),
                const Spacer(),
                Text(
                  '${lab.extractedData.length} TOTAL',
                  style: TextStyle(
                    color: AppColors.textDim,
                    fontSize: 9,
                    fontFamily: 'monospace',
                    letterSpacing: 0.5,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Individual biomarker rows - sorted by priority
            Builder(
              builder: (context) {
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
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A0A0A),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: isOut
                                ? AppColors.error.withOpacity(0.45)
                                : categoryColor.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Left accent bar colored by category
                            Container(width: 3, height: 36, color: categoryColor.withOpacity(0.6)),
                            const SizedBox(width: 10),
                            // Icon
                            Icon(icon, color: categoryColor.withOpacity(0.7), size: 16),
                            const SizedBox(width: 10),
                            // Name + hint
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _beautifyBiomarkerName(entry.key),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textLight,
                                      fontFamily: 'monospace',
                                      decoration: TextDecoration.none,
                                    ),
                                  ),
                                  if (hint.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      hint,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: AppColors.textDim,
                                        decoration: TextDecoration.none,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            // Value + unit + status badge
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
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: statusColor,
                                        fontFamily: 'monospace',
                                        decoration: TextDecoration.none,
                                      ),
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      _getUnitForBiomarker(entry.key),
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: AppColors.textDim,
                                        decoration: TextDecoration.none,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.12),
                                    border: Border.all(color: statusColor.withOpacity(0.4), width: 1),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                  child: Text(
                                    status.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 8,
                                      color: statusColor,
                                      fontFamily: 'monospace',
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                      decoration: TextDecoration.none,
                                    ),
                                  ),
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
          ],
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
        return AppColors.error; // Red
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

  // ==================== STYLING HELPERS ====================

  Widget _buildLabSection(String title, IconData icon, Color accentColor, Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0A),
        border: Border.all(color: accentColor.withOpacity(0.25), width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 3, height: 14, color: accentColor),
              const SizedBox(width: 8),
              Icon(icon, color: accentColor, size: 13),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                  letterSpacing: 2,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 10,
              color: AppColors.textDim,
              letterSpacing: 1,
              decoration: TextDecoration.none,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: valueColor ?? AppColors.textLight,
                fontWeight: FontWeight.w500,
                decoration: TextDecoration.none,
              ),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String sublabel,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF0A0A0A),
          border: Border.all(color: AppColors.accent.withOpacity(0.2), width: 1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.accent.withOpacity(0.7), size: 18),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textLight,
                    fontFamily: 'monospace',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  sublabel,
                  style: const TextStyle(
                    color: AppColors.textDim,
                    fontFamily: 'monospace',
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Icon(Icons.chevron_right, color: AppColors.textDim, size: 16),
          ],
        ),
      ),
    );
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

// Barcode painter for cyberpunk aesthetic
class BarcodePainter extends CustomPainter {
  final Color color;

  BarcodePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.6)
      ..strokeWidth = 1.0;

    // Draw random-width barcode lines
    double x = 0;
    final random = [2.0, 1.0, 3.0, 1.0, 2.0, 1.0, 4.0, 2.0, 1.0, 3.0, 1.0, 2.0];
    int index = 0;

    while (x < size.width && index < random.length) {
      final width = random[index % random.length];
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
      x += width;
      index++;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
