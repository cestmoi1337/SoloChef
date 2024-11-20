import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Singleton class to manage the SQLite database connection and queries
class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  factory DBHelper() => _instance;

  DBHelper._internal();

  static Database? _database;

  /// Getter to retrieve the database. Initializes it if it hasn't been created yet.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase(); // Initialize the database
    return _database!;
  }

  /// Initialize the SQLite database
  Future<Database> _initDatabase() async {
    // Get the default database path for the platform (e.g., Android, iOS)
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'solochef.db');

    // Open or create the database, and set up tables if they don't exist
    return await openDatabase(
      path,
      version: 1, // Versioning for schema updates in the future
      onCreate: _onCreate,
    );
  }

  /// Called when the database is created for the first time
  Future _onCreate(Database db, int version) async {
    // Create the pantry table
    await db.execute('''
      CREATE TABLE pantry (
        id INTEGER PRIMARY KEY AUTOINCREMENT, -- Unique ID for each item
        name TEXT NOT NULL, -- Name of the ingredient
        quantity INTEGER NOT NULL, -- Quantity of the ingredient
        expiration DATE NOT NULL -- Expiration date
      )
    ''');

    // Create the favorites table
    await db.execute('''
      CREATE TABLE favorites (
        id INTEGER PRIMARY KEY AUTOINCREMENT, -- Unique ID for each favorite
        recipe_id INTEGER NOT NULL, -- ID of the recipe (from recipe data)
        notes TEXT, -- Optional user notes about the recipe
        date_added DATE DEFAULT CURRENT_TIMESTAMP -- Timestamp for when the recipe was added
      )
    ''');
  }

  // CRUD OPERATIONS FOR THE PANTRY TABLE

  /// Add a new ingredient to the pantry
  Future<int> insertPantryItem(
      String name, int quantity, String expiration) async {
    final db = await database; // Get the database connection
    return await db.insert(
      'pantry', // Table name
      {
        'name': name,
        'quantity': quantity,
        'expiration': expiration, // Date in string format (e.g., "2024-12-31")
      },
      conflictAlgorithm: ConflictAlgorithm.replace, // Replaces if duplicate
    );
  }

  /// Fetch all ingredients from the pantry
  Future<List<Map<String, dynamic>>> fetchPantryItems() async {
    final db = await database;
    return await db.query('pantry'); // Returns all rows in the pantry table
  }

  /// Update an existing pantry item (e.g., to change quantity or expiration)
  Future<int> updatePantryItem(
      int id, String name, int quantity, String expiration) async {
    final db = await database;
    return await db.update(
      'pantry', // Table name
      {
        'name': name,
        'quantity': quantity,
        'expiration': expiration,
      },
      where: 'id = ?', // Update only the row with this id
      whereArgs: [id],
    );
  }

  /// Delete an ingredient from the pantry
  Future<int> deletePantryItem(int id) async {
    final db = await database;
    return await db.delete(
      'pantry', // Table name
      where: 'id = ?', // Delete only the row with this id
      whereArgs: [id],
    );
  }

  // CRUD OPERATIONS FOR THE FAVORITES TABLE

  /// Add a recipe to the favorites list
  Future<int> insertFavorite(int recipeId, String? notes) async {
    final db = await database;
    return await db.insert(
      'favorites',
      {
        'recipe_id': recipeId,
        'notes': notes, // Nullable: notes can be null
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Fetch all favorite recipes
  Future<List<Map<String, dynamic>>> fetchFavorites() async {
    final db = await database;
    return await db
        .query('favorites'); // Returns all rows in the favorites table
  }

  /// Update notes for a favorite recipe
  Future<int> updateFavoriteNotes(int id, String? notes) async {
    final db = await database;
    return await db.update(
      'favorites',
      {
        'notes': notes, // Update only the notes field
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete a recipe from the favorites list
  Future<int> deleteFavorite(int id) async {
    final db = await database;
    return await db.delete(
      'favorites',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
