import 'package:flutter/material.dart';
import '../data/alarm_model.dart';

class AlarmTile extends StatelessWidget {
  final AlarmModel alarm;
  final VoidCallback onTap;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final bool isOn;

  const AlarmTile({
    super.key,
    required this.alarm,
    required this.onTap,
    required this.onToggle,
    required this.onDelete,
    required this.isOn,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(alarm.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: ListTile(
        leading: Icon(
          Icons.alarm,
          color: isOn ? Colors.blueGrey : Colors.grey,
        ),
        title: Text(
          alarm.time,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isOn ? null : Colors.grey,
          ),
        ),
        subtitle: Text(
          alarm.repeatText,
          style: TextStyle(
            color: isOn ? Colors.blueGrey : Colors.grey,
          ),
        ),
        trailing: Switch(
          value: isOn,
          onChanged: (_) => onToggle(),
        ),
        onTap: onTap,
        onLongPress: () => _showDeleteConfirmation(context),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Alarm?'),
        content: Text('Delete alarm at ${alarm.time}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete();
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}