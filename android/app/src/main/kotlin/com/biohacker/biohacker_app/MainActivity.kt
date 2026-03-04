package com.biohacker.biohacker_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import android.app.Activity

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.biohacker.biohacker_app/file_picker"
    private val FILE_PICKER_REQUEST = 12345

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "pickPdf" -> {
                    pickPdfFile(result)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun pickPdfFile(result: MethodChannel.Result) {
        val intent = Intent(Intent.ACTION_GET_CONTENT).apply {
            type = "application/pdf"
            addCategory(Intent.CATEGORY_OPENABLE)
        }
        
        val chooser = Intent.createChooser(intent, "Select PDF Lab Report")
        
        // Store result for callback
        pendingResult = result
        startActivityForResult(chooser, FILE_PICKER_REQUEST)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        
        if (requestCode == FILE_PICKER_REQUEST) {
            if (resultCode == Activity.RESULT_OK && data != null) {
                val uri = data.data
                if (uri != null) {
                    // Get file path from URI
                    val filePath = getPathFromUri(uri)
                    pendingResult?.success(filePath)
                } else {
                    pendingResult?.error("NO_FILE", "No file selected", null)
                }
            } else {
                pendingResult?.error("CANCELLED", "File selection cancelled", null)
            }
            pendingResult = null
        }
    }

    private fun getPathFromUri(uri: android.net.Uri): String? {
        return when (uri.scheme) {
            "content" -> {
                val cursor = contentResolver.query(uri, arrayOf(android.provider.MediaStore.MediaColumns.DATA), null, null, null)
                cursor?.use {
                    if (it.moveToFirst()) {
                        val index = it.getColumnIndex(android.provider.MediaStore.MediaColumns.DATA)
                        if (index >= 0) {
                            return@use it.getString(index)
                        }
                    }
                }
                // Fallback: copy to cache
                val inputStream = contentResolver.openInputStream(uri)
                val fileName = uri.lastPathSegment ?: "temp.pdf"
                val file = java.io.File(cacheDir, fileName)
                inputStream?.use { input ->
                    file.outputStream().use { output ->
                        input.copyTo(output)
                    }
                }
                file.absolutePath
            }
            "file" -> uri.path
            else -> null
        }
    }

    companion object {
        private var pendingResult: MethodChannel.Result? = null
    }
}
