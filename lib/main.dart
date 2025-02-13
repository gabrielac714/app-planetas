class Planet {
  int? id;
  String name;
  double distanceFromSun;
  double size;
  String? nickname;

  Planet({
    this.id,
    required this.name,
    required this.distanceFromSun,
    required this.size,
    this.nickname,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'distanceFromSun': distanceFromSun,
      'size': size,
      'nickname': nickname,
    };
  }

  factory Planet.fromMap(Map<String, dynamic> map) {
    return Planet(
      id: map['id'],
      name: map['name'],
      distanceFromSun: map['distanceFromSun'],
      size: map['size'],
      nickname: map['nickname'],
    );
  }
}

import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/planet.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  Future<Database> _initDb() async {
    String path = join(await getDatabasesPath(), 'planets.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE planets(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        distanceFromSun REAL NOT NULL,
        size REAL NOT NULL,
        nickname TEXT
      )
    ''');
  }

  Future<int> insertPlanet(Planet planet) async {
    Database db = await database;
    return await db.insert('planets', planet.toMap());
  }

  Future<List<Planet>> getPlanets() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query('planets');
    return List.generate(maps.length, (i) {
      return Planet.fromMap(maps[i]);
    });
  }

  Future<int> updatePlanet(Planet planet) async {
    Database db = await database;
    return await db.update(
      'planets',
      planet.toMap(),
      where: 'id = ?',
      whereArgs: [planet.id],
    );
  }

  Future<int> deletePlanet(int id) async {
    Database db = await database;
    return await db.delete(
      'planets',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/planet.dart';
import '../widgets/planet_list_item.dart';
import 'planet_form_screen.dart';
import 'planet_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Planet> _planets = [];

  @override
  void initState() {
    super.initState();
    _fetchPlanets();
  }

  void _fetchPlanets() async {
    final planets = await _dbHelper.getPlanets();
    setState(() {
      _planets = planets;
    });
  }

  void _deletePlanet(int id) async {
    await _dbHelper.deletePlanet(id);
    _fetchPlanets();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Planetas'),
      ),
      body: ListView.builder(
        itemCount: _planets.length,
        itemBuilder: (context, index) {
          return PlanetListItem(
            planet: _planets[index],
            onDelete: () => _deletePlanet(_planets[index].id!),
            onEdit: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PlanetFormScreen(planet: _planets[index]),
                ),
              );
              if (result != null) {
                _fetchPlanets();
              }
            },
            onViewDetails: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PlanetDetailScreen(planet: _planets[index]),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PlanetFormScreen(),
            ),
          );
          if (result != null) {
            _fetchPlanets();
          }
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/planet.dart';

class PlanetFormScreen extends StatefulWidget {
  final Planet? planet;

  PlanetFormScreen({this.planet});

  @override
  _PlanetFormScreenState createState() => _PlanetFormScreenState();
}

class _PlanetFormScreenState extends State<PlanetFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseHelper _dbHelper = DatabaseHelper();

  late String _name;
  late double _distanceFromSun;
  late double _size;
  String? _nickname;

  @override
  void initState() {
    super.initState();
    if (widget.planet != null) {
      _name = widget.planet!.name;
      _distanceFromSun = widget.planet!.distanceFromSun;
      _size = widget.planet!.size;
      _nickname = widget.planet!.nickname;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.planet == null ? 'Adicionar Planeta' : 'Editar Planeta'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: 