import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class AndroidFilePicker {
  static const platform = MethodChannel('com.biohacker.biohacker_app/file_picker');

  /// Pick a PDF file from device storage
  static Future<String?> pickPdfFile() async {
    try {
      final String? result = await platform.invokeMethod('pickPdf');
      return result;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print("Error picking PDF: ${e.message}");
      }
      return null;
    }
  }
}
