import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import '../models/embedding.dart';

/// 本地存储服务
/// - 使用 SQLite 存储文本和向量数据
/// - 支持批量操作和事务
/// - 实现简单的向量相似度搜索
class LocalStorageService {
  static final LocalStorageService _instance = LocalStorageService._internal();
  factory LocalStorageService() => _instance;
  LocalStorageService._internal();

  static Database? _db;
  
  /// 数据库版本，修改schema时递增
  static const int _version = 1;

  /// 获取数据库实例
  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  /// 初始化数据库
  Future<Database> _initDatabase() async {
    final appDir = await getApplicationSupportDirectory();
    final dbPath = join(appDir.path, 'knowledge.db');
    
    return await openDatabase(
      dbPath,
      version: _version,
      onCreate: _createDb,
      onUpgrade: _upgradeDb,
    );
  }

  /// 创建数据库表
  Future<void> _createDb(Database db, int version) async {
    // 1. 向量表（存储文本及其向量）
    await db.execute('''
      CREATE TABLE IF NOT EXISTS embeddings (
        id TEXT PRIMARY KEY,
        text TEXT NOT NULL,
        vec TEXT NOT NULL,
        module_id TEXT NOT NULL,
        type TEXT NOT NULL,
        metadata TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    // 2. 模块向量索引表（用于加速检索）
    await db.execute('''
      CREATE TABLE IF NOT EXISTS vector_index (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        embedding_id TEXT NOT NULL,
        module_id TEXT NOT NULL,
        vec_part INTEGER NOT NULL,
        vec_value REAL NOT NULL,
        FOREIGN KEY (embedding_id) REFERENCES embeddings (id) ON DELETE CASCADE
      )
    ''');

    // 3. 创建索引
    await db.execute('CREATE INDEX idx_embeddings_module ON embeddings (module_id)');
    await db.execute('CREATE INDEX idx_vector_index_module ON vector_index (module_id)');
    await db.execute('CREATE INDEX idx_vector_index_part ON vector_index (vec_part)');
  }

  /// 数据库升级逻辑
  Future<void> _upgradeDb(Database db, int oldVersion, int newVersion) async {
    // 简单的升级占位实现：按版本顺序执行迁移步骤
    // 若需要增加新表或变更 schema，应在此处添加对应迁移逻辑
    for (var v = oldVersion + 1; v <= newVersion; v++) {
      // 示例：如果将来 v==2 需要添加新表，可在这里处理
      // if (v == 2) { await db.execute('CREATE TABLE ...'); }
    }
    return;
  }

  /// 批量插入向量
  Future<void> insertEmbeddings(List<Embedding> embeddings) async {
    final db = await database;
    final batch = db.batch();

    for (final emb in embeddings) {
      // 1. 插入主记录
      batch.insert('embeddings', emb.toSqlite(), 
        conflictAlgorithm: ConflictAlgorithm.replace);

      // 2. 为向量值创建索引记录（用于近似最近邻搜索）
      for (var i = 0; i < emb.vec.length; i++) {
        batch.insert('vector_index', {
          'embedding_id': emb.id,
          'module_id': emb.moduleId,
          'vec_part': i,
          'vec_value': emb.vec[i],
        });
      }
    }

    await batch.commit(noResult: true);
  }

  /// 删除模块的所有向量
  Future<void> deleteModuleEmbeddings(String moduleId) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('embeddings', where: 'module_id = ?', whereArgs: [moduleId]);
      await txn.delete('vector_index', where: 'module_id = ?', whereArgs: [moduleId]);
    });
  }

  /// 简单的向量近似最近邻搜索
  /// 实现思路：
  /// 1. 将向量分解为多个维度存储在vector_index表中
  /// 2. 查询时计算每个维度的欧氏距离
  /// 3. 使用SQL聚合函数计算总距离并排序
  Future<List<SearchResult>> search(
    List<double> queryVec,
    String moduleId, {
    int limit = 10,
  }) async {
    final db = await database;
    
    // 构建查询SQL：计算欧氏距离并按距离排序
    final distanceCalc = queryVec.asMap().entries.map((e) {
      return "POWER(COALESCE(MAX(CASE WHEN vi.vec_part = ${e.key} THEN vi.vec_value END) - ${e.value}, 0), 2)";
    }).join(' + ');

    final results = await db.rawQuery('''
      SELECT 
        e.id,
        e.text,
        e.module_id,
        e.type,
        e.metadata,
        SQRT($distanceCalc) as distance
      FROM embeddings e
      JOIN vector_index vi ON e.id = vi.embedding_id
      WHERE e.module_id = ?
      GROUP BY e.id
      HAVING distance > 0
      ORDER BY distance ASC
      LIMIT ?
    ''', [moduleId, limit]);

    return results.map((row) => SearchResult(
      embedding: Embedding.fromSqlite(row),
      distance: row['distance'] as double,
    )).toList();
  }
}

/// 搜索结果
class SearchResult {
  final Embedding embedding;
  final double distance;

  SearchResult({
    required this.embedding,
    required this.distance,
  });

  /// 计算相似度得分 (0-1)
  double get similarity => 1.0 / (1.0 + distance);
}