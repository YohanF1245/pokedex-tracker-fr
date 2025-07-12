import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'pokemon.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Get the directory for storing the database
    final documentsDirectory = await getDatabasesPath();
    final path = join(documentsDirectory, 'pokemon.db');

    // Check if the database exists
    final exists = await databaseExists(path);

    if (!exists) {
      // Copy the database from assets
      final data = await rootBundle.load('assets/pokemon.db');
      final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      await File(path).writeAsBytes(bytes);
    }

    // Open the database
    return await openDatabase(path, version: 1);
  }

  Future<List<Pokemon>> getAllPokemon() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('pokemon', orderBy: 'number ASC, form ASC');
    
    return List.generate(maps.length, (i) {
      return Pokemon.fromMap(maps[i]);
    });
  }

  Future<List<Pokemon>> getPokemonByForm(String form) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'pokemon',
      where: 'form = ?',
      whereArgs: [form],
      orderBy: 'number ASC',
    );
    
    return List.generate(maps.length, (i) {
      return Pokemon.fromMap(maps[i]);
    });
  }

  Future<Map<String, List<Pokemon>>> getPokemonGroupedByGeneration() async {
    final allPokemon = await getAllPokemon();
    final Map<String, List<Pokemon>> grouped = {};

    for (final pokemon in allPokemon) {
      final genKey = pokemon.generationName;
      
      if (!grouped.containsKey(genKey)) {
        grouped[genKey] = [];
      }
      grouped[genKey]!.add(pokemon);
    }

    // Sort generations in order
    final sortedKeys = grouped.keys.toList()..sort((a, b) {
      final genA = int.parse(a.split(' ')[1]);
      final genB = int.parse(b.split(' ')[1]);
      return genA.compareTo(genB);
    });

    final sortedGrouped = <String, List<Pokemon>>{};
    for (final key in sortedKeys) {
      sortedGrouped[key] = grouped[key]!;
    }

    return sortedGrouped;
  }

  Future<List<Pokemon>> searchPokemon(String query) async {
    final allPokemon = await getAllPokemon();
    return allPokemon.where((pokemon) => pokemon.matchesSearch(query)).toList();
  }

  Future<Map<String, List<Pokemon>>> searchPokemonGroupedByGeneration(String query) async {
    final allPokemon = await searchPokemon(query);
    final Map<String, List<Pokemon>> grouped = {};

    for (final pokemon in allPokemon) {
      final genKey = pokemon.generationName;
      
      if (!grouped.containsKey(genKey)) {
        grouped[genKey] = [];
      }
      grouped[genKey]!.add(pokemon);
    }

    // Sort generations in order
    final sortedKeys = grouped.keys.toList()..sort((a, b) {
      final genA = int.parse(a.split(' ')[1]);
      final genB = int.parse(b.split(' ')[1]);
      return genA.compareTo(genB);
    });

    final sortedGrouped = <String, List<Pokemon>>{};
    for (final key in sortedKeys) {
      sortedGrouped[key] = grouped[key]!;
    }

    return sortedGrouped;
  }

  Future<void> updatePokemonStatus(int pokemonId, int status) async {
    final db = await database;
    await db.update(
      'pokemon',
      {'status': status},
      where: 'id = ?',
      whereArgs: [pokemonId],
    );
  }

  Future<Map<String, int>> getStatusCounts() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT status, COUNT(*) as count 
      FROM pokemon 
      GROUP BY status
    ''');
    
    final Map<String, int> counts = {
      'not_caught': 0,
      'caught_normal': 0,
      'caught_shiny': 0,
    };

    for (final row in result) {
      final status = row['status'] as int;
      final count = row['count'] as int;
      
      switch (status) {
        case 0:
          counts['not_caught'] = count;
          break;
        case 1:
          counts['caught_normal'] = count;
          break;
        case 2:
          counts['caught_shiny'] = count;
          break;
      }
    }

    return counts;
  }

  Future<Map<String, Map<String, int>>> getStatusCountsByGeneration() async {
    final allPokemon = await getAllPokemon();
    final Map<String, Map<String, int>> generationStats = {};

    for (final pokemon in allPokemon) {
      final genKey = pokemon.generationName;
      
      if (!generationStats.containsKey(genKey)) {
        generationStats[genKey] = {
          'total': 0,
          'not_caught': 0,
          'caught_normal': 0,
          'caught_shiny': 0,
        };
      }

      generationStats[genKey]!['total'] = generationStats[genKey]!['total']! + 1;
      
      switch (pokemon.status) {
        case 0:
          generationStats[genKey]!['not_caught'] = generationStats[genKey]!['not_caught']! + 1;
          break;
        case 1:
          generationStats[genKey]!['caught_normal'] = generationStats[genKey]!['caught_normal']! + 1;
          break;
        case 2:
          generationStats[genKey]!['caught_shiny'] = generationStats[genKey]!['caught_shiny']! + 1;
          break;
      }
    }

    return generationStats;
  }
} 