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

class LabsScreen extends StatefulWidget {
  const LabsScreen({Key? key}) : super(key: key);

  @override
  State<LabsScreen> createState() => _LabsScreenState();
}

class _LabsScreenState extends State<LabsScreen> with TickerProviderStateMixin {
  final LabsDatabase _labsDb = LabsDatabase();
  late String _userId;
  List<LabResult> _labResults = [];
  bool _isUploading = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _userId = Supabase.instance.client.auth.currentUser?.id ?? '';
    _tabController = TabController(length: 4, vsync: this);
    _loadLabResultsBackground();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadLabResultsBackground() async {
    try {
      final results = await _labsDb.getUserLabResults(_userId);
      if (mounted) {
        setState(() => _labResults = results);
      }
    } catch (e) {
      print('Error loading labs: $e');
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
                // Header with dark background bar
                Container(
                  color: AppColors.surface.withOpacity(0.3),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Icon(Icons.science, color: WintermmuteStyles.colorOrange, size: 28),
                      const SizedBox(width: 12),
                      Text(
                        'LABS',
                        style: WintermmuteStyles.titleStyle,
                      ),
                    ],
                  ),
                ),
                Divider(color: AppColors.primary.withOpacity(0.3), thickness: 1, height: 1),
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  indicatorColor: AppColors.primary,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textMid,
                  labelStyle: WintermmuteStyles.tabLabelStyle,
                  unselectedLabelStyle: WintermmuteStyles.tabLabelStyle.copyWith(
                    color: AppColors.textMid,
                  ),
                  tabs: const [
                    Tab(text: 'ALL RESULTS'),
                    Tab(text: 'OUT OF RANGE'),
                    Tab(text: 'RECENT'),
                    Tab(text: 'UPLOAD'),
                  ],
                ),
                Expanded(
                  child: Stack(
                    children: [
                      TabBarView(
                        controller: _tabController,
                        children: [
                          // Tab 1: All Results
                          _buildAllResultsTab(),
                          // Tab 2: Out of Range
                          _buildOutOfRangeTab(),
                          // Tab 3: Recent
                          _buildRecentTab(),
                          // Tab 4: Upload
                          _buildUploadTab(),
                        ],
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllResultsTab() {
    if (_labResults.isEmpty) {
      return Center(
        child: Text(
          'NO LAB RESULTS',
          style: TextStyle(color: AppColors.textMid, letterSpacing: 1),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
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
    );
  }

  Widget _buildOutOfRangeTab() {
    final outOfRange = _labResults.where((lab) {
      // Count biomarkers that are out of range (simplified)
      int count = 0;
      lab.extractedData.forEach((key, value) {
        if (_isOutOfRange(key, value)) {
          count++;
        }
      });
      return count > 0;
    }).toList();

    if (outOfRange.isEmpty) {
      return Center(
        child: Text(
          'NO OUT OF RANGE MARKERS',
          style: TextStyle(color: AppColors.accent, letterSpacing: 1),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          '${outOfRange.length} tests with out-of-range markers',
          style: TextStyle(
            color: AppColors.textMid,
            fontSize: 11,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 16),
        ...outOfRange.map((lab) => _buildLabResultCard(lab)).toList(),
      ],
    );
  }

  Widget _buildRecentTab() {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    final recent = _labResults.where((lab) => lab.uploadDate.isAfter(thirtyDaysAgo)).toList();

    if (recent.isEmpty) {
      return Center(
        child: Text(
          'NO RECENT LABS (30 DAYS)',
          style: TextStyle(color: AppColors.textMid, letterSpacing: 1),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          '${recent.length} labs from last 30 days',
          style: TextStyle(
            color: AppColors.textMid,
            fontSize: 11,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 16),
        ...recent.map((lab) => _buildLabResultCard(lab)).toList(),
      ],
    );
  }

  Widget _buildUploadTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.upload_file, size: 48, color: AppColors.primary),
          const SizedBox(height: 16),
          Text(
            'UPLOAD LAB REPORT',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Take a photo or upload an image of your lab report. Results will be extracted automatically.',
              style: TextStyle(
                color: AppColors.textMid,
                fontSize: 12,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          GestureDetector(
            onTap: _isUploading ? null : _handleUpload,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(
                  color: _isUploading ? AppColors.textMid : AppColors.primary.withOpacity(0.2), // Matte style
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isUploading) ...[
                    SizedBox(
                      width: 16,
                      height: 16,
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
                      fontSize: 12,
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
    );
  }

  Widget _buildLabResultCard(LabResult lab) {
    return GestureDetector(
      onTap: () => _showLabDetail(lab),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: WintermmuteStyles.cardDecoration,
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
                    Icon(Icons.chevron_right, color: AppColors.primary, size: 18),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: lab.extractedData.entries.take(6).map((entry) {
                final isOut = _isOutOfRange(entry.key, entry.value);
                final displayValue = entry.value is Map 
                  ? (entry.value['value']?.toString() ?? 'N/A')
                  : entry.value.toString();
                
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.surface.withOpacity(0.15),
                    border: Border.all(
                      color: isOut ? AppColors.error.withOpacity(0.2) : AppColors.primary.withOpacity(0.2),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text(
                    '${entry.key}: $displayValue${isOut ? ' [HIGH]' : ''}',
                    style: TextStyle(
                      color: isOut ? AppColors.error : AppColors.textMid,
                      fontSize: 10,
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
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        builder: (context, scrollController) => Container(
          color: AppColors.background,
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(16),
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'LAB REPORT',
                        style: TextStyle(
                          color: AppColors.textMid,
                          fontSize: 11,
                          letterSpacing: 1,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('MMMM d, yyyy').format(lab.uploadDate),
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    color: AppColors.primary,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Lab metadata
              if (lab.notes != null && lab.notes!.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: WintermmuteStyles.cardDecoration,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SOURCE',
                        style: TextStyle(
                          color: AppColors.textMid,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        lab.notes!,
                        style: TextStyle(color: AppColors.textMid, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // All biomarkers header
              Container(
                padding: const EdgeInsets.all(12),
                decoration: WintermmuteStyles.cardDecoration,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'ALL BIOMARKERS',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.surface.withOpacity(0.15),
                            border: Border.all(
                              color: AppColors.accent.withOpacity(0.2),
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Text(
                            '${lab.extractedData.length} markers',
                            style: TextStyle(
                              color: AppColors.textMid,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              ...lab.extractedData.entries.map((entry) {
                final isOut = _isOutOfRange(entry.key, entry.value);
                final displayValue = entry.value is Map 
                  ? (entry.value['value']?.toString() ?? 'N/A')
                  : entry.value.toString();
                final status = entry.value is Map
                  ? (entry.value['status']?.toString() ?? 'NORMAL')
                  : 'NORMAL';
                final category = _getBiomarkerCategory(entry.key);
                final hint = _getBiomarkerHint(entry.key);

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: WintermmuteStyles.customCardDecoration(
                    borderColor: isOut ? AppColors.error : AppColors.primary,
                    backgroundColor: AppColors.surface.withOpacity(0.15),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top row: Name + Status
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _beautifyBiomarkerName(entry.key),
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                if (hint.isNotEmpty)
                                  Text(
                                    hint,
                                    style: TextStyle(
                                      color: AppColors.textMid,
                                      fontSize: 10,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.surface.withOpacity(0.15),
                              border: Border.all(
                                color: isOut
                                  ? AppColors.error.withOpacity(0.2)
                                  : AppColors.accent.withOpacity(0.2),
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              isOut ? 'OUT OF\nRANGE' : status,
                              style: TextStyle(
                                color: isOut ? AppColors.error : AppColors.textMid,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Value + Unit + Category
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            displayValue,
                            style: TextStyle(
                              color: AppColors.textMid,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getUnitForBiomarker(entry.key),
                                  style: TextStyle(
                                    color: AppColors.textMid,
                                    fontSize: 10,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                  child: Text(
                                    category,
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  String _beautifyBiomarkerName(String key) {
    final names = {
      'testosterone': 'Testosterone',
      'free_testosterone': 'Free Testosterone',
      'estradiol': 'Estradiol',
      'igf1': 'IGF-1',
      'hgh': 'HGH',
      'crp': 'CRP (High Sensitivity)',
      'hdl': 'HDL Cholesterol',
      'ldl': 'LDL Cholesterol',
      'total_cholesterol': 'Total Cholesterol',
      'triglycerides': 'Triglycerides',
      'glucose': 'Glucose',
      'insulin': 'Insulin',
      'cortisol': 'Cortisol',
      'alt': 'ALT',
      'ast': 'AST',
      'tsh': 'TSH',
      't3': 'T3',
      't4': 'T4',
      'prolactin': 'Prolactin',
      'psa': 'PSA',
      'basophils': 'Basophils',
      'eosinophils': 'Eosinophils',
      'ferritin': 'Ferritin',
      'hematocrit': 'Hematocrit',
      'hemoglobin': 'Hemoglobin',
      'hemoglobin_a1c': 'Hemoglobin A1C',
    };
    return names[key.toLowerCase()] ?? key;
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
    final hints = {
      'testosterone': 'Primary male sex hormone',
      'free_testosterone': 'Bioavailable testosterone',
      'estradiol': 'Primary female sex hormone',
      'cortisol': 'Stress hormone',
      'prolactin': 'Milk production hormone',
      'tsh': 'Thyroid stimulating hormone',
      't3': 'Active thyroid hormone',
      't4': 'Thyroid storage hormone',
      'igf1': 'Growth & recovery factor',
      'hgh': 'Human growth hormone',
      'crp': 'Inflammation marker',
      'hdl': 'Good cholesterol',
      'ldl': 'LDL cholesterol',
      'total_cholesterol': 'Total blood cholesterol',
      'triglycerides': 'Blood fat storage',
      'glucose': 'Blood sugar level',
      'insulin': 'Blood sugar regulator',
      'hemoglobin_a1c': '3-month glucose average',
      'alt': 'Liver enzyme',
      'ast': 'Liver enzyme',
      'psa': 'Prostate marker',
      'basophils': 'White blood cell type',
      'eosinophils': 'White blood cell type',
      'ferritin': 'Iron storage protein',
      'hematocrit': 'Red blood cell % in blood',
      'hemoglobin': 'Oxygen-carrying protein',
    };
    return hints[key.toLowerCase()] ?? '';
  }

  String _getUnitForBiomarker(String key) {
    final units = {
      'testosterone': 'ng/dL',
      'free_testosterone': 'pg/mL',
      'estradiol': 'pg/mL',
      'igf1': 'ng/mL',
      'hgh': 'ng/mL',
      'crp': 'mg/L',
      'hdl': 'mg/dL',
      'ldl': 'mg/dL',
      'total_cholesterol': 'mg/dL',
      'triglycerides': 'mg/dL',
      'glucose': 'mg/dL',
      'insulin': 'mIU/L',
      'cortisol': 'µg/dL',
      'alt': 'U/L',
      'ast': 'U/L',
      'tsh': 'mIU/L',
      't3': 'pg/mL',
      't4': 'ng/dL',
      'prolactin': 'ng/mL',
      'psa': 'ng/mL',
    };
    return units[key.toLowerCase()] ?? '';
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
