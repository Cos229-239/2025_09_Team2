# StudyPals - AI-Powered Study Companion

I, Yasmani Acosta, also known as the solo coder, have created a comprehensive Flutter application that combines task management, spaced repetition flashcards, and a virtual pet system to gamify the learning experience with the help of my genius collegues!

## 🚀 Features

### Core Functionality
- **Task Management**: Create, organize, and track study tasks with priority levels
- **Spaced Repetition System (SRS)**: Intelligent flashcard review using SM-2 algorithm
- **Virtual Pet System**: Gamified learning with XP, levels, and pet moods
- **Study Streaks**: Track consecutive study days for motivation
- **Multi-Platform**: Runs on Web, Android, iOS, Windows, and macOS

### User Interface
- **Material 3 Design**: Modern, responsive UI with light/dark theme support
- **Dashboard**: Centralized view of today's tasks, due cards, and progress
- **Navigation**: Bottom navigation bar with 5 main sections
- **Interactive Widgets**: Pet feeding, task completion, and quick stats

## 🏗️ Architecture

### Design Pattern
- **Provider Pattern**: State management using ChangeNotifier
- **Repository Pattern**: Data access abstraction layer
- **Model-View-Provider (MVP)**: Clean separation of concerns

### Project Structure
```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   ├── user.dart
│   ├── task.dart
│   ├── note.dart
│   ├── card.dart
│   ├── deck.dart
│   ├── review.dart
│   └── pet.dart
├── providers/                # State management
│   ├── app_state.dart
│   ├── task_provider.dart
│   ├── note_provider.dart
│   ├── deck_provider.dart
│   ├── pet_provider.dart
│   └── srs_provider.dart
├── services/                 # Business logic
│   ├── database_service.dart
│   └── task_repository.dart
├── screens/                  # UI screens
│   ├── auth/
│   │   ├── auth_wrapper.dart
│   │   └── login_screen.dart
│   └── dashboard_screen.dart
├── widgets/                  # Reusable components
│   ├── common/
│   │   └── add_task_sheet.dart
│   └── dashboard/
│       ├── pet_widget.dart
│       ├── today_tasks_widget.dart
│       ├── due_cards_widget.dart
│       └── quick_stats_widget.dart
└── theme/
    └── app_theme.dart        # UI theming
```

## 📊 Database Schema

### Tables
- **users**: User profiles and preferences
- **tasks**: Study tasks with priorities and deadlines
- **notes**: Markdown-formatted study notes
- **decks**: Flashcard deck organization
- **cards**: Individual flashcards with front/back content
- **reviews**: SRS review history and scheduling
- **schedule_blocks**: Planned study sessions
- **pets**: Virtual pet progress and state
- **streaks**: Study streak tracking

## 🔧 Technical Stack

### Dependencies
```yaml
flutter: SDK framework
provider: ^6.0.5 (State management)
sqflite: ^2.3.0 (Local database)
sqflite_common_ffi_web: ^0.4.2+1 (Web database support)
flutter_markdown: ^0.6.18 (Markdown rendering)
intl: ^0.18.1 (Internationalization)
fl_chart: ^0.66.0 (Data visualization)
```

### Key Technologies
- **Flutter 3.35.3**: Cross-platform UI framework
- **SQLite**: Local data persistence
- **Material 3**: Google's latest design system
- **Provider**: Reactive state management
- **Web FFI**: Web database compatibility

## 🎮 Gaming Elements

### Virtual Pet System
- **5 Species**: Cat, Dog, Dragon, Owl, Fox
- **4 Mood States**: Sleepy, Content, Happy, Excited
- **XP System**: Gain experience through study activities
- **Level Progression**: Pet grows stronger with consistent study

### Gamification Features
- **Study Streaks**: Daily study habit tracking
- **Task Completion**: XP rewards for finishing tasks
- **Review Performance**: SRS algorithm adapts to user success
- **Progress Visualization**: Charts and statistics

## 🧠 Spaced Repetition System

### SM-2 Algorithm Implementation
- **Ease Factor**: Adjusts based on review performance (1.3-2.5)
- **Interval Calculation**: Determines next review date
- **Grade System**: 4-point scale (Again, Hard, Good, Easy)
- **Retention Optimization**: Maximizes long-term memory retention

### Review Grades
- **Again**: Restart learning (10 minutes)
- **Hard**: Reduce ease, shorter interval
- **Good**: Standard progression
- **Easy**: Increase ease, longer interval

## 🔄 State Management Flow

### Provider Hierarchy
```
StudyPalsApp
├── AppState (Authentication)
├── TaskProvider (Task CRUD)
├── NoteProvider (Note management)
├── DeckProvider (Flashcard decks)
├── PetProvider (Virtual pet state)
└── SRSProvider (Review scheduling)
```

### Data Flow
1. User interaction triggers widget event
2. Widget calls provider method
3. Provider updates database via repository
4. Provider notifies UI of state changes
5. UI rebuilds with new data

## 🎨 UI Components

### Dashboard Widgets
- **PetWidget**: Interactive pet display with feeding/playing
- **TodayTasksWidget**: Task list with completion checkboxes
- **DueCardsWidget**: Flashcard review countdown
- **QuickStatsWidget**: Study progress overview

### Common Components
- **AddTaskSheet**: Modal bottom sheet for task creation
- **Priority Indicators**: Color-coded task importance
- **Progress Bars**: XP and completion tracking

## 🔐 Authentication System

### Login Flow
1. Email/password validation
2. Guest login option
3. User state persistence
4. Auto-redirect to dashboard

### User Model
- **ID**: Unique identifier
- **Email**: Authentication credential
- **Name**: Display name
- **Preferences**: Study settings and limits

## 📱 Cross-Platform Support

### Platforms
- **Web**: PWA-ready with IndexedDB storage
- **Android**: Native performance with Material Design
- **iOS**: Cupertino design adaptation
- **Windows**: Desktop-optimized layouts
- **macOS**: Native menu integration

### Platform-Specific Features
- **Web**: Browser notification support
- **Mobile**: Push notifications and background sync
- **Desktop**: System tray integration and keyboard shortcuts

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.35.3+
- Dart SDK 3.0.0+
- Platform-specific development tools

### Installation
```bash
# Clone the project
git clone <repository-url>
cd studypals

# Install dependencies
flutter pub get

# Run on web
flutter run -d chrome

# Run on mobile
flutter run
```

### Development Setup
```bash
# Generate build files
flutter packages pub run build_runner build

# Run tests
flutter test

# Build for production
flutter build web
flutter build apk
flutter build windows
```

## 📊 Performance Optimizations

### Database
- **Indexed queries**: Fast task and review lookups
- **Connection pooling**: Efficient database access
- **Lazy loading**: Load data on demand

### UI
- **Provider scoping**: Minimize unnecessary rebuilds
- **Widget keys**: Preserve state during rebuilds
- **Image caching**: Optimize asset loading

### Memory Management
- **Dispose controllers**: Prevent memory leaks
- **Stream subscriptions**: Proper cleanup
- **Provider cleanup**: Resource management

## 🧪 Testing Strategy

### Unit Tests
- Model serialization/deserialization
- Business logic validation
- SRS algorithm correctness

### Widget Tests
- UI component behavior
- User interaction flows
- State management integration

### Integration Tests
- End-to-end user workflows
- Database operations
- Cross-platform compatibility

## 🔮 Future Enhancements

### Planned Features
- **Cloud Sync**: Multi-device synchronization
- **AI Integration**: Smart content generation
- **Social Features**: Study groups and leaderboards
- **Advanced Analytics**: Learning pattern analysis
- **Offline Mode**: Full functionality without internet

### Technical Improvements
- **Performance**: Lazy loading and virtual scrolling
- **Security**: End-to-end encryption
- **Accessibility**: Screen reader support and high contrast
- **Internationalization**: Multi-language support

## 📄 License

This project is licensed under the Full Sail University Academic License - see the [LICENSE](LICENSE) file for details.

**Academic Project**: This software is developed as part of an academic project at Full Sail University for educational purposes.

## 🎓 Academic Information

- **Institution**: Full Sail University
- **Project**: StudyPals - AI-Powered Study Companion  
- **Course**: Software Development
- **Team**: Cos229-239/2025_09_Team2
- **Year**: 2025

## 🤝 Contributing

This is an academic project. For educational collaboration and questions, please follow Full Sail University's academic policies.

## 📞 Support

For questions and support, please open an issue on the project repository.
