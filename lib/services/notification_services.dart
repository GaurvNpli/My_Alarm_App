import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationServices {

  static Future<void> requestPermissions(BuildContext context) async {
    debugPrint('📋 Requesting permissions...');

    final exactAlarm = await Permission.scheduleExactAlarm.request();
    final notification = await Permission.notification.request();

    debugPrint('   Exact Alarm: $exactAlarm');
    debugPrint('   Notification: $notification');

    if (Platform.isAndroid) {
      final battery = await Permission.ignoreBatteryOptimizations.request();
      debugPrint('   Battery Optimization: $battery');
    }

    if (exactAlarm.isDenied || exactAlarm.isPermanentlyDenied) {
      debugPrint('⚠️ Exact alarm permission needed!');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please enable alarm permission in settings'),
            action: SnackBarAction(
              label: 'Open',
              onPressed: () => openAppSettings(),
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  static Future<Map<String, bool>> checkPermissions() async {
    return {
      'notification': await Permission.notification.isGranted,
      'exactAlarm': await Permission.scheduleExactAlarm.isGranted,
      'batteryOptimization': await Permission.ignoreBatteryOptimizations.isGranted,
    };
  }

  static Future<void> showBatteryOptimizationDialog(BuildContext context) async {
    final status = await Permission.ignoreBatteryOptimizations.status;

    if (status.isGranted) return;

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Battery Optimization'),
          content: const Text(
            'To ensure alarms work reliably, please disable battery optimization for this app.\n\n'
            'This prevents Android from killing the app in the background.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Later'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                Permission.ignoreBatteryOptimizations.request();
              },
              child: const Text('Disable'),
            ),
          ],
        ),
      );
    }
  }
}