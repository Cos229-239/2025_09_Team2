# Development Guide - StudyPals

## Getting Started

### Prerequisites
- **Flutter SDK**: 3.35.3 or higher
- **Dart SDK**: 3.0.0 or higher
- **IDE**: VS Code with Flutter extension or Android Studio
- **Git**: For version control

### Platform-Specific Requirements

#### Web Development
- **Chrome**: Latest version for testing
- **Web Server**: For deployment testing

#### Android Development
- **Android Studio**: Latest version
- **Android SDK**: API level 21+ (Android 5.0)
- **Java**: JDK 8 or higher

#### iOS Development (macOS only)
- **Xcode**: Latest version
- **iOS Simulator**: iOS 11.0+
- **Apple Developer Account**: For device testing

#### Windows Development
- **Visual Studio 2022**: Community edition or higher
- **Windows 10**: Version 1903 or higher

## Installation & Setup

### 1. Clone and Setup
```bash
# Clone the repository
git clone <your-repo-url>
cd studypals

# Install dependencies
flutter pub get

# Verify installation
flutter doctor
```

### 2. IDE Configuration

#### VS Code Setup
Install these extensions:
- Flutter (Dart-Code.flutter)
- Dart (Dart-Code.dart-code)
- Flutter Widget Snippets
- Awesome Flutter Snippets

#### Recommended VS Code Settings
```json
{
  "dart.flutterSdkPath": "path/to/flutter",
  "dart.previewFlutterUiGuides": true,
  "dart.previewFlutterUiGuidesCustomTracking": true,
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    "source.fixAll": true
  }
}
```

## Development Workflow

### 1. Running the App
```bash
# Web development
flutter run -d chrome

# Android emulator
flutter run -d android

# iOS simulator (macOS only)
flutter run -d ios

# Windows desktop
flutter run -d windows

# List available devices
flutter devices
```

### 2. Hot Reload Workflow
- **Hot Reload (r)**: Updates UI instantly without losing state
- **Hot Restart (R)**: Restarts app but preserves navigation
- **Full Restart**: Stop and restart for major changes

### 3. Debugging
```bash
# Run with debugging
flutter run --debug

# Enable verbose logging
flutter run --verbose

# Profile performance
flutter run --profile

# Release build testing
flutter run --release
```

## Code Organization

### 1. Creating New Features

#### Model Creation
```dart
// lib/models/new_model.dart
class NewModel {
  final String id;
  final String name;
  final DateTime createdAt;

  NewModel({
    required this.id,
    required this.name,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // JSON serialization
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'createdAt': createdAt.toIso8601String(),
  };

  factory NewModel.fromJson(Map<String, dynamic> json) => NewModel(
    id: json['id'] as String,
    name: json['name'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}
```

#### Provider Creation
```dart
// lib/providers/new_provider.dart
import 'package:flutter/foundation.dart';
import 'package:studypals/models/new_model.dart';

class NewProvider extends ChangeNotifier {
  List<NewModel> _items = [];
  bool _isLoading = false;

  List<NewModel> get items => _items;
  bool get isLoading => _isLoading;

  Future<void> loadItems() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // Load from repository
      _items = await NewRepository.getAllItems();
    } catch (e) {
      // Handle error
      print('Error loading items: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void addItem(NewModel item) {
    _items.add(item);
    notifyListeners();
  }
}
```

#### Widget Creation
```dart
// lib/widgets/new_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:studypals/providers/new_provider.dart';

class NewWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<NewProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return Center(child: CircularProgressIndicator());
        }

        return ListView.builder(
          itemCount: provider.items.length,
          itemBuilder: (context, index) {
            final item = provider.items[index];
            return ListTile(
              title: Text(item.name),
              subtitle: Text(item.createdAt.toString()),
            );
          },
        );
      },
    );
  }
}
```

### 2. Adding New Screens
```dart
// lib/screens/new_screen.dart
import 'package:flutter/material.dart';
import 'package:studypals/widgets/new_widget.dart';

class NewScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('New Feature'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => _showAddDialog(context),
          ),
        ],
      ),
      body: NewWidget(),
    );
  }

  void _showAddDialog(BuildContext context) {
    // Implementation for adding new items
  }
}
```

## Testing

### 1. Unit Tests
```dart
// test/models/task_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:studypals/models/task.dart';

void main() {
  group('Task Model Tests', () {
    test('should create task from JSON', () {
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
      expect(task.estMinutes, 30);
      expect(task.status, TaskStatus.pending);
    });

    test('should convert task to JSON', () {
      final task = Task(
        id: '1',
        title: 'Test Task',
        estMinutes: 30,
        priority: 1,
        status: TaskStatus.pending,
      );

      final json = task.toJson();

      expect(json['id'], '1');
      expect(json['title'], 'Test Task');
      expect(json['estMinutes'], 30);
    });
  });
}
```

### 2. Widget Tests
```dart
// test/widgets/pet_widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:studypals/providers/pet_provider.dart';
import 'package:studypals/widgets/dashboard/pet_widget.dart';
import 'package:studypals/models/pet.dart';

void main() {
  group('PetWidget Tests', () {
    testWidgets('should display pet information', (tester) async {
      final petProvider = PetProvider();
      
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<PetProvider>.value(
            value: petProvider,
            child: Scaffold(body: PetWidget()),
          ),
        ),
      );

      expect(find.text('Level 1 CAT'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('Feed'), findsOneWidget);
      expect(find.text('Play'), findsOneWidget);
    });

    testWidgets('should handle feed button tap', (tester) async {
      final petProvider = PetProvider();
      final initialXP = petProvider.currentPet.xp;
      
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<PetProvider>.value(
            value: petProvider,
            child: Scaffold(body: PetWidget()),
          ),
        ),
      );

      await tester.tap(find.text('Feed'));
      await tester.pump();

      expect(petProvider.currentPet.xp, initialXP + 10);
    });
  });
}
```

### 3. Integration Tests
```dart
// integration_test/app_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:studypals/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App Integration Tests', () {
    testWidgets('complete user flow', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Test login flow
      expect(find.text('StudyPals'), findsOneWidget);
      await tester.tap(find.text('Continue as Guest'));
      await tester.pumpAndSettle();

      // Test dashboard
      expect(find.text('Today'), findsOneWidget);
      expect(find.byType(BottomNavigationBar), findsOneWidget);

      // Test task creation
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      
      await tester.enterText(find.byType(TextFormField).first, 'Test Task');
      await tester.tap(find.text('Add Task'));
      await tester.pumpAndSettle();

      expect(find.text('Test Task'), findsOneWidget);
    });
  });
}
```

### 4. Running Tests
```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/models/task_test.dart

# Run tests with coverage
flutter test --coverage

# Run integration tests
flutter test integration_test/app_test.dart

# Generate coverage report
genhtml coverage/lcov.info -o coverage/html
```

## Building & Deployment

### 1. Web Deployment
```bash
# Build for web
flutter build web

# Build with specific base href
flutter build web --base-href "/studypals/"

# Serve locally for testing
flutter run -d web-server --web-port 8080
```

### 2. Android Deployment
```bash
# Build APK
flutter build apk

# Build AAB (recommended for Play Store)
flutter build appbundle

# Build for specific ABI
flutter build apk --target-platform android-arm64
```

### 3. iOS Deployment
```bash
# Build for iOS
flutter build ios

# Build for release
flutter build ios --release

# Archive for App Store
xcodebuild -workspace Runner.xcworkspace -scheme Runner archive
```

### 4. Windows Deployment
```bash
# Build for Windows
flutter build windows

# Build with specific target
flutter build windows --release
```

## Performance Optimization

### 1. Build Performance
```bash
# Analyze build size
flutter build web --analyze-size

# Enable tree shaking
flutter build web --tree-shake-icons

# Profile build performance
flutter build --verbose
```

### 2. Runtime Performance
```bash
# Profile app performance
flutter run --profile

# Track widget rebuilds
flutter run --track-widget-creation

# Memory profiling
flutter run --enable-dart-profiling
```

### 3. Code Analysis
```bash
# Run linter
flutter analyze

# Format code
flutter format .

# Check for unused files
flutter clean && flutter pub get
```

## Common Development Tasks

### 1. Adding Dependencies
```bash
# Add regular dependency
flutter pub add provider

# Add dev dependency
flutter pub add --dev flutter_test

# Add specific version
flutter pub add provider:^6.0.5

# Update dependencies
flutter pub upgrade
```

### 2. Code Generation
```bash
# Generate build files (if using build_runner)
flutter packages pub run build_runner build

# Watch for changes
flutter packages pub run build_runner watch

# Clean generated files
flutter packages pub run build_runner clean
```

### 3. Internationalization
```bash
# Generate localization files
flutter gen-l10n

# Extract messages for translation
flutter packages pub run intl_translation:extract_to_arb
```

## Troubleshooting

### Common Issues

#### 1. Build Errors
```bash
# Clean project
flutter clean
flutter pub get

# Reset Flutter
flutter doctor
flutter upgrade
```

#### 2. Hot Reload Not Working
- Check for syntax errors
- Restart with `R` (hot restart)
- Stop and run again
- Check file watchers in IDE

#### 3. Provider Not Updating
- Ensure `notifyListeners()` is called
- Check Consumer is wrapping the correct widget
- Verify provider is above Consumer in widget tree

#### 4. Database Issues
- Check database path permissions
- Verify table creation SQL
- Clear app data and restart

### Debug Tools

#### 1. Flutter Inspector
- Available in VS Code and Android Studio
- Shows widget tree and properties
- Helps identify layout issues

#### 2. Performance Overlay
```dart
// Add to MaterialApp
MaterialApp(
  showPerformanceOverlay: true,
  // ... other properties
)
```

#### 3. Debug Prints
```dart
// Conditional debug prints
if (kDebugMode) {
  print('Debug information: $data');
}

// Using debugPrint for better performance
debugPrint('Debug message');
```

This guide should help you get started with developing and extending the StudyPals application!
