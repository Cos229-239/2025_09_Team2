import 'package:flutter/material.dart';
import '../../models/task.dart';

class PlannerItemWidget extends StatelessWidget {
  final Task item;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final Function(bool) onStatusChanged;

  const PlannerItemWidget({
    super.key,
    required this.item,
    required this.onDelete,
    required this.onEdit,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Checkbox(
          value: item.status == TaskStatus.completed,
          onChanged: (bool? value) {
            if (value != null) {
              onStatusChanged(value);
            }
          },
        ),
        title: Text(
          item.title,
          style: TextStyle(
            decoration: item.status == TaskStatus.completed
                ? TextDecoration.lineThrough
                : null,
          ),
        ),
        subtitle: item.dueAt != null
            ? Text('Due: ${_formatDate(item.dueAt!)}')
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}
