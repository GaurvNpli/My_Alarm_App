import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'alarm_model.dart';

class AlarmRepository {
  static const String _alarmsKey = 'alarms';

  Future<List<AlarmModel>> loadAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_alarmsKey);

    if (data == null || data.isEmpty) return [];

    try {
      final List<dynamic> jsonList = json.decode(data);
      return jsonList
          .map((j) => AlarmModel.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error loading alarms: $e');
      return [];
    }
  }

  Future<void> saveAlarms(List<AlarmModel> alarms) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = alarms.map((a) => a.toJson()).toList();
    await prefs.setString(_alarmsKey, json.encode(jsonList));
  }

  Future<List<AlarmModel>> getEnabledAlarms() async {
    final alarms = await loadAlarms();
    return alarms.where((a) => a.isEnabled).toList();
  }

  int generateId() {
    return DateTime.now().millisecondsSinceEpoch ~/ 1000;
  }
}
