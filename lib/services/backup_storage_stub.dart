import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<bool> saveAndExportJsonFile(String jsonContent, String fileName) async {
  try {
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsString(jsonContent);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/json', name: fileName)],
      subject: 'Cadangan Data Yotro ($fileName)',
      text: 'Berkas cadangan data keuangan Yotro.',
    );
    return true;
  } catch (_) {
    return false;
  }
}

