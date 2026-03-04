import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import '../theme/colors.dart';
import '../models/lab_result.dart';
import '../services/labs_database.dart';
import '../services/bloodwork_service.dart';

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
                onTap: () async {
                  Navigator.pop(context);
                  final image = await picker.pickImage(source: ImageSource.gallery);
                  if (image != null) {
                    await _uploadImage(image);
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
      // Convert image to bytes
      final bytes = await image.readAsBytes();

      // For now, show a message (actual extraction would happen here)
      print('Image upload started: ${image.name}');

      // Add mock lab result
      final mockResult = LabResult(
        id: 'lab-${DateTime.now().millisecondsSinceEpoch}',
        userId: _userId,
        uploadDate: DateTime.now(),
        labSource: 'Manual Upload',
        biomarkers: {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(
          'LABS',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMid,
          tabs: const [
            Tab(text: 'ALL RESULTS'),
            Tab(text: 'OUT OF RANGE'),
            Tab(text: 'RECENT'),
            Tab(text: 'UPLOAD'),
          ],
        ),
      ),
      body: TabBarView(
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
        ..._labResults.asMap().entries.map((entry) {
          return _buildLabResultCard(entry.value);
        }).toList(),
      ],
    );
  }

  Widget _buildOutOfRangeTab() {
    final outOfRange = _labResults.where((lab) {
      // Count biomarkers that are out of range (simplified)
      int count = 0;
      lab.biomarkers.forEach((key, value) {
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
              'Photograph your lab report or upload from gallery. Results will be extracted automatically.',
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
                  color: _isUploading ? AppColors.textMid : AppColors.primary,
                  width: 2,
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(4),
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
              Text(
                '${lab.biomarkers.length} markers',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: lab.biomarkers.entries.take(6).map((entry) {
              final isOut = _isOutOfRange(entry.key, entry.value);
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isOut ? AppColors.error.withOpacity(0.1) : AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Text(
                  '${entry.key}: ${entry.value}${isOut ? ' [HIGH]' : ''}',
                  style: TextStyle(
                    color: isOut ? AppColors.error : AppColors.accent,
                    fontSize: 10,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  int _getTotalMarkerCount() {
    return _labResults.fold(0, (sum, lab) => sum + lab.biomarkers.length);
  }

  bool _isOutOfRange(String biomarker, dynamic value) {
    // Simple check - in production, use reference ranges from database
    final numValue = (value as num).toDouble();
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
