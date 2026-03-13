import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Generate the icon at 1024x1024 (master size)
  final image = await generateBHIcon(1024);

  // Save master icon
  await saveImage(image, 'assets/icon/app_icon.png');

  // Generate Android icons
  final sizes = {
    'mipmap-mdpi': 48,
    'mipmap-hdpi': 72,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192,
  };

  for (var entry in sizes.entries) {
    final resized = await generateBHIcon(entry.value);
    await saveImage(
      resized,
      'android/app/src/main/res/${entry.key}/ic_launcher.png',
    );
  }

  print('✓ Icon generation complete!');
  exit(0);
}

Future<ui.Image> generateBHIcon(int size) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final paint = Paint()..isAntiAlias = true;

  // Background - pure black
  paint.color = const Color(0xFF000000);
  canvas.drawRect(
    Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble()),
    paint,
  );

  // Draw subtle grid pattern
  paint.color = const Color(0xFF0A0A0A);
  paint.strokeWidth = size * 0.002;
  final gridSpacing = size / 20;
  for (double i = 0; i <= size; i += gridSpacing) {
    canvas.drawLine(Offset(i, 0), Offset(i, size.toDouble()), paint);
    canvas.drawLine(Offset(0, i), Offset(size.toDouble(), i), paint);
  }

  // Draw BH letters
  final textPainter = TextPainter(
    textDirection: TextDirection.ltr,
  );

  // Main BH text - Cyan
  textPainter.text = TextSpan(
    text: 'BH',
    style: TextStyle(
      fontSize: size * 0.5,
      fontWeight: FontWeight.w900,
      color: const Color(0xFF00FFFF), // Cyan
      fontFamily: 'monospace',
      letterSpacing: size * 0.02,
    ),
  );

  textPainter.layout();

  // Center the text
  final xCenter = (size - textPainter.width) / 2;
  final yCenter = (size - textPainter.height) / 2;

  // Draw green glow (outer shadow)
  for (int i = 3; i > 0; i--) {
    final glowPaint = Paint()
      ..color = const Color(0xFF39FF14).withOpacity(0.3 / i)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, size * 0.02 * i);

    canvas.save();
    canvas.translate(xCenter, yCenter);
    textPainter.paint(canvas, Offset.zero);
    canvas.restore();
  }

  // Draw main cyan text
  textPainter.paint(canvas, Offset(xCenter, yCenter));

  // Draw cyan glow
  for (int i = 2; i > 0; i--) {
    final cyanGlow = Paint()
      ..color = const Color(0xFF00FFFF).withOpacity(0.4 / i)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, size * 0.015 * i);

    canvas.save();
    canvas.translate(xCenter, yCenter);
    textPainter.paint(canvas, Offset.zero);
    canvas.restore();
  }

  final picture = recorder.endRecording();
  return await picture.toImage(size, size);
}

Future<void> saveImage(ui.Image image, String path) async {
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  final buffer = byteData!.buffer.asUint8List();

  final file = File(path);
  await file.parent.create(recursive: true);
  await file.writeAsBytes(buffer);

  print('✓ Saved: $path');
}
