# Code Architecture Guide - StudyPals

## Overview
This document provides detailed explanations of the architectural decisions, design patterns, and implementation details for the StudyPals Flutter application.

## Table of Contents
1. [Architectural Patterns](#architectural-patterns)
2. [State Management](#state-management)
3. [Data Flow](#data-flow)
4. [File Organization](#file-organization)
5. [Design Principles](#design-principles)
6. [Performance Considerations](#performance-considerations)

## Architectural Patterns

### 1. Provider Pattern (State Management)
**Why Chosen:** Simple, Flutter-native, and perfect for medium-complexity apps.

```dart
// Provider hierarchy in main.dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => AppState()),
    ChangeNotifierProvider(create: (_) => TaskProvider()),
    ChangeNotifierProvider(create: (_) => DeckProvider()),
    // ... other providers
  ],
  child: MaterialApp(...)
)
```

**Benefits:**
- Reactive UI updates
- Minimal boilerplate
- Easy testing
- Built-in to Flutter ecosystem

### 2. Repository Pattern (Data Access)
**Why Chosen:** Abstracts database operations and enables easy testing.

```dart
// Repository interface
class TaskRepository {
  static Future<List<Task>> getAllTasks() async {
    final db = await DatabaseService.database;
    final results = await db.query('tasks');
    return results.map((json) => Task.fromJson(json)).toList();
  }
}
```

**Benefits:**
- Separation of concerns
- Testable data layer
- Database abstraction
- Easy to mock for testing

### 3. Model-View-Provider (MVP)
**Structure:**
- **Models**: Data classes with serialization
- **Views**: UI widgets and screens
- **Providers**: Business logic and state management

## State Management

### Provider Lifecycle
```dart
class TaskProvider extends ChangeNotifier {
  List<Task> _tasks = [];
  bool _isLoading = false;

  // Getter for UI consumption
  List<Task> get tasks => _tasks;
  
  // Async operation with loading state
  Future<void> loadTasks() async {
    _isLoading = true;
    notifyListeners(); // Trigger UI update
    
    try {
      _tasks = await TaskRepository.getAllTasks();
    } catch (e) {
      // Handle error
    } finally {
      _isLoading = false;
      notifyListeners(); // Final UI update
    }
  }
}
```

### Consumer Widgets
```dart
// Efficient consumption of specific provider data
Consumer<TaskProvider>(
  builder: (context, taskProvider, child) {
    if (taskProvider.isLoading) {
      return CircularProgressIndicator();
    }
    return ListView.builder(
      itemCount: taskProvider.tasks.length,
      itemBuilder: (context, index) => TaskTile(taskProvider.tasks[index]),
    );
  },
)
```

## Data Flow

### 1. User Interaction → Provider → Database → UI Update
```
User taps "Add Task" button
    ↓
AddTaskSheet shows with form
    ↓
User fills form and submits
    ↓
TaskProvider.addTask() called
    ↓
TaskRepository.insertTask() saves to DB
    ↓
Provider updates local state (_tasks)
    ↓
notifyListeners() triggers UI rebuild
    ↓
Consumer rebuilds with new task list
```

### 2. Database Initialization Flow
```dart
// main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseService.initialize(); // Platform-specific setup
  runApp(StudyPalsApp());
}

// database_service.dart
static Future<void> initialize() async {
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb; // Web compatibility
  }
  // Mobile uses default SQLite
}
```

## File Organization

### 1. Feature-Based Structure
```
lib/
├── models/          # Data models
├── providers/       # State management
├── services/        # Business logic
├── screens/         # Full-screen pages
├── widgets/         # Reusable components
└── theme/          # UI styling
```

### 2. Widget Hierarchy
```
StudyPalsApp (MaterialApp)
├── AuthWrapper (Authentication logic)
│   ├── LoginScreen (Unauthenticated)
│   └── DashboardScreen (Authenticated)
│       ├── DashboardHome
│       │   ├── PetWidget
│       │   ├── TodayTasksWidget
│       │   ├── DueCardsWidget
│       │   └── QuickStatsWidget
│       ├── PlannerScreen
│       ├── NotesScreen
│       ├── DecksScreen
│       └── ProgressScreen
```

## Design Principles

### 1. Single Responsibility Principle
Each class has one reason to change:
- **Models**: Data representation and serialization
- **Providers**: State management for specific domain
- **Repositories**: Data access for specific entity
- **Widgets**: UI rendering for specific component

### 2. Dependency Inversion
High-level modules don't depend on low-level modules:
```dart
// Provider depends on Repository interface, not concrete database
class TaskProvider {
  Future<void> loadTasks() async {
    _tasks = await TaskRepository.getAllTasks(); // Abstracted
  }
}
```

### 3. Open/Closed Principle
Code is open for extension, closed for modification:
```dart
// Easy to add new pet species without changing existing code
enum PetSpecies { cat, dog, dragon, owl, fox }

// New mood states can be added without breaking existing logic
enum PetMood { sleepy, content, happy, excited }
```

## Performance Considerations

### 1. Widget Rebuilding Optimization
```dart
// Use Consumer for specific data instead of Provider.of
Consumer<TaskProvider>( // Only rebuilds when TaskProvider changes
  builder: (context, taskProvider, child) => TaskList(),
)

// Use const constructors to prevent unnecessary rebuilds
class TaskTile extends StatelessWidget {
  const TaskTile({Key? key, required this.task}) : super(key: key);
  final Task task;
}
```

### 2. Database Query Optimization
```dart
// Use indexes for frequently queried columns
// Order by clauses for sorted results
Future<List<Task>> getAllTasks() async {
  final results = await db.query(
    'tasks', 
    orderBy: 'due_at ASC', // Efficient sorting
    where: 'status != ?',   // Filtered queries
    whereArgs: ['completed']
  );
}
```

### 3. Memory Management
```dart
// Dispose controllers in StatefulWidget
@override
void dispose() {
  _titleController.dispose();
  _minutesController.dispose();
  super.dispose();
}

// Use keys for list items to preserve state
ListView.builder(
  itemBuilder: (context, index) => TaskTile(
    key: ValueKey(tasks[index].id), // Stable key
    task: tasks[index],
  ),
)
```

### 4. Lazy Loading Strategy
```dart
// Load data only when needed
@override
void initState() {
  super.initState();
  // Use post-frame callback to avoid setState during build
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _loadData();
  });
}
```

## Error Handling Strategy

### 1. Provider Error Handling
```dart
class TaskProvider extends ChangeNotifier {
  String? _errorMessage;
  String? get errorMessage => _errorMessage;
  
  Future<void> addTask(Task task) async {
    try {
      await TaskRepository.insertTask(task);
      _tasks.add(task);
      _errorMessage = null; // Clear previous errors
    } catch (e) {
      _errorMessage = 'Failed to add task: $e';
    } finally {
      notifyListeners();
    }
  }
}
```

### 2. UI Error Display
```dart
Consumer<TaskProvider>(
  builder: (context, provider, child) {
    if (provider.errorMessage != null) {
      // Show error message
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.errorMessage!)),
        );
      });
    }
    return TaskList();
  },
)
```

## Testing Architecture

### 1. Unit Tests for Models
```dart
test('Task.fromJson creates correct object', () {
  final json = {
    'id': '1',
    'title': 'Test Task',
    'estMinutes': 30,
    'priority': 1,
    'status': 'TaskStatus.pending',
  };
  
  final task = Task.fromJson(json);
  
  expect(task.id, '1');
  expect(task.title, 'Test Task');
  expect(task.status, TaskStatus.pending);
});
```

### 2. Provider Tests with Mocks
```dart
class MockTaskRepository extends Mock implements TaskRepository {}

void main() {
  group('TaskProvider Tests', () {
    late TaskProvider provider;
    late MockTaskRepository mockRepository;
    
    setUp(() {
      mockRepository = MockTaskRepository();
      provider = TaskProvider();
    });
    
    test('loadTasks updates task list', () async {
      when(mockRepository.getAllTasks())
          .thenAnswer((_) async => [testTask]);
      
      await provider.loadTasks();
      
      expect(provider.tasks, hasLength(1));
      expect(provider.tasks.first.id, testTask.id);
    });
  });
}
```

### 3. Widget Tests
```dart
testWidgets('TaskTile displays task information', (tester) async {
  final task = Task(
    id: '1',
    title: 'Test Task',
    estMinutes: 30,
    priority: 1,
    status: TaskStatus.pending,
  );
  
  await tester.pumpWidget(
    MaterialApp(home: TaskTile(task: task)),
  );
  
  expect(find.text('Test Task'), findsOneWidget);
  expect(find.text('30 min'), findsOneWidget);
});
```

## Security Considerations

### 1. SQL Injection Prevention
```dart
// Use parameterized queries
await db.query(
  'tasks',
  where: 'id = ?',        // Parameterized
  whereArgs: [taskId],    // Safe value binding
);
```

### 2. Input Validation
```dart
// Validate all user inputs
String? validateTaskTitle(String? value) {
  if (value == null || value.isEmpty) {
    return 'Please enter a title';
  }
  if (value.length > 100) {
    return 'Title too long';
  }
  return null;
}
```

This architecture provides a solid foundation for a maintainable, scalable, and performant Flutter application.
