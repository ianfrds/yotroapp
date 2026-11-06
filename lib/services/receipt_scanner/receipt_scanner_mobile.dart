import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/receipt_data_model.dart';
import 'receipt_parser_service.dart';
import 'receipt_scanner_platform.dart';

class ReceiptScannerMobile implements ReceiptScannerPlatform {
  final ImagePicker _picker = ImagePicker();

  @override
  Future<ReceiptDataModel?> scanReceipt(
    BuildContext context, {
    required ReceiptImageSource source,
  }) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source == ReceiptImageSource.camera
            ? ImageSource.camera
            : ImageSource.gallery,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      );

      if (file == null) return null;

      final inputImage = InputImage.fromFile(File(file.path));
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

      try {
        final RecognizedText recognizedText =
            await textRecognizer.processImage(inputImage);
        final rawText = recognizedText.text;
        return ReceiptParserService.parseText(rawText);
      } finally {
        await textRecognizer.close();
      }
    } catch (e) {
      debugPrint('ReceiptScannerMobile error: $e');
      return null;
    }
  }
}

ReceiptScannerPlatform getScannerInstance() => ReceiptScannerMobile();

