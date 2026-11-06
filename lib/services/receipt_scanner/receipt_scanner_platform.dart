import 'package:flutter/material.dart';
import '../../models/receipt_data_model.dart';

enum ReceiptImageSource { camera, gallery }

abstract class ReceiptScannerPlatform {
  Future<ReceiptDataModel?> scanReceipt(
    BuildContext context, {
    required ReceiptImageSource source,
  });
}

