# File Structure Documentation - StudyPals

## Complete File Tree
```
studypals/
├── README.md                           # Project overview and setup
├── API_DOCUMENTATION.md               # Detailed API reference
├── ARCHITECTURE.md                    # Architecture and design patterns
├── DEVELOPMENT_GUIDE.md               # Development workflow and best practices
├── pubspec.yaml                       # Dependencies and project metadata
├── .gitignore                         # Git ignore patterns
├── analysis_options.yaml             # Dart/Flutter linting rules
│
├── lib/                               # Main application source code
│   ├── main.dart                      # Application entry point
│   ├── main_annotated.dart           # Annotated version with comments
│   │
│   ├── models/                        # Data models and business entities
│   │   ├── user.dart                  # User account and preferences
│   │   ├── task.dart                  # Study task with scheduling
│   │   ├── note.dart                  # Markdown study notes
│   │   ├── card.dart                  # Flashcard with Q&A content
│   │   ├── deck.dart                  # Flashcard deck organization
│   │   ├── review.dart                # SRS review scheduling data
│   │   └── pet.dart                   # Virtual pet progression
│   │
│   ├── providers/                     # State management (Provider pattern)
│   │   ├── app_state.dart            # Global authentication state
│   │   ├── task_provider.dart        # Task CRUD and filtering
│   │   ├── note_provider.dart        # Note management
│   │   ├── deck_provider.dart        # Flashcard deck operations
│   │   ├── pet_provider.dart         # Virtual pet interactions
│   │   └── srs_provider.dart         # Spaced repetition scheduling
│   │
│   ├── services/                      # Business logic and data access
│   │   ├── database_service.dart     # SQLite database management
│   │   ├── task_repository.dart      # Task data access layer
│   │   ├── srs_service.dart          # SM-2 algorithm implementation
│   │   └── planner_service.dart      # Auto-scheduling logic
│   │
│   ├── screens/                       # Full-screen page widgets
│   │   ├── auth/                      # Authentication flow
│   │   │   ├── auth_wrapper.dart     # Authentication state router
│   │   │   └── login_screen.dart     # Login form and validation
│   │   └── dashboard_screen.dart     # Main app with navigation
│   │
│   ├── widgets/                       # Reusable UI components
│   │   ├── common/                    # Shared widgets across features
│   │   │   ├── add_task_sheet.dart   # Modal task creation form
│   │   │   └── create_flashcard_sheet.dart # Flashcard creation modal
│   │   └── dashboard/                 # Dashboard-specific widgets
│   │       ├── pet_widget.dart       # Virtual pet display and interactions
│   │       ├── today_tasks_widget.dart # Today's task list
│   │       ├── due_cards_widget.dart # Flashcard review summary
│   │       └── quick_stats_widget.dart # Progress statistics
│   │
│   └── theme/                         # UI styling and theming
│       └── app_theme.dart            # Material 3 theme configuration
│
├── test/                              # Unit and widget tests
│   ├── models/                        # Model serialization tests
│   ├── providers/                     # State management tests
│   ├── widgets/                       # Widget behavior tests
│   └── test_helpers/                  # Testing utilities
│
├── integration_test/                  # End-to-end tests
│   └── app_test.dart                 # Full user workflow tests
│
├── web/                              # Web-specific files
│   ├── index.html                    # Web app entry point
│   ├── manifest.json                # PWA configuration
│   └── favicon.png                   # Browser icon
│
├── android/                          # Android-specific configuration
│   ├── app/
│   │   ├── build.gradle             # Android build configuration
│   │   └── src/main/
│   │       ├── AndroidManifest.xml  # Android app manifest
│   │       └── kotlin/              # Android-specific code
│   └── gradle/                       # Gradle build system
│
├── ios/                              # iOS-specific configuration
│   ├── Runner/
│   │   ├── Info.plist              # iOS app configuration
│   │   └── AppDelegate.swift       # iOS app delegate
│   └── Runner.xcodeproj/           # Xcode project files
│
├── windows/                          # Windows-specific configuration
│   ├── runner/
│   │   ├── main.cpp                # Windows entry point
│   │   └── CMakeLists.txt          # CMake build configuration
│   └── CMakeLists.txt              # Root CMake file
│
└── assets/                           # Static assets (images, fonts, etc.)
    ├── images/                       # App images and icons
    ├── fonts/                        # Custom fonts
    └── data/                         # Static data files
```

## Key File Explanations

### Core Application Files

#### `/lib/main.dart`
- **Purpose**: Application entry point and provider setup
- **Key Functions**: Database initialization, provider hierarchy, theme configuration
- **Dependencies**: All providers, database service, authentication wrapper

#### `/pubspec.yaml`
- **Purpose**: Project configuration and dependency management
- **Key Sections**: Dependencies, dev dependencies, Flutter configuration
- **Important Dependencies**: provider, sqflite, flutter_markdown, intl

### Model Layer (`/lib/models/`)

#### `user.dart`
- **Purpose**: User account data and study preferences
- **Key Fields**: id, email, name, study hours, daily limits
- **Methods**: JSON serialization, preference management

#### `task.dart`
- **Purpose**: Study task representation with scheduling
- **Key Fields**: title, estimated time, due date, priority, status
- **Methods**: Status transitions, JSON serialization

#### `review.dart`
- **Purpose**: Spaced repetition scheduling data
- **Key Fields**: card ID, due date, ease factor, interval, repetitions
- **Methods**: SM-2 algorithm implementation, grade processing

### Provider Layer (`/lib/providers/`)

#### `app_state.dart`
- **Purpose**: Global authentication and user session management
- **Key State**: isAuthenticated, currentUser
- **Methods**: login(), logout()

#### `task_provider.dart`
- **Purpose**: Task management with CRUD operations
- **Key State**: tasks list, loading state, today's tasks
- **Methods**: loadTasks(), addTask(), updateTask(), deleteTask()

#### `srs_provider.dart`
- **Purpose**: Spaced repetition system management
- **Key State**: reviews list, due reviews, statistics
- **Methods**: recordReview(), getDueCards(), getReviewStats()

### Service Layer (`/lib/services/`)

#### `database_service.dart`
- **Purpose**: SQLite database management and table creation
- **Key Functions**: Database initialization, schema creation, migrations
- **Platform Support**: Web (IndexedDB) and mobile (SQLite) compatibility

#### `task_repository.dart`
- **Purpose**: Task data access with SQL operations
- **Key Functions**: CRUD operations, query optimization, data mapping
- **Methods**: getAllTasks(), insertTask(), updateTask(), deleteTask()

### Screen Layer (`/lib/screens/`)

#### `dashboard_screen.dart`
- **Purpose**: Main application interface with navigation
- **Key Components**: Bottom navigation, page management, data loading
- **Child Widgets**: Dashboard home, planner, notes, decks, progress

#### `auth/login_screen.dart`
- **Purpose**: User authentication interface
- **Key Features**: Email/password validation, guest login, form handling
- **State Management**: Integration with AppState provider

### Widget Layer (`/lib/widgets/`)

#### `dashboard/pet_widget.dart`
- **Purpose**: Virtual pet display and interaction
- **Key Features**: Pet avatar, XP progress, mood display, feed/play buttons
- **State Integration**: PetProvider consumption

#### `common/add_task_sheet.dart`
- **Purpose**: Modal form for creating new tasks
- **Key Features**: Form validation, date picker, priority selection, tag management
- **State Integration**: TaskProvider for task creation

### Theme Layer (`/lib/theme/`)

#### `app_theme.dart`
- **Purpose**: Material 3 theme configuration
- **Key Features**: Light/dark themes, consistent styling, responsive design
- **Components**: Colors, typography, component themes

## File Relationships and Dependencies

### Data Flow Architecture
```
UI Widgets (Screens/Widgets)
    ↓ (Consumer/Provider.of)
State Management (Providers)
    ↓ (Repository calls)
Data Access (Services/Repositories)
    ↓ (SQL queries)
Database (SQLite/IndexedDB)
```

### Import Dependencies
```
main.dart
├── providers/* (all providers)
├── services/database_service.dart
├── screens/auth/auth_wrapper.dart
└── theme/app_theme.dart

Providers
├── models/* (respective models)
├── services/* (data repositories)
└── flutter/foundation.dart (ChangeNotifier)

Widgets
├── providers/* (for Consumer widgets)
├── models/* (for data display)
└── flutter/material.dart (UI components)
```

### Cross-Platform File Usage
```
Web Platform:
├── web/index.html (entry point)
├── lib/services/database_service.dart (IndexedDB)
└── pubspec.yaml (web dependencies)

Mobile Platform:
├── android/app/src/main/AndroidManifest.xml
├── ios/Runner/Info.plist
└── lib/services/database_service.dart (SQLite)

Desktop Platform:
├── windows/runner/main.cpp
├── linux/main.cc (if added)
└── macos/Runner/MainFlutterWindow.swift (if added)
```

## File Naming Conventions

### Dart Files
- **snake_case**: All Dart files use snake_case naming
- **Descriptive names**: Files clearly indicate their purpose
- **Layer prefixes**: Organized by architectural layer

### Examples
```
task_provider.dart      # Provider for task management
add_task_sheet.dart     # Widget for adding tasks
database_service.dart   # Service for database operations
task_repository.dart    # Repository for task data access
```

### Directory Structure
- **Singular names**: Directory names are singular (model, not models for consistency)
- **Feature grouping**: Related files grouped by feature/layer
- **Clear hierarchy**: Nested structure reflects dependency relationships

This file structure provides clear separation of concerns, maintainable code organization, and scalable architecture for the StudyPals application.
