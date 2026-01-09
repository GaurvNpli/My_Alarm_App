class AlarmModel {
  final int id;
  final String time;
  final DateTime scheduled;
  final bool isEnabled;
  final String tone;
  final String? customPath;
  final List<bool> repeatDays;
  final int snoozeMinutes;

  AlarmModel({
    required this.id,
    required this.time,
    required this.scheduled,
    this.isEnabled = true,
    this.tone = 'assets/alarm_classic.mp3',
    this.customPath,
    List<bool>? repeatDays,
    this.snoozeMinutes = 5,
  }) : repeatDays = repeatDays ?? List.filled(7, false);

  AlarmModel copyWith({
    int? id,
    String? time,
    DateTime? scheduled,
    bool? isEnabled,
    String? tone,
    String? customPath,
    List<bool>? repeatDays,
    int? snoozeMinutes,
  }) {
    return AlarmModel(
      id: id ?? this.id,
      time: time ?? this.time,
      scheduled: scheduled ?? this.scheduled,
      isEnabled: isEnabled ?? this.isEnabled,
      tone: tone ?? this.tone,
      customPath: customPath ?? this.customPath,
      repeatDays: repeatDays ?? List.from(this.repeatDays),
      snoozeMinutes: snoozeMinutes ?? this.snoozeMinutes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'time': time,
      'scheduled': scheduled.toIso8601String(),
      'isEnabled': isEnabled,
      'tone': tone,
      'customPath': customPath,
      'repeatDays': repeatDays,
      'snooze': snoozeMinutes,
    };
  }

  factory AlarmModel.fromJson(Map<String, dynamic> json) {
    return AlarmModel(
      id: json['id'] as int,
      time: json['time'] as String,
      scheduled: DateTime.parse(json['scheduled'] as String),
      isEnabled: json['isEnabled'] as bool? ?? true,
      tone: json['tone'] as String? ?? 'assets/alarm_classic.mp3',
      customPath: json['customPath'] as String?,
      repeatDays:
          (json['repeatDays'] as List<dynamic>?)
              ?.map((e) => e as bool)
              .toList() ??
          List.filled(7, false),
      snoozeMinutes: json['snooze'] as int? ?? 5,
    );
  }

  static const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  String get repeatText {
    if (!repeatDays.contains(true)) return 'Once';

    final selected = <String>[];
    for (int i = 0; i < 7; i++) {
      if (repeatDays[i]) selected.add(dayNames[i]);
    }

    if (selected.length == 7) return 'Every day';
    if (selected.length == 5 && !repeatDays[5] && !repeatDays[6])
      return 'Weekdays';
    if (selected.length == 2 && repeatDays[5] && repeatDays[6])
      return 'Weekends';
    return selected.join(', ');
  }

  DateTime getNextScheduledTime() {
    final now = DateTime.now();

    if (!repeatDays.contains(true)) {
      if (scheduled.isAfter(now)) return scheduled;
      return DateTime(
        now.year,
        now.month,
        now.day + 1,
        scheduled.hour,
        scheduled.minute,
      );
    }

    DateTime candidate = DateTime(
      now.year,
      now.month,
      now.day,
      scheduled.hour,
      scheduled.minute,
    );

    if (candidate.isBefore(now) || candidate.isAtSameMomentAs(now)) {
      candidate = candidate.add(const Duration(days: 1));
    }

    for (int i = 0; i < 7; i++) {
      final weekday = (candidate.weekday - 1) % 7; // Convert to 0=Mon format
      if (repeatDays[weekday]) {
        return candidate;
      }
      candidate = candidate.add(const Duration(days: 1));
    }

    return candidate;
  }
}
