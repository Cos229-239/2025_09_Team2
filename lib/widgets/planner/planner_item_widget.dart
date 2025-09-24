import 'package:flutter/material.dart';
import '../../models/task.dart';

// TODO: Planner Item Widget - Missing Interactive Features
// - No drag-and-drop reordering functionality
// - Missing priority visual indicators beyond text
// - No swipe actions for quick operations
// - Missing task progress indicators for multi-step tasks
// - No integration with time tracking
// - Missing attachment indicators (files, notes, links)
// - No collaboration indicators (shared tasks, assignees)
// - Missing contextual actions based on task type
// - No smart suggestions or recommendations
// - Missing accessibility improvements (screen reader support)
// - No animation feedback for user interactions
// - Missing bulk selection and operations

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
