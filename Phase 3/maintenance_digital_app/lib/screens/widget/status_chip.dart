import 'package:flutter/material.dart';

class StatusChip extends StatelessWidget {
  final String status;
  const StatusChip({super.key, required this.status});

  Color get _color {
    switch (status) {
      case 'reported':
        return Colors.blue;
      case 'assigned':
        return Colors.indigo;
      case 'accepted':
        return Colors.purple;
      case 'in_progress':
        return Colors.orange;
      case 'completed':
        return Colors.teal;
      case 'verified':
      case 'closed':
        return Colors.green;
      case 'reopened':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String get _label {
    return status
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withOpacity(0.4)),
      ),
      child: Text(
        _label,
        style: TextStyle(
          color: _color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
