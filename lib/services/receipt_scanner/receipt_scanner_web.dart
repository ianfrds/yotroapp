import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/receipt_data_model.dart';
import 'receipt_parser_service.dart';
import 'receipt_scanner_platform.dart';

class ReceiptScannerWeb implements ReceiptScannerPlatform {
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
      );

      if (file == null) return null;

      // Realistic sample receipt simulation on web preview
      final simulatedSample = '''
KOPI KENANGAN - MALL CENTRAL PARK
Jl. Letjen S. Parman No. 28, Jakarta Barat
Telp: (021) 5698-8888

TANGGAL: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}  14:32
KASIR: AHMAD (POS-01)
NO. STRUK: KK-20261106-8812

1x Kopi Kenangan Mantan (L)     24.000
1x Toast Cokelat Klasik         18.000
1x Extra Shot Espresso           6.000

SUBTOTAL                        48.000
PAJAK PB1 (10%)                  4.800
GRAND TOTAL                     52.800
TUNAI                           60.000
KEMBALIAN                        7.200

PEMBAYARAN: QRIS BCA
TERIMA KASIH ATAS KUNJUNGAN ANDA!
''';

      return ReceiptParserService.parseText(simulatedSample);
    } catch (e) {
      debugPrint('ReceiptScannerWeb error: $e');
      return null;
    }
  }
}

ReceiptScannerPlatform getScannerInstance() => ReceiptScannerWeb();

