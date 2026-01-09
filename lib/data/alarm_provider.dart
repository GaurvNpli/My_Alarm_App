import 'package:flutter/material.dart';
import 'package:alarm/alarm.dart';
import 'alarm_model.dart';
import 'alarm_repository.dart';

class AlarmProvider extends ChangeNotifier {
  final AlarmRepository _repository = AlarmRepository();

  List<AlarmModel> _alarms = [];
  List<AlarmModel> get alarms => _alarms;

  String selectedTone = 'assets/alarm_classic.mp3';
  String? customSongPath;
  List<bool> repeatDays = List.filled(7, false);
  int snoozeMinutes = 5;

  final builtInTones = [
    {
      'name': 'Classic',
      'path': 'assets/alarm_classic.mp3',
      'icon': Icons.alarm,
    },
    {'name': 'Gentle', 'path': 'assets/alarm_gentle.mp3', 'icon': Icons.waves},
    {
      'name': 'Digital',
      'path': 'assets/alarm_digital.mp3',
      'icon': Icons.phone_android,
    },
  ];

  Future<void> loadAlarms() async {
    _alarms = await _repository.loadAlarms();
    debugPrint('📂 Loaded ${_alarms.length} alarms');
    notifyListeners();
  }

  void resetEditingState() {
    selectedTone = 'assets/alarm_classic.mp3';
    customSongPath = null;
    repeatDays = List.filled(7, false);
    snoozeMinutes = 5;
  }

  void loadEditingState(AlarmModel alarm) {
    selectedTone = alarm.tone;
    customSongPath = alarm.customPath;
    repeatDays = List.from(alarm.repeatDays);
    snoozeMinutes = alarm.snoozeMinutes;
  }

  Future<void> addAlarm(TimeOfDay time, BuildContext context) async {
    final now = DateTime.now();
    var scheduled = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    final alarm = AlarmModel(
      id: _repository.generateId(),
      time: time.format(context),
      scheduled: scheduled,
      isEnabled: true,
      tone: selectedTone,
      customPath: customSongPath,
      repeatDays: List.from(repeatDays),
      snoozeMinutes: snoozeMinutes,
    );

    _alarms.add(alarm);
    await _scheduleAlarm(alarm);
    await _repository.saveAlarms(_alarms);
    notifyListeners();

    debugPrint('✅ Added alarm ID: ${alarm.id}');
  }

  Future<void> updateAlarm(
    int index,
    TimeOfDay time,
    BuildContext context,
  ) async {
    final existingAlarm = _alarms[index];
    final formattedTime = time.format(context); // Format before async

    // Cancel the old schedule first
    await Alarm.stop(existingAlarm.id);
    debugPrint('🛑 Cancelled old alarm ID: ${existingAlarm.id}');

    final now = DateTime.now();
    var scheduled = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    final updatedAlarm = existingAlarm.copyWith(
      time: formattedTime,
      scheduled: scheduled,
      isEnabled: true,
      tone: selectedTone,
      customPath: customSongPath,
      repeatDays: List.from(repeatDays),
      snoozeMinutes: snoozeMinutes,
    );

    _alarms[index] = updatedAlarm;
    await _scheduleAlarm(updatedAlarm);
    await _repository.saveAlarms(_alarms);
    notifyListeners();

    debugPrint('✅ Updated alarm ID: ${updatedAlarm.id} (same ID kept)');
  }

  Future<void> toggleAlarm(int index, bool enabled) async {
    final alarm = _alarms[index];
    _alarms[index] = alarm.copyWith(isEnabled: enabled);

    if (enabled) {
      await _scheduleAlarm(_alarms[index]);
    } else {
      await Alarm.stop(alarm.id);
      debugPrint('🛑 Alarm ${alarm.id} disabled');
    }

    await _repository.saveAlarms(_alarms);
    notifyListeners();
  }

  Future<void> deleteAlarm(int index) async {
    final alarm = _alarms[index];
    await Alarm.stop(alarm.id);
    _alarms.removeAt(index);
    await _repository.saveAlarms(_alarms);
    notifyListeners();
    debugPrint('🗑️ Deleted alarm ID: ${alarm.id}');
  }

  Future<void> snoozeAlarm(AlarmSettings alarmSettings) async {
    await Alarm.stop(alarmSettings.id);

    final snoozeTime = DateTime.now().add(Duration(minutes: snoozeMinutes));
    await Alarm.set(
      alarmSettings: alarmSettings.copyWith(dateTime: snoozeTime),
    );

    debugPrint(
      '😴 Snoozed alarm ${alarmSettings.id} for $snoozeMinutes minutes',
    );
  }

  Future<void> dismissAlarm(int id) async {
    await Alarm.stop(id);

    final index = _alarms.indexWhere((a) => a.id == id);
    if (index != -1) {
      final alarm = _alarms[index];
      if (alarm.repeatDays.contains(true)) {
        // Reschedule for next occurrence
        final nextTime = alarm.getNextScheduledTime();
        final updatedAlarm = alarm.copyWith(scheduled: nextTime);
        _alarms[index] = updatedAlarm;
        await _scheduleAlarm(updatedAlarm);
        await _repository.saveAlarms(_alarms);
        notifyListeners();
        debugPrint('🔄 Rescheduled repeating alarm for $nextTime');
      }
    }

    debugPrint('✅ Dismissed alarm $id');
  }

  Future<void> stopAllAlarms() async {
    final activeAlarms = await Alarm.getAlarms();
    debugPrint('🛑 Stopping ${activeAlarms.length} alarms');

    for (var alarm in activeAlarms) {
      await Alarm.stop(alarm.id);
    }
  }

  
  Future<void> rescheduleAllAlarms() async {
    final enabledAlarms = await _repository.getEnabledAlarms();
    debugPrint('🔄 Rescheduling ${enabledAlarms.length} alarms after reboot');

    for (final alarm in enabledAlarms) {
      final nextTime = alarm.getNextScheduledTime();
      if (nextTime.isAfter(DateTime.now())) {
        final updatedAlarm = alarm.copyWith(scheduled: nextTime);
        await _scheduleAlarm(updatedAlarm);
      }
    }
  }

  AlarmModel? getAlarmById(int id) {
    try {
      return _alarms.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> _scheduleAlarm(AlarmModel alarm) async {
    debugPrint('🔔 Scheduling alarm:');
    debugPrint('   ID: ${alarm.id}');
    debugPrint('   Time: ${alarm.scheduled}');
    debugPrint('   Tone: ${alarm.tone}');

    final alarmSettings = AlarmSettings(
      id: alarm.id,
      dateTime: alarm.scheduled,
      assetAudioPath: alarm.tone == 'custom'
          ? 'assets/alarm_classic.mp3'
          : alarm.tone,
      loopAudio: true,
      vibrate: true,
      warningNotificationOnKill: true,
      androidFullScreenIntent: true, // FIX #3
      notificationSettings: const NotificationSettings(
        title: '⏰ Alarm',
        body: 'Tap to stop',
        stopButton: 'Stop',
      ),
    );

    final result = await Alarm.set(alarmSettings: alarmSettings);
    debugPrint('   ✅ Alarm set: $result');

    final allAlarms = await Alarm.getAlarms();
    debugPrint('   📋 Total scheduled: ${allAlarms.length}');
  }
}
