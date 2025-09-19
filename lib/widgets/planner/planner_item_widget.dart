import 'package:flutter/material.dart';
import '../../../models/planner/task.dart';

class PlannerItemWidget extends StatelessWidget {
  final Task item;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final Function(bool) onStatusChanged;

  const PlannerItemWidget({
    required this.item,
    required this.onDelete,
    required this.onEdit,
    required this.onStatusChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Checkbox(
          value: item.isCompleted,
          onChanged: (value) => onStatusChanged(value ?? false),
        ),
        title: Text(
          item.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            decoration: item.isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
            color: item.isCompleted ? Colors.grey : null,
          ),
        ),
        subtitle: item.description.isNotEmpty ? Text(item.description) : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blueGrey),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}