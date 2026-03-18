import 'package:flutter/material.dart';
import '../theme/colors.dart';

class LegalScreen extends StatefulWidget {
  final String title;
  final String content;

  const LegalScreen({
    Key? key,
    required this.title,
    required this.content,
  }) : super(key: key);

  @override
  State<LegalScreen> createState() => _LegalScreenState();
}

class _LegalScreenState extends State<LegalScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF00FFFF)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Color(0xFF00FFFF),
            fontFamily: 'Courier New',
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        centerTitle: true,
      ),
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 60),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF00FFFF), width: 1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Stack(
            children: [
              // Scanlines overlay
              Positioned.fill(
                child: CustomPaint(
                  painter: _ScanlinesPainter(),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(20),
                child: _buildContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final lines = widget.content.split('\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        if (line.startsWith('# ')) {
          return Padding(
            padding: const EdgeInsets.only(top: 24, bottom: 12),
            child: Text(
              line.replaceFirst('# ', ''),
              style: const TextStyle(
                color: Color(0xFF00FFFF),
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'Courier New',
                letterSpacing: 1,
              ),
            ),
          );
        } else if (line.startsWith('## ')) {
          return Padding(
            padding: const EdgeInsets.only(top: 18, bottom: 10),
            child: Text(
              line.replaceFirst('## ', ''),
              style: const TextStyle(
                color: Color(0xFFFF9800),
                fontSize: 13,
                fontWeight: FontWeight.bold,
                fontFamily: 'Courier New',
              ),
            ),
          );
        } else if (line.startsWith('### ')) {
          return Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Text(
              line.replaceFirst('### ', ''),
              style: const TextStyle(
                color: Color(0xFFCCCCCC),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFamily: 'Courier New',
              ),
            ),
          );
        } else if (line.startsWith('- ')) {
          return Padding(
            padding: const EdgeInsets.only(left: 20, top: 6, bottom: 6),
            child: Text(
              '• ${line.replaceFirst('- ', '')}',
              style: const TextStyle(
                color: Color(0xFFCCCCCC),
                fontSize: 12,
                fontFamily: 'Courier New',
              ),
            ),
          );
        } else if (line.trim().isEmpty) {
          return const SizedBox(height: 8);
        } else {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              line,
              style: const TextStyle(
                color: Color(0xFFCCCCCC),
                fontSize: 12,
                fontFamily: 'Courier New',
                height: 1.6,
              ),
            ),
          );
        }
      }).toList(),
    );
  }
}

class _ScanlinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00FFFF).withOpacity(0.05)
      ..strokeWidth = 1;

    for (double i = 0; i < size.height; i += 3) {
      canvas.drawLine(
        Offset(0, i),
        Offset(size.width, i),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
