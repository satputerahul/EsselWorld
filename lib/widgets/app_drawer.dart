import 'package:flutter/material.dart';
import '../screens/import_screen.dart';
import '../screens/login_screen.dart';
import '../screens/scan_log_screen.dart';
import '../services/auth_service.dart';
import '../services/device_id_service.dart';
import '../utils/app_colors.dart';

/// Left side bar (profile) shown on the scan screen.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  void _open(BuildContext context, Widget screen) {
    final nav = Navigator.of(context);
    nav.pop(); // close drawer
    nav.push(MaterialPageRoute(builder: (_) => screen));
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Do you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Logout', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      AuthService.logout();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = AuthService.currentUser ?? 'Staff';

    return Drawer(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 24, 20, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primaryDark, AppColors.primary],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 38, color: AppColors.primary),
                ),
                const SizedBox(height: 12),
                Text(
                  email,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                FutureBuilder<String>(
                  future: DeviceIdService.getDeviceId(),
                  builder: (context, snap) => Text(
                    'Device: ${snap.data ?? '...'}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.qr_code_scanner, color: AppColors.primary),
            title: const Text('Scan screen'),
            selected: true,
            selectedTileColor: AppColors.primary.withOpacity(0.08),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.upload_file),
            title: const Text('Import CSV'),
            onTap: () => _open(context, const ImportScreen()),
          ),
          ListTile(
            leading: const Icon(Icons.list_alt),
            title: const Text('Scan log'),
            onTap: () => _open(context, const ScanLogScreen()),
          ),
          const Spacer(),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.error),
            title: const Text('Logout', style: TextStyle(color: AppColors.error)),
            onTap: () => _confirmLogout(context),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}