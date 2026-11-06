import 'package:flutter/material.dart';

import '../../models/receipt_data_model.dart';
import 'receipt_scanner_platform.dart';
import 'receipt_scanner_stub.dart'
    if (dart.library.io) 'receipt_scanner_mobile.dart'
    if (dart.library.html) 'receipt_scanner_web.dart' as platform_impl;

export 'receipt_parser_service.dart';
export 'receipt_scanner_platform.dart';

class ReceiptScannerService {
  static final ReceiptScannerPlatform _scanner = platform_impl.getScannerInstance();

  static Future<ReceiptDataModel?> scanReceipt(
    BuildContext context, {
    required ReceiptImageSource source,
  }) async {
    return _scanner.scanReceipt(context, source: source);
  }
}

