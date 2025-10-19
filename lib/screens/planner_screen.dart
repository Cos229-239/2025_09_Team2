import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/planner_provider.dart';
import '../../models/task.dart';
import '../../widgets/planner/enhanced_calendar_widget.dart';
import '../../widgets/planner/planner_item_widget.dart';
import 'day_itinerary_screen.dart';

class PlannerPage extends StatefulWidget {
  const PlannerPage({super.key});

  @override
  State<PlannerPage> createState() => _PlannerPageState();
}

class _PlannerPageState extends State<PlannerPage> {
  @override
  Widget build(BuildContext context) {
    return Consumer<PlannerProvider>(
      builder: (context, provider, child) {
        final selectedDayTasks = provider.events[provider.selectedDay] ?? [];

        return Scaffold(
          appBar: AppBar(
            title: const Text('Study Planner'),
            centerTitle: true,
          ),
          body: Column(
            children: [
              EnhancedCalendarWidget(
                onDaySelected: (date, events) {
                  provider.setSelectedDay(date);
                  // Navigate to day detail view
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DayItineraryScreen(
                        selectedDate: date,
                      ),
                    ),
                  );
                },
                showFilters: false,
                showEventList: false,
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Tasks for ${DateFormat.yMMMd().format(provider.selectedDay)}',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: selectedDayTasks.length,
                  itemBuilder: (context, index) {
                    final item = selectedDayTasks[index];
                    return PlannerItemWidget(
                      item: item,
                      onDelete: () => provider.deleteTask(item.id),
                      onEdit: () =>
                          _showItemDialog(context, existingItem: item),
                      onStatusChanged: (isCompleted) =>
                          provider.updateTaskStatus(item, isCompleted),
                    );
                  },
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showItemDialog(context),
            tooltip: 'Add new task',
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  void _showItemDialog(BuildContext context, {Task? existingItem}) {
    final titleController =
        TextEditingController(text: existingItem?.title ?? '');
    final descriptionController = TextEditingController();
    final provider = Provider.of<PlannerProvider>(context, listen: false);
    DateTime selectedDate = existingItem?.dueAt ?? provider.selectedDay;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(existingItem == null ? 'Add New Task' : 'Edit Task'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Title'),
                      autofocus: true,
                    ),
                    TextField(
                      controller: descriptionController,
                      decoration:
                          const InputDecoration(labelText: 'Description'),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(DateFormat('MM/dd/yyyy').format(selectedDate)),
                        TextButton(
                          child: const Text('Select Date'),
                          onPressed: () async {
                            final pickedDate = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2101),
                            );
                            if (pickedDate != null) {
                              setDialogState(() => selectedDate = pickedDate);
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final title = titleController.text;
                    if (title.isEmpty) return;

                    if (existingItem != null) {
                      provider.updateTask(
                        existingItem.copyWith(
                          title: title,
                          dueAt: selectedDate,
                        ),
                      );
                    } else {
                      final newTask = Task(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        title: title,
                        estMinutes: 30, // Default 30 minutes
                        dueAt: selectedDate,
                      );
                      provider.addTask(newTask);
                    }

                    Navigator.pop(context);
                  },
                  child: Text(existingItem == null ? 'Add' : 'Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
