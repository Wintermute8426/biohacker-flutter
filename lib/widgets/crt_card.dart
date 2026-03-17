import 'package:flutter/material.dart';

enum CRTColor { amber, green, cyan, magenta }

class CRTCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final CRTColor color;
  final double? height;
  final VoidCallback? onTap;
  final Widget? trailing;

  const CRTCard({
    Key? key,
    required this.title,
    this.subtitle,
    required this.child,
    this.color = CRTColor.amber,
    this.height,
    this.onTap,
    this.trailing,
  }) : super(key: key);

  Color get _getColor {
    switch (color) {
      case CRTColor.amber:
        return Color(0xFFFF9800);
      case CRTColor.green:
        return Color(0xFF00FF00);
      case CRTColor.cyan:
        return Color(0xFF00FFFF);
      case CRTColor.magenta:
        return Color(0xFFFF00FF);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        margin: EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.black,
              _getColor.withOpacity(0.05),
              Colors.black,
            ],
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _getColor.withOpacity(0.6),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: _getColor.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 3,
            ),
          ],
        ),
        child: Stack(
          children: [
            // Scanlines
            Positioned.fill(
              child: CustomPaint(
                painter: _ScanlinesPainter(color: _getColor),
              ),
            ),

            // Content
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title.toUpperCase(),
                            style: TextStyle(
                              color: _getColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                              fontFamily: 'monospace',
                            ),
                          ),
                          if (subtitle != null) ...[
                            SizedBox(height: 2),
                            Text(
                              subtitle!,
                              style: TextStyle(
                                color: _getColor.withOpacity(0.6),
                                fontSize: 9,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (trailing != null) trailing!,
                    ],
                  ),

                  SizedBox(height: 12),

                  // Child content
                  Expanded(child: child),
                ],
              ),
            ),

            // Dystopian elements
            // Security classification badge (top-right)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  border: Border.all(color: _getColor.withOpacity(0.6), width: 1),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Text(
                  'AUTHORIZED',
                  style: TextStyle(
                    color: _getColor.withOpacity(0.7),
                    fontSize: 7,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // Classification marker (top-left)
            Positioned(
              top: 8,
              left: 8,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.shield_outlined, color: _getColor.withOpacity(0.5), size: 10),
                  SizedBox(width: 3),
                  Text(
                    'DELTA-4',
                    style: TextStyle(
                      color: _getColor.withOpacity(0.5),
                      fontSize: 7,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),

            // Barcode at bottom
            Positioned(
              bottom: 4,
              right: 8,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.qr_code_2, color: _getColor.withOpacity(0.3), size: 12),
                  SizedBox(width: 4),
                  CustomPaint(
                    size: Size(30, 8),
                    painter: _BarcodePainter(color: _getColor),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanlinesPainter extends CustomPainter {
  final Color color;

  _ScanlinesPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.12)
      ..strokeWidth = 1.5;

    for (double i = 0; i < size.height; i += 3) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BarcodePainter extends CustomPainter {
  final Color color;

  _BarcodePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.4)
      ..style = PaintingStyle.fill;

    // Draw random-looking barcode lines
    final barWidths = [2.0, 1.0, 3.0, 1.0, 2.0, 1.0, 2.0, 3.0, 1.0];
    double x = 0;

    for (int i = 0; i < barWidths.length && x < size.width; i++) {
      if (i % 2 == 0) {
        canvas.drawRect(
          Rect.fromLTWH(x, 0, barWidths[i], size.height),
          paint,
        );
      }
      x += barWidths[i];
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
