import 'dart:convert';
import 'package:flutter/services.dart';

import '../models/task.dart';
import '../models/achievement.dart';
import '../models/user_progress.dart';
import 'local_storage_service.dart';

/// 任务系统服务
/// 管理任务、成就和用户进度
class TaskService {
  static final TaskService _instance = TaskService._internal();
  factory TaskService() => _instance;
  TaskService._internal();

  final LocalStorageService _storage = LocalStorageService();

  TaskCollection? _taskCollection;
  AchievementCollection? _achievementCollection;
  UserProgress? _userProgress;

  bool _isInitialized = false;

  /// 初始化任务系统
  Future<void> initialize() async {
    if (_isInitialized) return;

    // 加载任务数据
    await _loadTasks();
    // 加载成就数据
    await _loadAchievements();
    // 加载用户进度
    await _loadUserProgress();

    _isInitialized = true;
  }

  /// 加载任务数据
  Future<void> _loadTasks() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/data/tasks.json');
      _taskCollection = TaskCollection.fromJsonString(jsonString);

      // 从本地存储加载任务状态
      final savedTaskStatus = await _storage.getData<Map<String, dynamic>>('task_status');
      if (savedTaskStatus != null) {
        for (int i = 0; i < _taskCollection!.tasks.length; i++) {
          final taskId = _taskCollection!.tasks[i].id.toString();
          if (savedTaskStatus.containsKey(taskId)) {
            _taskCollection!.tasks[i] = _taskCollection!.tasks[i].copyWith(
              status: savedTaskStatus[taskId] as String,
            );
          }
        }
      }
    } catch (e) {
      print('加载任务数据失败: $e');
      // 创建默认任务集合
      _taskCollection = TaskCollection(tasks: _getDefaultTasks());
    }
  }

  /// 加载成就数据
  Future<void> _loadAchievements() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/data/achievements.json');
      _achievementCollection = AchievementCollection.fromJsonString(jsonString);

      // 从用户进度中恢复已解锁的成就
      if (_userProgress != null) {
        for (int i = 0; i < _achievementCollection!.achievements.length; i++) {
          final achievement = _achievementCollection!.achievements[i];
          if (_userProgress!.unlockedAchievementIds.contains(achievement.id)) {
            _achievementCollection!.achievements[i] = achievement.unlock();
          }
        }
      }
    } catch (e) {
      print('加载成就数据失败: $e');
      // 创建默认成就集合
      _achievementCollection = AchievementCollection(
        achievements: _getDefaultAchievements(),
        rarityColors: {
          '普通': '#95A5A6',
          '稀有': '#3498DB',
          '史诗': '#9B59B6',
          '传说': '#F39C12',
        },
      );
    }
  }

  /// 加载用户进度
  Future<void> _loadUserProgress() async {
    final data = await _storage.getData<Map<String, dynamic>>('user_progress');
    if (data != null) {
      _userProgress = UserProgress.fromJson(data);
      _userProgress!.checkLogin(); // 检查并更新登录天数
    } else {
      _userProgress = UserProgress();
    }
    await _saveUserProgress();
  }

  /// 保存用户进度
  Future<void> _saveUserProgress() async {
    if (_userProgress != null) {
      await _storage.saveData('user_progress', _userProgress!.toJson());
    }
  }

  /// 保存任务状态
  Future<void> _saveTaskStatus() async {
    if (_taskCollection != null) {
      final Map<String, String> taskStatus = {};
      for (final task in _taskCollection!.tasks) {
        taskStatus[task.id.toString()] = task.status;
      }
      await _storage.saveData('task_status', taskStatus);
    }
  }

  /// 获取用户进度
  UserProgress get userProgress => _userProgress ?? UserProgress();

  /// 获取所有任务
  List<Task> getAllTasks() {
    return _taskCollection?.tasks ?? [];
  }

  /// 获取指定角色的任务
  List<Task> getTasksByRole(String role) {
    return _taskCollection?.getByRole(role) ?? [];
  }

  /// 获取可用任务
  List<Task> getAvailableTasks() {
    return _taskCollection?.getAvailableTasks() ?? [];
  }

  /// 获取进行中的任务
  List<Task> getInProgressTasks() {
    return _taskCollection?.getInProgressTasks() ?? [];
  }

  /// 获取已完成的任务
  List<Task> getCompletedTasks() {
    return _taskCollection?.getCompletedTasks() ?? [];
  }

  /// 开始任务
  Future<void> startTask(int taskId) async {
    if (_taskCollection == null) return;

    final index = _taskCollection!.tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      _taskCollection!.tasks[index] = _taskCollection!.tasks[index].copyWith(
        status: 'in_progress',
      );
      await _saveTaskStatus();
    }
  }

  /// 完成任务
  Future<void> completeTask(int taskId) async {
    if (_taskCollection == null || _userProgress == null) return;

    final index = _taskCollection!.tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      final task = _taskCollection!.tasks[index];

      // 更新任务状态
      _taskCollection!.tasks[index] = task.copyWith(status: 'completed');

      // 奖励用户
      _userProgress!.completeTask(
        taskId,
        task.rewards.exp,
        task.rewards.coins,
      );

      // 检查成就
      await _checkAchievements();

      await _saveTaskStatus();
      await _saveUserProgress();
    }
  }

  /// 获取所有成就
  List<Achievement> getAllAchievements() {
    return _achievementCollection?.achievements ?? [];
  }

  /// 获取已解锁的成就
  List<Achievement> getUnlockedAchievements() {
    return _achievementCollection?.getUnlockedAchievements() ?? [];
  }

  /// 获取未解锁的成就
  List<Achievement> getLockedAchievements() {
    return _achievementCollection?.getLockedAchievements() ?? [];
  }

  /// 检查并解锁成就
  Future<List<Achievement>> _checkAchievements() async {
    if (_achievementCollection == null || _userProgress == null) {
      return [];
    }

    final newlyUnlocked = <Achievement>[];

    for (int i = 0; i < _achievementCollection!.achievements.length; i++) {
      final achievement = _achievementCollection!.achievements[i];

      if (achievement.unlocked) continue;

      bool shouldUnlock = false;

      // 检查成就条件
      switch (achievement.condition) {
        case 'complete_first_task':
          shouldUnlock = _userProgress!.completedTaskIds.isNotEmpty;
          break;
        case 'complete_5_tasks':
          shouldUnlock = _userProgress!.completedTaskIds.length >= 5;
          break;
        case 'complete_10_tasks':
          shouldUnlock = _userProgress!.completedTaskIds.length >= 10;
          break;
        case 'reach_level_5':
          shouldUnlock = _userProgress!.level >= 5;
          break;
        case 'reach_level_10':
          shouldUnlock = _userProgress!.level >= 10;
          break;
        case 'consecutive_login_7':
          shouldUnlock = _userProgress!.consecutiveLoginDays >= 7;
          break;
        case 'favorite_5_knowledge':
          shouldUnlock = _userProgress!.favoriteKnowledgeIds.length >= 5;
          break;
        case 'favorite_5_products':
          shouldUnlock = _userProgress!.favoriteProductIds.length >= 5;
          break;
      }

      if (shouldUnlock) {
        _achievementCollection!.achievements[i] = achievement.unlock();
        _userProgress!.unlockAchievement(achievement.id, achievement.exp);
        newlyUnlocked.add(_achievementCollection!.achievements[i]);
      }
    }

    if (newlyUnlocked.isNotEmpty) {
      await _saveUserProgress();
    }

    return newlyUnlocked;
  }

  /// 切换角色
  Future<void> changeRole(String role) async {
    if (_userProgress != null) {
      _userProgress!.currentRole = role;
      await _saveUserProgress();
    }
  }

  /// 获取成就进度
  double getAchievementProgress() {
    return _achievementCollection?.getProgress() ?? 0.0;
  }

  /// 获取默认任务（当assets文件不存在时）
  List<Task> _getDefaultTasks() {
    return [
      Task(
        id: 1,
        title: '完成第一次档案采集',
        description: '学习如何使用数字档案系统,记录你的第一份非遗资料',
        role: 'archivist',
        difficulty: '初级',
        exp: 50,
        steps: ['打开非遗档案整理游戏', '选择一个档案进行整理', '完成档案分类'],
        rewards: TaskRewards(exp: 50, coins: 10),
        estimatedTime: '10分钟',
        category: '档案管理',
        status: 'available',
      ),
      Task(
        id: 2,
        title: '使用AI设计文创产品',
        description: '体验AI辅助设计,创作你的第一件文创产品',
        role: 'designer',
        difficulty: '初级',
        exp: 50,
        steps: ['打开AI设计助手', '描述你想设计的产品', '生成设计方案'],
        rewards: TaskRewards(exp: 50, coins: 10),
        estimatedTime: '15分钟',
        category: 'AI设计',
        status: 'available',
      ),
      Task(
        id: 3,
        title: '策划研学路线',
        description: '设计一条麻江非遗体验路线',
        role: 'operator',
        difficulty: '中级',
        exp: 100,
        steps: ['了解麻江非遗景点', '规划游览顺序', '添加体验活动'],
        rewards: TaskRewards(exp: 100, coins: 20),
        estimatedTime: '30分钟',
        category: '活动策划',
        status: 'available',
      ),
    ];
  }

  /// 获取默认成就（当assets文件不存在时）
  List<Achievement> _getDefaultAchievements() {
    return [
      Achievement(
        id: 1,
        name: '初次尝试',
        description: '完成第一个任务',
        icon: '🌟',
        category: '任务',
        condition: 'complete_first_task',
        exp: 20,
        rarity: '普通',
      ),
      Achievement(
        id: 2,
        name: '勤奋学习者',
        description: '完成5个任务',
        icon: '📚',
        category: '任务',
        condition: 'complete_5_tasks',
        exp: 50,
        rarity: '稀有',
      ),
      Achievement(
        id: 3,
        name: '成长达人',
        description: '达到等级5',
        icon: '⭐',
        category: '成长',
        condition: 'reach_level_5',
        exp: 100,
        rarity: '史诗',
      ),
      Achievement(
        id: 4,
        name: '坚持不懈',
        description: '连续登录7天',
        icon: '🔥',
        category: '日常',
        condition: 'consecutive_login_7',
        exp: 80,
        rarity: '稀有',
      ),
    ];
  }

  /// 添加收藏档案
  Future<void> toggleFavoriteKnowledge(int knowledgeId) async {
    if (_userProgress != null) {
      _userProgress!.toggleFavoriteKnowledge(knowledgeId);
      await _checkAchievements();
      await _saveUserProgress();
    }
  }

  /// 添加收藏产品
  Future<void> toggleFavoriteProduct(int productId) async {
    if (_userProgress != null) {
      _userProgress!.toggleFavoriteProduct(productId);
      await _checkAchievements();
      await _saveUserProgress();
    }
  }

  /// 阅读档案
  Future<void> readKnowledge(int knowledgeId) async {
    if (_userProgress != null) {
      _userProgress!.readKnowledge(knowledgeId);
      await _saveUserProgress();
    }
  }
}
