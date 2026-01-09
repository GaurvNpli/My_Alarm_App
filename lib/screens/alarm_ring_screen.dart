import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:alarm/alarm.dart';
import 'package:provider/provider.dart';
import '../data/alarm_provider.dart';

class AlarmRingScreen extends StatefulWidget {
  final AlarmSettings alarmSettings;

  const AlarmRingScreen({super.key, required this.alarmSettings});

  @override
  State<AlarmRingScreen> createState() => _AlarmRingScreenState();
}

class _AlarmRingScreenState extends State<AlarmRingScreen> {
  late Map<String, dynamic> _problem;
  String? _feedback;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _generateProblem();
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _generateProblem() {
    final random = Random();

    int a = random.nextInt(16) + 5;
    int b = random.nextInt(16) + 5;

    List<String> operations = ['+', '-', '×'];
    String operation = operations[random.nextInt(3)];

    int answer;
    switch (operation) {
      case '+':
        answer = a + b;
        break;
      case '-':
        if (a < b) {
          int temp = a;
          a = b;
          b = temp;
        }
        answer = a - b;
        break;
      case '×':
        a = random.nextInt(10) + 2;
        b = random.nextInt(10) + 2;
        answer = a * b;
        break;
      default:
        answer = a + b;
    }

    Set<int> options = {answer};
    while (options.length < 4) {
      int wrong = answer + random.nextInt(11) - 5;
      if (wrong != answer && wrong > 0) {
        options.add(wrong);
      }
    }

    List<int> shuffled = options.toList()..shuffle();

    setState(() {
      _problem = {
        'question': '$a $operation $b = ?',
        'answer': answer,
        'options': shuffled,
      };
      _feedback = null;
    });
  }

  void _onAnswerSelected(int option) async {
    final provider = context.read<AlarmProvider>();

    if (option == _problem['answer']) {
      await provider.dismissAlarm(widget.alarmSettings.id);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Correct! Alarm stopped.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      HapticFeedback.heavyImpact();
      setState(() => _feedback = 'Wrong! Try again 😅');
    }
  }

  void _onSnooze() async {
    final provider = context.read<AlarmProvider>();
    await provider.snoozeAlarm(widget.alarmSettings);

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Snoozed for ${provider.snoozeMinutes} minutes'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final alarm = context.read<AlarmProvider>().getAlarmById(
      widget.alarmSettings.id,
    );
    final timeText = alarm?.time ?? 'Alarm';

    return PopScope(
      canPop: false, // Prevent back button
      child: Scaffold(
        backgroundColor: const Color(0xFF1a1a2e),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.alarm, size: 80, color: Colors.red),
                const SizedBox(height: 16),

                Text(
                  timeText,
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),

                const Text(
                  'Wake Up!',
                  style: TextStyle(fontSize: 24, color: Colors.white70),
                ),
                const SizedBox(height: 40),

                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Solve to stop alarm:',
                        style: TextStyle(fontSize: 16, color: Colors.white70),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _problem['question'],
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: (_problem['options'] as List<int>).map((option) {
                    return SizedBox(
                      width: 100,
                      height: 60,
                      child: ElevatedButton(
                        onPressed: () => _onAnswerSelected(option),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueGrey,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          '$option',
                          style: const TextStyle(fontSize: 22),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                if (_feedback != null) ...[
                  const SizedBox(height: 20),
                  Text(
                    _feedback!,
                    style: const TextStyle(color: Colors.red, fontSize: 18),
                  ),
                ],

                const Spacer(),

                OutlinedButton.icon(
                  onPressed: _onSnooze,
                  icon: const Icon(Icons.snooze, color: Colors.white70),
                  label: const Text(
                    'Snooze',
                    style: TextStyle(color: Colors.white70),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    side: const BorderSide(color: Colors.white38),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
