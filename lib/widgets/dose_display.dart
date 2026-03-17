import 'package:flutter/material.dart';

class DoseDisplay extends StatelessWidget {
  final double doseMg;
  final String peptideName;
  final Color? color;
  final TextStyle? mgStyle;
  final TextStyle? mlStyle;
  final bool showLabel;
  final bool showSyringe;

  const DoseDisplay({
    Key? key,
    required this.doseMg,
    required this.peptideName,
    this.color,
    this.mgStyle,
    this.mlStyle,
    this.showLabel = false,
    this.showSyringe = true, // Show syringe by default
  }) : super(key: key);

  static double calculateMLDraw(String peptideName, double doseMg) {
    // Normalize peptide name (remove extra text in parentheses and trim)
    final normalizedName = peptideName.split('(')[0].trim();

    final reconstitutionData = {
      'BPC-157': [5.0, 2.0],
      'TB-500': [5.0, 2.0],
      'GHK-Cu': [50.0, 2.0],
      'Semaglutide': [5.0, 2.0],
      'Tirzepatide': [10.0, 2.0],
      'CJC-1295': [2.0, 2.0],
      'Ipamorelin': [5.0, 2.0],
      'MOTS-c': [10.0, 2.0],
      'Thymosin Alpha-1': [5.0, 2.0],
      'PT-141': [10.0, 2.0],
    };

    final reconInfo = reconstitutionData[normalizedName];
    if (reconInfo == null) {
      print('[DoseDisplay] WARNING: No recon data for "$peptideName" (normalized: "$normalizedName"), using default 5mg/2mL');
      return (doseMg / 5.0) * 2.0;
    }

    final totalMg = reconInfo[0];
    final totalML = reconInfo[1];
    final concentration = totalMg / totalML; // mg/mL
    final mlDraw = doseMg / concentration;

    print('[DoseDisplay] $normalizedName: ${doseMg}mg from ${totalMg}mg/${totalML}mL = ${concentration}mg/mL → ${mlDraw.toStringAsFixed(3)}mL');

    return mlDraw;
  }

  @override
  Widget build(BuildContext context) {
    final mlDraw = calculateMLDraw(peptideName, doseMg);
    final displayColor = color ?? Color(0xFF00FF00);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showLabel)
          Padding(
            padding: EdgeInsets.only(bottom: 2),
            child: Text(
              'DOSE',
              style: TextStyle(
                fontSize: 9,
                color: displayColor.withOpacity(0.5),
                fontFamily: 'monospace',
                letterSpacing: 0.5,
              ),
            ),
          ),

        // mg dose
        Text(
          '${doseMg.toStringAsFixed(1)}mg',
          style: mgStyle ?? TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: displayColor.withOpacity(0.9),
            fontFamily: 'monospace',
          ),
        ),

        SizedBox(height: 4),

        // Syringe visual + mL amount
        if (showSyringe)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomPaint(
                size: Size(35, 14),
                painter: SyringePainter(
                  fillPercent: (mlDraw / 1.0).clamp(0.0, 1.0), // Assume 1mL max for viz
                  color: displayColor,
                ),
              ),
              SizedBox(width: 6),
              Text(
                '${mlDraw.toStringAsFixed(2)}mL',
                style: mlStyle ?? TextStyle(
                  fontSize: 9,
                  color: displayColor.withOpacity(0.7),
                  fontFamily: 'monospace',
                ),
              ),
            ],
          )
        else
          Text(
            '${mlDraw.toStringAsFixed(2)}mL',
            style: mlStyle ?? TextStyle(
              fontSize: 9,
              color: displayColor.withOpacity(0.7),
              fontFamily: 'monospace',
            ),
          ),
      ],
    );
  }
}

// Enhanced syringe painter with better visuals
class SyringePainter extends CustomPainter {
  final double fillPercent;
  final Color color;

  SyringePainter({
    required this.fillPercent,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Barrel background
    final barrelPaint = Paint()
      ..color = color.withOpacity(0.15)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(2, 2, size.width - 8, size.height - 4),
        Radius.circular(2),
      ),
      barrelPaint,
    );

    // Fill liquid
    if (fillPercent > 0) {
      final fillPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            color.withOpacity(0.9),
            color.withOpacity(0.7),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

      final fillWidth = (size.width - 10) * fillPercent.clamp(0.0, 1.0);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(3, 3, fillWidth, size.height - 6),
          Radius.circular(1),
        ),
        fillPaint,
      );
    }

    // Barrel outline
    final outlinePaint = Paint()
      ..color = color.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(2, 2, size.width - 8, size.height - 4),
        Radius.circular(2),
      ),
      outlinePaint,
    );

    // Plunger
    final plungerPaint = Paint()
      ..color = color.withOpacity(0.9)
      ..strokeWidth = 2.5;
    final plungerX = size.width - 5;
    canvas.drawLine(
      Offset(plungerX, 0),
      Offset(plungerX, size.height),
      plungerPaint,
    );

    // Needle
    final needlePaint = Paint()
      ..color = color.withOpacity(0.6)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(4, size.height / 2),
      needlePaint,
    );

    // Measurement marks (0.25mL increments)
    final markPaint = Paint()
      ..color = color.withOpacity(0.4)
      ..strokeWidth = 1;

    for (int i = 1; i < 4; i++) {
      final x = 3 + ((size.width - 10) * (i / 4));
      canvas.drawLine(
        Offset(x, size.height - 4),
        Offset(x, size.height - 2),
        markPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
