import 'dart:convert';
import 'dart:html' as html;

Future<bool> saveAndExportJsonFile(String jsonContent, String fileName) async {
  try {
    final bytes = utf8.encode(jsonContent);
    final blob = html.Blob([bytes], 'application/json');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..click();
    html.Url.revokeObjectUrl(url);
    return true;
  } catch (_) {
    return false;
  }
}

void triggerApkDownload() {
  try {
    final anchor = html.AnchorElement(href: 'yotro-app.apk')
      ..setAttribute('download', 'yotro-app.apk')
      ..click();
  } catch (_) {}
}

