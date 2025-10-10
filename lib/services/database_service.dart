// Import SQLite database package for local data storage
import 'package:sqflite/sqflite.dart';
// Import path utilities for constructing database file paths
import 'package:path/path.dart';
// Import Flutter foundation to check if running on web platform
import 'package:flutter/foundation.dart';

// Import web-specific SQLite implementation for browser compatibility
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

/// Database service managing SQLite database operations for StudyPals app
/// Handles database initialization, table creation, and provides database instance
/// Supports both mobile (native SQLite) and web (SQLite via WebAssembly) platforms
///
/// NOTE: This service is partially deprecated but still in use by task_repository.dart
/// - Most features have migrated to FirestoreService for cloud sync
/// - Still used by: task_repository.dart (which is itself unused), main.dart initialization
/// - Consider full migration to Firestore and removal once all dependencies verified
class DatabaseService {
  // Static database instance - singleton pattern ensures one database connection
  static Database? _database;

  // Database file name stored on device/browser
  static const String _dbName = 'studypals.db';

  // Database schema version - increment when making schema changes
  static const int _dbVersion = 1;

  /// Initializes database factory for cross-platform compatibility
  /// Must be called before any database operations
  /// Sets up web-specific database factory when running in browser
  static Future<void> initialize() async {
    // Check if running in web browser environment
    if (kIsWeb) {
      // Use WebAssembly-based SQLite for web browsers
      databaseFactory = databaseFactoryFfiWeb;
    }
    // For mobile platforms, default SQLite factory is used automatically
  }

  /// Gets the database instance, creating it if it doesn't exist
  /// Implements lazy initialization - database is only opened when first needed
  /// @return Database instance ready for queries
  static Future<Database> get database async {
    // Return existing database if already initialized
    if (_database != null) return _database!;

    // Ensure platform-specific initialization is complete
    await initialize();

    // Create and configure the database
    _database = await _initDatabase();

    return _database!;
  }

  /// Creates and opens the SQLite database file
  /// Sets up database path, version, and callback functions
  /// @return Configured Database instance
  static Future<Database> _initDatabase() async {
    // Get platform-appropriate directory for database files
    final dbPath = await getDatabasesPath();

    // Construct full path to database file
    final path = join(dbPath, _dbName);

    // Open database with configuration
    return await openDatabase(
      path, // Full path to database file
      version: _dbVersion, // Schema version for migration tracking
      onCreate: _onCreate, // Callback when database is first created
      onUpgrade: _onUpgrade, // Callback when database version changes
    );
  }

  /// Creates all database tables when database is first initialized
  /// Defines the complete schema for the StudyPals application
  /// @param db - Database instance to execute CREATE TABLE statements on
  /// @param version - Version number (currently unused)
  static Future<void> _onCreate(Database db, int version) async {
    // Users table - stores user profile and preferences
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,                    -- Unique user identifier
        email TEXT UNIQUE NOT NULL,             -- User email (unique constraint)
        name TEXT NOT NULL,                     -- Display name
        created_at TEXT NOT NULL,               -- Account creation timestamp
        study_start_hour INTEGER DEFAULT 9,     -- Preferred study start time (24h format)
        study_end_hour INTEGER DEFAULT 21,      -- Preferred study end time (24h format)
        max_cards_per_day INTEGER DEFAULT 20,   -- Daily flashcard review limit
        max_minutes_per_day INTEGER DEFAULT 180 -- Daily study time limit (3 hours)
      )
    ''');

    // Tasks table - stores to-do items and assignments
    await db.execute('''
      CREATE TABLE tasks (
        id TEXT PRIMARY KEY,                    -- Unique task identifier
        title TEXT NOT NULL,                    -- Task description/title
        est_minutes INTEGER NOT NULL,           -- Estimated completion time
        due_at TEXT,                           -- Optional deadline (ISO string)
        priority INTEGER DEFAULT 1,            -- Priority level (1=low, 2=med, 3=high)
        tags TEXT,                             -- JSON array of tag strings
        status TEXT NOT NULL,                  -- Current status (pending/inProgress/completed/cancelled)
        linked_note_id TEXT,                   -- Optional reference to related note
        linked_deck_id TEXT,                   -- Optional reference to related deck
        created_at TEXT NOT NULL,              -- Task creation timestamp
        updated_at TEXT NOT NULL               -- Last modification timestamp
      )
    ''');

    // Notes table - stores study notes and documents
    await db.execute('''
      CREATE TABLE notes (
        id TEXT PRIMARY KEY,                    -- Unique note identifier
        title TEXT NOT NULL,                    -- Note title/subject
        content_md TEXT NOT NULL,               -- Note content in Markdown format
        tags TEXT,                             -- JSON array of tag strings for categorization
        created_at TEXT NOT NULL,              -- Note creation timestamp
        updated_at TEXT NOT NULL               -- Last modification timestamp
      )
    ''');

    // Decks table - stores flashcard collections
    await db.execute('''
      CREATE TABLE decks (
        id TEXT PRIMARY KEY,                    -- Unique deck identifier
        title TEXT NOT NULL,                    -- Deck name/subject
        tags TEXT,                             -- JSON array of tag strings
        note_id TEXT,                          -- Optional reference to source note
        created_at TEXT NOT NULL,              -- Deck creation timestamp
        updated_at TEXT NOT NULL               -- Last modification timestamp
      )
    ''');

    // Cards table - stores individual flashcards within decks
    await db.execute('''
      CREATE TABLE cards (
        id TEXT PRIMARY KEY,                    -- Unique card identifier
        deck_id TEXT NOT NULL,                  -- Reference to parent deck
        type TEXT NOT NULL,                     -- Card type (basic/cloze)
        front TEXT NOT NULL,                    -- Question/prompt side
        back TEXT NOT NULL,                     -- Answer side
        cloze_mask TEXT,                       -- Cloze deletion mask (for cloze cards)
        created_at TEXT NOT NULL,              -- Card creation timestamp
        FOREIGN KEY (deck_id) REFERENCES decks (id) ON DELETE CASCADE -- Delete cards when deck is deleted
      )
    ''');

    // Reviews table - tracks spaced repetition system data
    await db.execute('''
      CREATE TABLE reviews (
        card_id TEXT PRIMARY KEY,               -- Reference to card being reviewed
        user_id TEXT NOT NULL,                  -- User who owns this review data
        due_at TEXT NOT NULL,                   -- When card should be reviewed next
        ease REAL DEFAULT 2.5,                 -- Ease factor for spacing algorithm
        interval INTEGER DEFAULT 1,            -- Days until next review
        reps INTEGER DEFAULT 0,                 -- Number of times reviewed
        last_grade TEXT,                       -- Last review performance (again/hard/good/easy)
        last_reviewed TEXT,                    -- Timestamp of last review
        FOREIGN KEY (card_id) REFERENCES cards (id) ON DELETE CASCADE -- Delete review data when card is deleted
      )
    ''');

    // Schedule blocks table - stores calendar/study session blocks
    await db.execute('''
      CREATE TABLE schedule_blocks (
        id TEXT PRIMARY KEY,                    -- Unique block identifier
        user_id TEXT NOT NULL,                  -- User who owns this schedule block
        task_id TEXT,                          -- Optional reference to related task
        start TEXT NOT NULL,                   -- Block start time (ISO string)
        end TEXT NOT NULL,                     -- Block end time (ISO string)
        type TEXT NOT NULL,                    -- Block type (study/break/task/etc)
        created_at TEXT NOT NULL               -- Block creation timestamp
      )
    ''');

    // Pets table - stores virtual pet data for gamification
    await db.execute('''
      CREATE TABLE pets (
        user_id TEXT PRIMARY KEY,               -- User who owns this pet (one pet per user)
        species TEXT NOT NULL,                  -- Pet type (cat/dog/dragon/owl/fox)
        level INTEGER DEFAULT 1,               -- Current pet level
        xp INTEGER DEFAULT 0,                  -- Experience points within current level
        gear TEXT,                             -- JSON array of unlocked accessories
        mood TEXT DEFAULT 'happy',             -- Current pet mood (sleepy/content/happy/excited)
        created_at TEXT NOT NULL               -- Pet creation timestamp
      )
    ''');

    // Study streaks table - tracks daily study consistency
    await db.execute('''
      CREATE TABLE streaks (
        user_id TEXT PRIMARY KEY,               -- User whose streak this tracks
        current_streak INTEGER DEFAULT 0,       -- Days of consecutive studying
        longest_streak INTEGER DEFAULT 0,       -- Best streak ever achieved
        last_study_date TEXT                   -- Date of most recent study session
      )
    ''');
  }

  /// Handles database schema migrations when version number increases
  /// Currently empty but will contain ALTER TABLE statements for future updates
  /// @param db - Database instance to perform migrations on
  /// @param oldVersion - Previous schema version
  /// @param newVersion - Target schema version
  static Future<void> _onUpgrade(
      Database db, int oldVersion, int newVersion) async {
    // Handle database migrations here when schema changes are needed
    // Example: if (oldVersion < 2) { await db.execute('ALTER TABLE...'); }
  }
}
