# API Documentation - StudyPals

## Table of Contents
- [Models](#models)
- [Providers](#providers)
- [Services](#services)
- [Widgets](#widgets)
- [Database Schema](#database-schema)

## Models

### User
Represents a user in the system with preferences and authentication data.

```dart
class User {
  final String id;           // Unique identifier
  final String email;        // Authentication email
  final String name;         // Display name
  final DateTime createdAt;  // Account creation timestamp
  final UserPreferences preferences; // Study preferences
}

class UserPreferences {
  final int studyStartHour;    // Preferred study start time (0-23)
  final int studyEndHour;      // Preferred study end time (0-23) 
  final int maxCardsPerDay;    // Daily flashcard limit
  final int maxMinutesPerDay;  // Daily study time limit
}
```

### Task
Represents a study task with priority, scheduling, and completion tracking.

```dart
class Task {
  final String id;                // Unique identifier
  final String title;             // Task description
  final int estMinutes;           // Estimated completion time
  final DateTime? dueAt;          // Optional deadline
  final int priority;             // 1=Low, 2=Medium, 3=High
  final List<String> tags;        // Categorization tags
  final TaskStatus status;        // Current completion state
  final String? linkedNoteId;     // Optional linked note
  final String? linkedDeckId;     // Optional linked flashcard deck
}

enum TaskStatus { 
  pending,      // Not started
  inProgress,   // Currently working
  completed,    // Finished
  cancelled     // Abandoned
}
```

### FlashCard
Individual flashcard with front/back content and type specification.

```dart
class FlashCard {
  final String id;           // Unique identifier
  final String deckId;       // Parent deck reference
  final CardType type;       // Card format type
  final String front;        // Question/prompt text
  final String back;         // Answer/response text
  final String? clozeMask;   // Cloze deletion pattern (optional)
}

enum CardType { 
  basic,    // Standard Q&A format
  cloze,    // Fill-in-the-blank
  reverse   // Bidirectional review
}
```

### Review
SRS (Spaced Repetition System) review data for flashcard scheduling.

```dart
class Review {
  final String cardId;           // Target flashcard
  final String userId;           // Reviewing user
  final DateTime dueAt;          // Next review schedule
  final double ease;             // Difficulty factor (1.3-2.5)
  final int interval;            // Days until next review
  final int reps;                // Number of successful reviews
  final ReviewGrade? lastGrade;  // Most recent performance
  final DateTime? lastReviewed;  // Last review timestamp
}

enum ReviewGrade { 
  again,  // Failed - restart learning
  hard,   // Difficult - reduce interval
  good,   // Normal - standard progression
  easy    // Simple - increase interval
}
```

### Pet
Virtual companion with progression and mood tracking.

```dart
class Pet {
  final String userId;        // Owner reference
  final PetSpecies species;   // Animal type
  final int level;            // Current progression level
  final int xp;              // Experience points
  final List<String> gear;    // Equipped items
  final PetMood mood;        // Current emotional state
  final DateTime createdAt;   // Creation timestamp
}

enum PetSpecies { cat, dog, dragon, owl, fox }
enum PetMood { sleepy, content, happy, excited }
```

## Providers

### AppState
Global application state management for authentication and user session.

```dart
class AppState extends ChangeNotifier {
  bool get isAuthenticated;     // Login status
  User? get currentUser;        // Active user data
  
  void login(User user);        // Authenticate user
  void logout();                // Clear session
}
```

### TaskProvider
Task management with CRUD operations and filtering.

```dart
class TaskProvider extends ChangeNotifier {
  List<Task> get tasks;           // All user tasks
  List<Task> get todayTasks;      // Tasks due today
  List<Task> get pendingTasks;    // Incomplete tasks
  bool get isLoading;             // Loading state
  
  Future<void> loadTasks();                    // Fetch from database
  Future<void> addTask(Task task);             // Create new task
  Future<void> updateTask(Task task);          // Modify existing
  Future<void> deleteTask(String taskId);     // Remove task
  Future<void> completeTask(String taskId);   // Mark as done
}
```

### DeckProvider
Flashcard deck management with card operations.

```dart
class DeckProvider extends ChangeNotifier {
  List<Deck> get decks;           // All flashcard decks
  bool get isLoading;             // Loading state
  
  Future<void> loadDecks();                               // Fetch from database
  void addDeck(Deck deck);                               // Create new deck
  void addCardToDeck(String deckId, FlashCard card);     // Add card to deck
  void removeCardFromDeck(String deckId, String cardId); // Remove card
  List<FlashCard> getAllCards();                         // Get all cards
}
```

### SRSProvider
Spaced Repetition System with SM-2 algorithm implementation.

```dart
class SRSProvider extends ChangeNotifier {
  List<Review> get reviews;       // All review records
  List<Review> get dueReviews;    // Cards due for review
  int get dueCount;               // Number of due cards
  bool get isLoading;             // Loading state
  
  Future<void> loadReviews();                              // Fetch from database
  void recordReview(FlashCard card, ReviewGrade grade);    // Process review
  List<FlashCard> getDueCards(List<FlashCard> allCards);   // Filter due cards
  Map<String, int> getReviewStats();                      // Statistics summary
}
```

### PetProvider
Virtual pet management with progression and interaction.

```dart
class PetProvider extends ChangeNotifier {
  Pet get currentPet;         // Active pet data
  int get currentStreak;      // Study streak days
  
  void addXP(int amount);                          // Award experience
  void updateStreak(int streak);                   // Update study streak
  void feedPet();                                  // Pet interaction (+10 XP)
  void playWithPet();                             // Pet interaction (+15 XP)
  void changePetSpecies(PetSpecies newSpecies);   // Change pet type
}
```

## Services

### DatabaseService
SQLite database management with cross-platform support.

```dart
class DatabaseService {
  static Future<Database> get database;    // Database connection
  static Future<void> initialize();       // Setup for web/mobile
  
  // Database tables created:
  // - users, tasks, notes, decks, cards
  // - reviews, schedule_blocks, pets, streaks
}
```

### TaskRepository
Data access layer for task operations.

```dart
class TaskRepository {
  static Future<List<Task>> getAllTasks();        // Fetch all tasks
  static Future<void> insertTask(Task task);      // Create new task
  static Future<void> updateTask(Task task);      // Modify existing
  static Future<void> deleteTask(String taskId);  // Remove task
}
```

## Widgets

### Dashboard Widgets

#### PetWidget
Interactive virtual pet display with feeding and play actions.

**Features:**
- Pet avatar with species-specific icons
- XP progress bar with level display
- Mood indicator chip
- Study streak counter
- Feed and play buttons

#### TodayTasksWidget
Task list showing today's scheduled items with completion tracking.

**Features:**
- Task title and estimated time
- Priority color coding
- Completion checkboxes
- Add task button
- View more tasks link

#### DueCardsWidget
Flashcard review interface with due count and review button.

**Features:**
- Due card counter with badge
- Review time estimation
- Start review button
- Empty state messaging

#### QuickStatsWidget
Statistics overview with key performance metrics.

**Features:**
- Task completion ratio
- Deck count
- Daily review count
- Pet level display
- Study streak highlight

### Common Widgets

#### AddTaskSheet
Modal bottom sheet for creating new tasks.

**Form Fields:**
- Task title (required)
- Estimated minutes (numeric)
- Due date picker
- Priority selection (Low/Medium/High)
- Tag management
- Save/cancel actions

## Database Schema

### Users Table
```sql
CREATE TABLE users (
  id TEXT PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  created_at TEXT NOT NULL,
  study_start_hour INTEGER DEFAULT 9,
  study_end_hour INTEGER DEFAULT 21,
  max_cards_per_day INTEGER DEFAULT 20,
  max_minutes_per_day INTEGER DEFAULT 180
);
```

### Tasks Table
```sql
CREATE TABLE tasks (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  est_minutes INTEGER NOT NULL,
  due_at TEXT,
  priority INTEGER DEFAULT 1,
  tags TEXT,
  status TEXT NOT NULL,
  linked_note_id TEXT,
  linked_deck_id TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);
```

### Cards Table
```sql
CREATE TABLE cards (
  id TEXT PRIMARY KEY,
  deck_id TEXT NOT NULL,
  type TEXT NOT NULL,
  front TEXT NOT NULL,
  back TEXT NOT NULL,
  cloze_mask TEXT,
  created_at TEXT NOT NULL,
  FOREIGN KEY (deck_id) REFERENCES decks (id) ON DELETE CASCADE
);
```

### Reviews Table
```sql
CREATE TABLE reviews (
  card_id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  due_at TEXT NOT NULL,
  ease REAL DEFAULT 2.5,
  interval INTEGER DEFAULT 1,
  reps INTEGER DEFAULT 0,
  last_grade TEXT,
  last_reviewed TEXT,
  FOREIGN KEY (card_id) REFERENCES cards (id) ON DELETE CASCADE
);
```

### Pets Table
```sql
CREATE TABLE pets (
  user_id TEXT PRIMARY KEY,
  species TEXT NOT NULL,
  level INTEGER DEFAULT 1,
  xp INTEGER DEFAULT 0,
  gear TEXT,
  mood TEXT DEFAULT 'happy',
  created_at TEXT NOT NULL
);
```

## Error Handling

### Common Error Types
- **ValidationError**: Invalid input data
- **DatabaseError**: SQL operation failures
- **NetworkError**: Connectivity issues
- **AuthenticationError**: Login/session problems

### Error Recovery
- Automatic retry for transient failures
- Graceful degradation for missing data
- User-friendly error messages
- Fallback to cached data when possible
