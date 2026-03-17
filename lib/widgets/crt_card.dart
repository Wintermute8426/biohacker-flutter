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
