import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/knowledge_manifest.dart' hide ModuleMetadata;
import '../models/module_metadata.dart';
import '../services/download_manager.dart';
import '../services/module_state_service.dart';
import '../config/theme.dart';

class ModuleManagerScreen extends StatefulWidget {
  const ModuleManagerScreen({super.key});

  @override
  State<ModuleManagerScreen> createState() => _ModuleManagerScreenState();
}

class _ModuleManagerScreenState extends State<ModuleManagerScreen> {
  KnowledgeManifest? _manifest;
  final DownloadManager _dm = DownloadManager();
  final ModuleStateService _moduleService = ModuleStateService();
  final Map<String, double> _progress = {};
  final Map<String, String?> _status = {};
  final Map<String, ModuleMetadata> _metadata = {};

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _moduleService.initialize();
    await _loadManifest();
  }

  Future<void> _loadManifest() async {
    try {
      // 1. 加载清单文件
      final jsonStr = await rootBundle.loadString('assets/data/manifest.json');
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      final manifest = KnowledgeManifest.fromJson(json);
      
      if (!mounted) return;
      setState(() {
        _manifest = manifest;
      });

      // 2. 加载或创建每个模块的元数据
      for (final m in manifest.modules) {
        await _loadModuleMetadata(m);
        await _refreshModuleStatus(m);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _manifest = null;
      });
      _showError('加载清单失败：$e');
    }
  }

  Future<void> _loadModuleMetadata(KnowledgeModule module) async {
    // 尝试读取已存储的元数据
    var metadata = await _moduleService.getModuleMetadata(module.id);
    
    if (metadata == null) {
      // 如果不存在，创建新的元数据
      metadata = ModuleMetadata(
        id: module.id,
        name: module.name['zh'] ?? module.id,
        version: module.version,
        size: module.size,
        checksum: module.checksum,
        languages: module.name.keys.toList(),
        priority: module.priority.toDouble(),
        dependencies: module.dependencies,
        downloadUrl: module.downloadUrl,
      );
      await _moduleService.saveModuleMetadata(metadata);
    }

    if (!mounted) return;
    setState(() {
      _metadata[module.id] = metadata!;
    });
  }

  Future<void> _refreshModuleStatus(KnowledgeModule module) async {
    try {
      final localFile = await _dm.getLocalModuleFile(module);
      final metadata = _metadata[module.id];
      if (metadata == null) return;

      if (await localFile.exists()) {
        final ok = await _dm.verifyFileChecksum(localFile, module.checksum);
        if (!mounted) return;
        
        // 更新状态
        setState(() {
          _status[module.id] = ok ? '已下载' : '校验失败';
        });
        
        // 更新元数据
        await _moduleService.updateModuleState(
          module.id,
          isDownloaded: ok,
          localPath: ok ? localFile.path : null,
        );
      } else {
        if (!mounted) return;
        setState(() {
          _status[module.id] = '未下载';
        });
        
        // 更新元数据
        await _moduleService.updateModuleState(
          module.id,
          isDownloaded: false,
          localPath: null,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status[module.id] = '未知';
      });
      _showError('刷新状态失败：$e');
    }
  }

  Future<void> _toggleModule(String moduleId, bool enabled) async {
    try {
      await _moduleService.updateModuleState(moduleId, isEnabled: enabled);
      final metadata = await _moduleService.getModuleMetadata(moduleId);
      if (!mounted) return;
      setState(() {
        if (metadata != null) {
          _metadata[moduleId] = metadata;
        }
      });
    } catch (e) {
      _showError('更新状态失败：$e');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _downloadModule(KnowledgeModule module) async {
    setState(() {
      _progress[module.id] = 0.0;
      _status[module.id] = '下载中';
    });

    try {
      final file = await _dm.downloadModule(module, onProgress: (p) {
        setState(() => _progress[module.id] = p);
      });

      final ok = await _dm.verifyFileChecksum(file, module.checksum);
      if (!mounted) return;
      
      setState(() {
        _status[module.id] = ok ? '已下载' : '校验失败';
        _progress[module.id] = 1.0;
      });

      // 更新元数据
      await _moduleService.updateModuleState(
        module.id,
        isDownloaded: ok,
        localPath: ok ? file.path : null,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status[module.id] = '下载失败';
        _progress[module.id] = 0.0;
      });
      _showError('下载失败：$e');
    }
  }

  Future<void> _deleteModule(KnowledgeModule module) async {
    try {
      final localFile = await _dm.getLocalModuleFile(module);
      if (await localFile.exists()) await localFile.delete();
      
      // 删除临时文件
      final part = File('${localFile.path}.part');
      if (await part.exists()) await part.delete();
      
      // 更新元数据
      await _moduleService.updateModuleState(
        module.id,
        isDownloaded: false,
        localPath: null,
      );
      
      await _refreshModuleStatus(module);
    } catch (e) {
      _showError('删除失败：$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                MiaoTheme.indigoDye,
                MiaoTheme.indigoDye.withValues(alpha: 204), // 0.8 * 255
              ],
            ),
          ),
        ),
        title: const Row(
          children: [
            Icon(Icons.storage_rounded),
            SizedBox(width: 8),
            Text('知识模块管理'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadManifest,
            tooltip: '刷新',
          ),
        ],
      ),
      body: _manifest == null
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: _manifest!.modules.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final module = _manifest!.modules[index];
                final prog = _progress[module.id] ?? 0.0;
                final status = _status[module.id] ?? '未知';
                final metadata = _metadata[module.id];
                final isDownloaded = metadata?.isDownloaded ?? false;

                return Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    module.name['zh'] ?? module.id,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '版本: ${module.version} • 大小: ${_formatSize(module.size)}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (metadata != null && isDownloaded)
                              Switch(
                                value: metadata.isEnabled,
                                onChanged: (enabled) => _toggleModule(module.id, enabled),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              status,
                              style: TextStyle(
                                color: _getStatusColor(status),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (!isDownloaded)
                                  ElevatedButton.icon(
                                    onPressed: () => _downloadModule(module),
                                    icon: const Icon(Icons.download),
                                    label: const Text('下载'),
                                  )
                                else
                                  OutlinedButton.icon(
                                    onPressed: () => _deleteModule(module),
                                    icon: const Icon(Icons.delete_outline),
                                    label: const Text('删除'),
                                  ),
                              ],
                            ),
                          ],
                        ),
                        if (prog > 0 && prog < 1)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                LinearProgressIndicator(value: prog),
                                const SizedBox(height: 4),
                                Text(
                                  '${(prog * 100).toStringAsFixed(1)}%',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case '已下载':
        return Colors.green;
      case '下载中':
        return Colors.blue;
      case '未下载':
        return Colors.grey;
      case '校验失败':
      case '下载失败':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    final mb = kb / 1024;
    if (mb < 1024) return '${mb.toStringAsFixed(1)} MB';
    final gb = mb / 1024;
    return '${gb.toStringAsFixed(1)} GB';
  }
}
