// lib/database_helper.dart

import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

// --- 데이터 모델 수정 ---

// Todo 데이터 모델 (변경 없음)
class Todo {
  int? id;
  String task;
  bool isDone;
  String date;

  Todo({this.id, required this.task, this.isDone = false, required this.date});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'task': task,
      'isDone': isDone ? 1 : 0,
      'date': date,
    };
  }
}

// Diary 데이터 모델 (imagePath -> imagePaths 리스트로 변경)
class Diary {
  int? id;
  String content;
  List<String> imagePaths; // ✅ String? imagePath -> List<String> imagePaths
  String date;

  Diary({this.id, required this.content, this.imagePaths = const [], required this.date});

  // toMap에서 imagePaths 제거 (별도 테이블에서 관리)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'content': content,
      'date': date,
    };
  }
}


// --- 데이터베이스 헬퍼 클래스 수정 ---

class DatabaseHelper {
  static final _databaseName = "MyDiary.db";
  static final _databaseVersion = 2; // ✅ 스키마 변경으로 버전업

  static final diaryTable = 'diary';
  static final todoTable = 'todo';
  static final diaryImagesTable = 'diary_images'; // ✅ 이미지 테이블 이름 추가

  static final columnId = 'id';
  static final columnContent = 'content';
  // static final columnImagePath = 'imagePath'; // ❌ 사용 안함
  static final columnDate = 'date';
  static final columnTask = 'task';
  static final columnIsDone = 'isDone';

  // ✅ 이미지 테이블 컬럼
  static final columnDiaryId = 'diary_id';
  static final columnImagePath = 'image_path';


  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    // ✅ onUpgrade 추가
    return await openDatabase(path, version: _databaseVersion, onCreate: _onCreate, onUpgrade: _onUpgrade);
  }

  // ✅ DB 스키마 업그레이드 함수
  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE $diaryImagesTable (
          $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
          $columnDiaryId INTEGER NOT NULL,
          $columnImagePath TEXT NOT NULL,
          FOREIGN KEY ($columnDiaryId) REFERENCES $diaryTable ($columnId) ON DELETE CASCADE
        )
      ''');
      // 만약 버전 1에서 마이그레이션이 필요하다면 여기에 코드를 추가할 수 있습니다.
      // (예: 기존 diaryTable의 imagePath 데이터를 새 테이블로 옮기는 작업)
      // 지금은 새로 시작하는 기준으로 작성합니다.
    }
  }


  Future _onCreate(Database db, int version) async {
    // ✅ diaryTable에서 imagePath 컬럼 제거
    await db.execute('''
      CREATE TABLE $diaryTable (
        $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnContent TEXT NOT NULL,
        $columnDate TEXT NOT NULL UNIQUE
      )
    ''');

    await db.execute('''
      CREATE TABLE $todoTable (
        $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnTask TEXT NOT NULL,
        $columnIsDone INTEGER NOT NULL DEFAULT 0,
        $columnDate TEXT NOT NULL
      )
    ''');

    // ✅ diary_images 테이블 생성
    await db.execute('''
      CREATE TABLE $diaryImagesTable (
        $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnDiaryId INTEGER NOT NULL,
        $columnImagePath TEXT NOT NULL,
        FOREIGN KEY ($columnDiaryId) REFERENCES $diaryTable ($columnId) ON DELETE CASCADE
      )
    ''');
  }

  // --- Diary 관련 함수 수정 ---

  Future<int> insertOrUpdateDiary(Diary diary) async {
    final db = await instance.database;
    int diaryId;

    // 1. Diary 콘텐츠 먼저 삽입 또는 업데이트
    List<Map> maps = await db.query(diaryTable, columns: [columnId], where: '$columnDate = ?', whereArgs: [diary.date]);
    if (maps.isNotEmpty) {
      diaryId = maps.first[columnId];
      await db.update(diaryTable, {'content': diary.content}, where: '$columnId = ?', whereArgs: [diaryId]);
    } else {
      diaryId = await db.insert(diaryTable, diary.toMap());
    }

    // 2. 기존 이미지 경로 모두 삭제 (업데이트를 위해)
    await db.delete(diaryImagesTable, where: '$columnDiaryId = ?', whereArgs: [diaryId]);

    // 3. 새 이미지 경로들 삽입
    for (String path in diary.imagePaths) {
      await db.insert(diaryImagesTable, {
        columnDiaryId: diaryId,
        columnImagePath: path,
      });
    }

    return diaryId;
  }

  Future<Diary?> getDiary(String date) async {
    final db = await instance.database;
    List<Map<String, dynamic>> maps = await db.query(diaryTable, where: '$columnDate = ?', whereArgs: [date]);

    if (maps.isNotEmpty) {
      final diaryData = maps.first;
      final diaryId = diaryData[columnId];

      // 연결된 이미지 경로들 가져오기
      final List<Map<String, dynamic>> imageMaps = await db.query(diaryImagesTable, where: '$columnDiaryId = ?', whereArgs: [diaryId]);
      final List<String> imagePaths = imageMaps.map((img) => img[columnImagePath] as String).toList();

      return Diary(
        id: diaryId,
        content: diaryData[columnContent],
        date: diaryData[columnDate],
        imagePaths: imagePaths, // ✅ 이미지 경로 리스트를 포함하여 반환
      );
    }
    return null;
  }

  // (getAllDiaryDates, Todo 관련 함수들은 변경 없음)
  Future<List<String>> getAllDiaryDates() async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(diaryTable, columns: [columnDate], distinct: true);
    if (maps.isNotEmpty) {
      return maps.map((map) => map[columnDate] as String).toList();
    } else {
      return [];
    }
  }

  Future<List<Todo>> getTodos(String date) async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(todoTable, where: '$columnDate = ?', whereArgs: [date]);
    return List.generate(maps.length, (i) {
      return Todo(
        id: maps[i][columnId],
        task: maps[i][columnTask],
        isDone: maps[i][columnIsDone] == 1,
        date: maps[i][columnDate],
      );
    });
  }

  Future<int> insertTodo(Todo todo) async {
    Database db = await instance.database;
    return await db.insert(todoTable, todo.toMap());
  }

  Future<int> updateTodo(Todo todo) async {
    Database db = await instance.database;
    return await db.update(todoTable, todo.toMap(), where: '$columnId = ?', whereArgs: [todo.id]);
  }

  Future<int> deleteTodo(int id) async {
    Database db = await instance.database;
    return await db.delete(todoTable, where: '$columnId = ?', whereArgs: [id]);
  }

  Future<List<String>> getAllTodoDates() async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(todoTable, columns: [columnDate], distinct: true);
    if (maps.isNotEmpty) {
      return maps.map((map) => map[columnDate] as String).toList();
    } else {
      return [];
    }
  }
}