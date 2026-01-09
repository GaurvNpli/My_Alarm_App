import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:alarm/alarm.dart';
import 'data/alarm_provider.dart';
import 'screens/homescreen.dart';
import 'screens/alarm_ring_screen.dart';
import 'services/notification_services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Alarm.init();

  debugPrint('Alarm package initialized');

  runApp(
    ChangeNotifierProvider(
      create: (_) => AlarmProvider(),
      child: const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: AlarmHandler(),
      ),
    ),
  );
}

class AlarmHandler extends StatefulWidget {
  const AlarmHandler({super.key});

  @override
  State<AlarmHandler> createState() => _AlarmHandlerState();
}

class _AlarmHandlerState extends State<AlarmHandler> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await NotificationServices.requestPermissions(context);

    if (mounted) {
      await context.read<AlarmProvider>().loadAlarms();
    }

    await context.read<AlarmProvider>().rescheduleAllAlarms();

    if (mounted) {
      await NotificationServices.showBatteryOptimizationDialog(context);
    }

    _listenToAlarms();
  }

  void _listenToAlarms() {
    debugPrint('👂 Listening for alarms...');

    Alarm.ringStream.stream.listen((alarmSettings) {
      debugPrint('🔔🔔🔔 ALARM RINGING! ID: ${alarmSettings.id}');

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider.value(
            value: context.read<AlarmProvider>(),
            child: AlarmRingScreen(alarmSettings: alarmSettings),
          ),
          fullscreenDialog: true,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return const HomeScreen();
  }
}
