import 'backup_storage_stub.dart'
    if (dart.library.html) 'backup_storage_web.dart' as platform_impl;

class BackupStorageService {
  static Future<bool> exportJsonFile({
    required String jsonContent,
    required String fileName,
  }) async {
    return platform_impl.saveAndExportJsonFile(jsonContent, fileName);
  }

  static void downloadApk() {
    platform_impl.triggerApkDownload();
  }
}

