import 'dart:convert';

/// 用户进度和成长数据
class UserProgress {
  int exp; // 总经验值
  int level; // 等级
  String currentRole; // 当前选择的角色
  List<int> favoriteKnowledgeIds; // 收藏的非遗档案ID
  List<int> favoriteProductIds; // 收藏的产品ID
  List<int> completedTaskIds; // 已完成的任务ID
  List<int> unlockedAchievementIds; // 已解锁的成就ID
  int coins; // 金币
  int consecutiveLoginDays; // 连续登录天数
  DateTime lastLoginDate; // 最后登录日期
  Map<String, dynamic> statistics; // 统计数据

  UserProgress({
    this.exp = 0,
    this.level = 1,
    this.currentRole = 'archivist',
    List<int>? favoriteKnowledgeIds,
    List<int>? favoriteProductIds,
    List<int>? completedTaskIds,
    List<int>? unlockedAchievementIds,
    this.coins = 0,
    this.consecutiveLoginDays = 0,
    DateTime? lastLoginDate,
    Map<String, dynamic>? statistics,
  })  : favoriteKnowledgeIds = favoriteKnowledgeIds ?? [],
        favoriteProductIds = favoriteProductIds ?? [],
        completedTaskIds = completedTaskIds ?? [],
        unlockedAchievementIds = unlockedAchievementIds ?? [],
        lastLoginDate = lastLoginDate ?? DateTime.now(),
        statistics = statistics ?? {};

  factory UserProgress.fromJson(Map<String, dynamic> json) {
    return UserProgress(
      exp: json['exp'] as int? ?? 0,
      level: json['level'] as int? ?? 1,
      currentRole: json['currentRole'] as String? ?? 'archivist',
      favoriteKnowledgeIds: (json['favoriteKnowledgeIds'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [],
      favoriteProductIds: (json['favoriteProductIds'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [],
      completedTaskIds: (json['completedTaskIds'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [],
      unlockedAchievementIds: (json['unlockedAchievementIds'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [],
      coins: json['coins'] as int? ?? 0,
      consecutiveLoginDays: json['consecutiveLoginDays'] as int? ?? 0,
      lastLoginDate: json['lastLoginDate'] != null
          ? DateTime.parse(json['lastLoginDate'] as String)
          : DateTime.now(),
      statistics: json['statistics'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exp': exp,
      'level': level,
      'currentRole': currentRole,
      'favoriteKnowledgeIds': favoriteKnowledgeIds,
      'favoriteProductIds': favoriteProductIds,
      'completedTaskIds': completedTaskIds,
      'unlockedAchievementIds': unlockedAchievementIds,
      'coins': coins,
      'consecutiveLoginDays': consecutiveLoginDays,
      'lastLoginDate': lastLoginDate.toIso8601String(),
      'statistics': statistics,
    };
  }

  String toJsonString() {
    return jsonEncode(toJson());
  }

  factory UserProgress.fromJsonString(String jsonString) {
    final Map<String, dynamic> json = jsonDecode(jsonString);
    return UserProgress.fromJson(json);
  }

  /// 获取当前等级所需的经验值
  int getExpForLevel(int level) {
    // 等级1: 0-99 (100exp)
    // 等级2: 100-299 (200exp)
    // 等级3: 300-599 (300exp)
    // 等级N: 需要 N*100 exp
    return level * 100;
  }

  /// 获取当前等级的总经验值要求
  int getTotalExpForLevel(int level) {
    int total = 0;
    for (int i = 1; i < level; i++) {
      total += getExpForLevel(i);
    }
    return total;
  }

  /// 获取下一级需要的经验值
  int getExpToNextLevel() {
    final currentLevelTotalExp = getTotalExpForLevel(level);
    final nextLevelTotalExp = getTotalExpForLevel(level + 1);
    return nextLevelTotalExp - exp;
  }

  /// 获取当前等级的进度 (0.0-1.0)
  double getLevelProgress() {
    final currentLevelTotalExp = getTotalExpForLevel(level);
    final nextLevelTotalExp = getTotalExpForLevel(level + 1);
    final currentLevelExp = exp - currentLevelTotalExp;
    final expNeeded = nextLevelTotalExp - currentLevelTotalExp;
    if (expNeeded <= 0) return 1.0;
    return (currentLevelExp / expNeeded).clamp(0.0, 1.0);
  }

  /// 添加经验值并更新等级
  void addExp(int amount) {
    exp += amount;
    _updateLevel();
  }

  /// 更新等级
  void _updateLevel() {
    while (exp >= getTotalExpForLevel(level + 1)) {
      level++;
    }
  }

  /// 添加金币
  void addCoins(int amount) {
    coins += amount;
  }

  /// 完成任务
  void completeTask(int taskId, int expReward, int coinsReward) {
    if (!completedTaskIds.contains(taskId)) {
      completedTaskIds.add(taskId);
      addExp(expReward);
      addCoins(coinsReward);
      _incrementStat('tasksCompleted');
    }
  }

  /// 解锁成就
  void unlockAchievement(int achievementId, int expReward) {
    if (!unlockedAchievementIds.contains(achievementId)) {
      unlockedAchievementIds.add(achievementId);
      addExp(expReward);
      _incrementStat('achievementsUnlocked');
    }
  }

  /// 收藏档案
  void toggleFavoriteKnowledge(int knowledgeId) {
    if (favoriteKnowledgeIds.contains(knowledgeId)) {
      favoriteKnowledgeIds.remove(knowledgeId);
    } else {
      favoriteKnowledgeIds.add(knowledgeId);
      _incrementStat('knowledgeFavorited');
    }
  }

  /// 收藏产品
  void toggleFavoriteProduct(int productId) {
    if (favoriteProductIds.contains(productId)) {
      favoriteProductIds.remove(productId);
    } else {
      favoriteProductIds.add(productId);
      _incrementStat('productsFavorited');
    }
  }

  /// 检查登录并更新连续登录天数
  void checkLogin() {
    final now = DateTime.now();
    final lastLogin = DateTime(
      lastLoginDate.year,
      lastLoginDate.month,
      lastLoginDate.day,
    );
    final today = DateTime(now.year, now.month, now.day);
    final difference = today.difference(lastLogin).inDays;

    if (difference == 0) {
      // 今天已登录
      return;
    } else if (difference == 1) {
      // 连续登录
      consecutiveLoginDays++;
    } else {
      // 断签
      consecutiveLoginDays = 1;
    }
    lastLoginDate = now;
  }

  /// 获取等级称号
  String getLevelTitle() {
    if (level >= 20) return '非遗大师';
    if (level >= 15) return '文化传播者';
    if (level >= 10) return '资深采撷者';
    if (level >= 5) return '优秀采撷者';
    return '见习采撷者';
  }

  /// 增加统计数据
  void _incrementStat(String key) {
    statistics[key] = (statistics[key] as int? ?? 0) + 1;
  }

  /// 获取统计数据
  int getStat(String key) {
    return statistics[key] as int? ?? 0;
  }

  /// 阅读档案
  void readKnowledge(int knowledgeId) {
    _incrementStat('knowledgeRead');
  }
}
