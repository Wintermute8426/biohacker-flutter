import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import '../theme/colors.dart';
import '../models/lab_result.dart';
import '../services/labs_database.dart';
import '../services/bloodwork_service.dart';

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

  @override
  void initState() {
    super.initState();
    _userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    print('=== DEBUG: Labs screen initialized. User ID: $_userId ===');
    // Load in background WITHOUT showing loading state
    _loadLabResultsBackground();
  }

  /// Load lab results in background (no loading state)
  Future<void> _loadLabResultsBackground() async {
    try {
      print('DEBUG: Loading lab results in background for user: $_userId');
      final results = await _labsDb.getUserLabResults(_userId);
      print('DEBUG: Loaded ${results.length} lab results in background');
      if (mounted) {
        setState(() => _labResults = results);
      }
    } catch (e) {
      print('DEBUG: Error loading lab results in background: $e');
      // Silently fail - show empty state
    }
  }

  /// Load all lab results for user
  Future<void> _loadLabResults() async {
    print('DEBUG: _loadLabResults() START');
    if (!mounted) return;
    
    try {
      print('DEBUG: Loading lab results for user: $_userId');
      final results = await _labsDb.getUserLabResults(_userId);
      print('DEBUG: Loaded ${results.length} lab results');
      if (mounted) {
        setState(() => _labResults = results);
      }
    } catch (e) {
      print('DEBUG: Error loading lab results: $e');
      if (mounted) {
        _showError('Failed to load lab results: $e');
      }
    }
  }

  /// Handle file upload (camera or gallery only)
  Future<void> _handleUpload() async {
    try {
      final picker = ImagePicker();
      
      // Show choice: Camera or Gallery (no PDF)
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
                  await _uploadFromSource(picker, ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                subtitle: const Text('Select lab report image'),
                onTap: () async {
                  Navigator.pop(context);
                  await _uploadFromSource(picker, ImageSource.gallery);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
    } catch (e) {
      _showError('Upload failed: $e');
    }
  }

  /// Upload from camera or gallery
  /// Photograph lab report or select image - displays mock biomarker data
  /// Phase 7: Real BloodworkAI API for actual biomarker extraction
  Future<void> _uploadFromSource(ImagePicker picker, ImageSource source) async {
    print('DEBUG: _uploadFromSource() STARTED for source: $source');
    try {
      print('DEBUG: Setting _isUploading = true');
      setState(() => _isUploading = true);

      print('DEBUG: Opening image picker for source: $source');
      final image = await picker.pickImage(source: source);
      print('DEBUG: Image picker returned: ${image?.path ?? "null"}');
      if (image == null) {
        print('DEBUG: Image was null, returning');
        return;
      }

      // Create lab result with mock biomarker data
      final mockData = BloodworkService.getMockResponse();
      
      final labResult = LabResult(
        id: 'lab_${DateTime.now().millisecondsSinceEpoch}',
        userId: _userId,
        pdfPath: image.path,
        extractedData: mockData['biomarkers'] as Map<String, dynamic>,
        uploadDate: DateTime.now(),
        processedDate: DateTime.now(),
        notes: 'Lab report uploaded on ${DateTime.now().toString().split(' ')[0]}',
      );

      // Save to Supabase
      print('DEBUG: Saving lab result to Supabase: ${labResult.id}');
      await _labsDb.saveLabResult(labResult);
      print('DEBUG: Lab result saved successfully');

      // Add to local list instead of reloading from DB
      if (mounted) {
        print('DEBUG: Adding result to local list. Total results: ${_labResults.length + 1}');
        setState(() {
          _labResults.insert(0, labResult);
          _isUploading = false;
          print('DEBUG: setState complete. Total results now: ${_labResults.length}');
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lab report uploaded and processed'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('DEBUG: Upload error: $e');
      _showError('Upload failed: $e');
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  /// Show error message
  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  /// Show lab result details
  void _showResultDetails(LabResult result) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (context) => _buildResultDetailsSheet(result),
    );
  }

  /// Build result details sheet
  Widget _buildResultDetailsSheet(LabResult result) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'LAB RESULTS',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.primary,
                  letterSpacing: 1,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Date
          Text(
            'Uploaded: ${result.uploadDate.toString().split(' ')[0]}',
            style: TextStyle(color: AppColors.textDim, fontSize: 12),
          ),
          const SizedBox(height: 20),

          // Key Biomarkers
          if (result.testosterone != null) ...[
            _buildBiomarkerRow('TESTOSTERONE', '${result.testosterone} ng/dL', result.testosteroneStatus),
          ],
          if (result.cortisol != null) ...[
            _buildBiomarkerRow('CORTISOL', '${result.cortisol} µg/dL', result.cortisolStatus),
          ],
          if (result.glucose != null) ...[
            _buildBiomarkerRow('GLUCOSE', '${result.glucose} mg/dL', 'NORMAL'),
          ],

          // All extracted data
          const SizedBox(height: 20),
          Text(
            'All Biomarkers',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          ...result.extractedData.entries
              .where((e) => e.value != null && e.key != 'extracted_at')
              .map((e) {
                String displayValue = '';
                if (e.value is Map) {
                  final map = e.value as Map;
                  displayValue = map.entries
                      .map((entry) => '${entry.key}: ${entry.value}')
                      .join(', ');
                } else {
                  displayValue = e.value.toString();
                }
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        e.key.replaceAll('_', ' ').toUpperCase(),
                        style: TextStyle(color: AppColors.textMid, fontSize: 11),
                      ),
                      Flexible(
                        child: Text(
                          displayValue,
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.end,
                        ),
                      ),
                    ],
                  ),
                );
              })
              .toList(),

          // Notes
          if (result.notes != null && result.notes!.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              'Notes',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              result.notes!,
              style: TextStyle(color: AppColors.textLight, fontSize: 11),
            ),
          ],

          // Delete button
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                await _labsDb.deleteLabResult(result.id);
                if (mounted) {
                  Navigator.pop(context);
                  _loadLabResults();
                }
              },
              icon: const Icon(Icons.delete),
              label: const Text('DELETE RESULT'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build biomarker row
  Widget _buildBiomarkerRow(String label, String value, String? status) {
    Color statusColor = Colors.grey;
    if (status == 'OPTIMAL') statusColor = Colors.green;
    else if (status == 'HIGH' || status == 'LOW') statusColor = Colors.orange;
    else if (status == 'CRITICAL') statusColor = Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(color: statusColor.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: AppColors.textMid,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.2),
              border: Border.all(color: statusColor.withOpacity(0.5)),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              status ?? 'N/A',
              style: TextStyle(
                color: statusColor,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'LABS',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isUploading ? null : _handleUpload,
                  icon: _isUploading
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation(AppColors.background),
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.cloud_upload),
                  label: Text(_isUploading ? 'UPLOADING...' : 'UPLOAD'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: Container(
              color: AppColors.background,
              child: _labResults.isEmpty
                  ? SingleChildScrollView(
                      child: _buildEmptyState(),
                    )
                  : _buildResultsList(),
            ),
          ),
        ],
      ),
    );
  }

  /// Build empty state
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.science_outlined,
              color: AppColors.primary,
              size: 64,
            ),
            const SizedBox(height: 24),
            Text(
              'No lab results yet',
              style: TextStyle(
                color: AppColors.textLight,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Tap UPLOAD to add your lab report',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textDim,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build results list
  Widget _buildResultsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16).copyWith(bottom: 120),
      itemCount: _labResults.length,
      itemBuilder: (context, index) {
        final result = _labResults[index];
        return GestureDetector(
          onTap: () => _showResultDetails(result),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Lab Results',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      result.uploadDate.toString().split(' ')[0],
                      style: TextStyle(color: AppColors.textDim, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (result.testosterone != null)
                  Text(
                    'Test: ${result.testosterone} ng/dL',
                    style: TextStyle(color: AppColors.textLight, fontSize: 12),
                  ),
                if (result.cortisol != null)
                  Text(
                    'Cortisol: ${result.cortisol} µg/dL',
                    style: TextStyle(color: AppColors.textLight, fontSize: 12),
                  ),
                const SizedBox(height: 8),
                Text(
                  'Tap to view full results',
                  style: TextStyle(color: AppColors.textDim, fontSize: 10),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
