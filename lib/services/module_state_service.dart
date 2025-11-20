import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/module_metadata.dart';
import '../utils/logger.dart';

/// 模块元数据持久化服务
class ModuleStateService {
  static const String _moduleIdsKey = 'module_ids';
  late SharedPreferences _prefs;
  
  // 单例模式
  static final ModuleStateService _instance = ModuleStateService._internal();
  factory ModuleStateService() => _instance;
  ModuleStateService._internal();

  /// 初始化服务
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// 保存模块元数据
  Future<void> saveModuleMetadata(ModuleMetadata metadata) async {
    // 1. 保存模块ID到列表
    final moduleIds = _getModuleIds();
    if (!moduleIds.contains(metadata.id)) {
      moduleIds.add(metadata.id);
      await _prefs.setStringList(_moduleIdsKey, moduleIds);
    }

    // 2. 保存模块元数据
    final key = ModuleMetadata.storageKey(metadata.id);
    await _prefs.setString(key, jsonEncode(metadata.toJson()));
  }

  /// 读取模块元数据
  Future<ModuleMetadata?> getModuleMetadata(String moduleId) async {
    final key = ModuleMetadata.storageKey(moduleId);
    final json = _prefs.getString(key);
    if (json == null) return null;

    try {
      return ModuleMetadata.fromJson(jsonDecode(json));
    } catch (e, st) {
      Logger.error('Error parsing module metadata', error: e, stackTrace: st);
      return null;
    }
  }

  /// 获取所有模块元数据
  Future<List<ModuleMetadata>> getAllModuleMetadata() async {
    final moduleIds = _getModuleIds();
    final List<ModuleMetadata> result = [];

    for (final id in moduleIds) {
      final metadata = await getModuleMetadata(id);
      if (metadata != null) {
        result.add(metadata);
      }
    }

    return result;
  }

  /// 更新模块状态
  Future<void> updateModuleState(
    String moduleId, {
    bool? isEnabled,
    bool? isDownloaded,
    String? localPath,
  }) async {
    final metadata = await getModuleMetadata(moduleId);
    if (metadata == null) return;

    if (isEnabled != null) metadata.isEnabled = isEnabled;
    if (isDownloaded != null) metadata.isDownloaded = isDownloaded;
    if (localPath != null) metadata.localPath = localPath;
    metadata.lastUpdated = DateTime.now();

    await saveModuleMetadata(metadata);
  }

  /// 删除模块元数据
  Future<void> deleteModuleMetadata(String moduleId) async {
    // 1. 从ID列表中移除
    final moduleIds = _getModuleIds();
    moduleIds.remove(moduleId);
    await _prefs.setStringList(_moduleIdsKey, moduleIds);

    // 2. 删除元数据
    final key = ModuleMetadata.storageKey(moduleId);
    await _prefs.remove(key);
  }

  /// 获取已启用的模块列表
  Future<List<ModuleMetadata>> getEnabledModules() async {
    final allModules = await getAllModuleMetadata();
    return allModules.where((m) => m.isEnabled).toList();
  }

  /// 获取已下载的模块列表
  Future<List<ModuleMetadata>> getDownloadedModules() async {
    final allModules = await getAllModuleMetadata();
    return allModules.where((m) => m.isDownloaded).toList();
  }

  // 私有辅助方法：获取所有模块ID
  List<String> _getModuleIds() {
    return _prefs.getStringList(_moduleIdsKey) ?? [];
  }
}