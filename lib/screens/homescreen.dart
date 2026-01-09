import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../data/alarm_provider.dart';
import '../widgets/alarm_tile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Alarm Clock'),
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.stop),
            tooltip: 'Stop Alarm',
            onPressed: () {
              context.read<AlarmProvider>().stopAllAlarms();
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Alarm stopped!')));
            },
          ),
        ],
      ),
      body: Consumer<AlarmProvider>(
        builder: (context, provider, child) {
          if (provider.alarms.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.alarm_off, size: 64, color: Colors.grey),
                  SizedBox(height: 8),
                  Text('No alarms yet', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: provider.alarms.length,
            itemBuilder: (_, i) {
              final alarm = provider.alarms[i];
              return AlarmTile(
                alarm: alarm,
                isOn: alarm.isEnabled,
                onTap: () => _showAlarmDialog(index: i),
                onToggle: () => provider.toggleAlarm(i, !alarm.isEnabled),
                onDelete: () {
                  provider.deleteAlarm(i);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Alarm deleted!')),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAlarmDialog(),
        backgroundColor: Colors.blueGrey,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Future<void> _showAlarmDialog({int? index}) async {
    final provider = context.read<AlarmProvider>();

    if (index != null) {
      provider.loadEditingState(provider.alarms[index]);
    } else {
      provider.resetEditingState();
    }

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return;

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (_, setDialogState) {
          String toneDisplay = provider.customSongPath != null
              ? provider.customSongPath!.split('/').last
              : provider.builtInTones.firstWhere(
                      (t) => t['path'] == provider.selectedTone,
                      orElse: () => {'name': 'Classic'},
                    )['name']
                    as String;

          return AlertDialog(
            title: Text(index == null ? 'New Alarm' : 'Edit Alarm'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    time.format(context),
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

                  ListTile(
                    leading: const Icon(Icons.music_note),
                    title: const Text('Tone'),
                    subtitle: Text(toneDisplay),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _pickTone(setDialogState, provider),
                  ),
                  const SizedBox(height: 8),

                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Repeat',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(
                      7,
                      (i) => GestureDetector(
                        onTap: () => setDialogState(() {
                          provider.repeatDays[i] = !provider.repeatDays[i];
                        }),
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: provider.repeatDays[i]
                              ? Colors.blueGrey
                              : Colors.grey[300],
                          child: Text(
                            dayNames[i][0],
                            style: TextStyle(
                              color: provider.repeatDays[i]
                                  ? Colors.white
                                  : Colors.black,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  ListTile(
                    leading: const Icon(Icons.snooze),
                    title: const Text('Snooze'),
                    subtitle: Text('${provider.snoozeMinutes} minutes'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      final result = await showDialog<int>(
                        context: context,
                        builder: (_) => SimpleDialog(
                          title: const Text('Snooze Duration'),
                          children: [5, 10, 15, 20, 30]
                              .map(
                                (m) => SimpleDialogOption(
                                  onPressed: () => Navigator.pop(context, m),
                                  child: Text('$m minutes'),
                                ),
                              )
                              .toList(),
                        ),
                      );
                      if (result != null) {
                        setDialogState(() => provider.snoozeMinutes = result);
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  if (index != null) {
                    await provider.updateAlarm(index, time, context);
                  } else {
                    await provider.addAlarm(time, context);
                  }

                  if (!context.mounted) return;
                  Navigator.pop(dialogContext);

                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Alarm set for ${time.format(context)}'),
                    ),
                  );
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }


  Future<void> _pickTone(
    StateSetter setDialogState,
    AlarmProvider provider,
  ) async {
    await showModalBottomSheet(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Choose Alarm Tone',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ...provider.builtInTones.map(
            (tone) => ListTile(
              leading: Icon(tone['icon'] as IconData, color: Colors.blueGrey),
              title: Text(tone['name'] as String),
              trailing:
                  provider.selectedTone == tone['path'] &&
                      provider.customSongPath == null
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : null,
              onTap: () {
                setDialogState(() {
                  provider.selectedTone = tone['path'] as String;
                  provider.customSongPath = null;
                });
                Navigator.pop(context);
              },
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.folder_open, color: Colors.purple),
            title: const Text('Choose from Files'),
            subtitle: provider.customSongPath != null
                ? Text(
                    provider.customSongPath!.split('/').last,
                    overflow: TextOverflow.ellipsis,
                  )
                : null,
            trailing: provider.customSongPath != null
                ? const Icon(Icons.check_circle, color: Colors.green)
                : null,
            onTap: () async {
              Navigator.pop(context);
              final result = await FilePicker.platform.pickFiles(
                type: FileType.audio,
              );
              if (result != null) {
                setDialogState(() {
                  provider.customSongPath = result.files.single.path;
                  provider.selectedTone = 'custom';
                });
              }
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
