import 'package:permission_handler/permission_handler.dart';

class CameraPermissionService {
  static Future<PermissionStatus> checkStatus() async {
    return Permission.camera.status;
  }

  static Future<PermissionStatus> requestPermission() async {
    final current = await Permission.camera.status;
    if (current.isGranted) return current;
    return Permission.camera.request();
  }

  static Future<void> openSettings() async {
    await openAppSettings();
  }
}