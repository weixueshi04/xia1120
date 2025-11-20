import 'dart:convert';

/// 成就模型
class Achievement {
  final int id;
  final String name;
  final String description;
  final String icon;
  final String category;
  final String condition;
  final int exp;
  final String rarity; // 普通, 稀有, 史诗, 传说
  bool unlocked;
  DateTime? unlockedAt;

  Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.category,
    required this.condition,
    required this.exp,
    required this.rarity,
    this.unlocked = false,
    this.unlockedAt,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String,
      icon: json['icon'] as String,
      category: json['category'] as String,
      condition: json['condition'] as String,
      exp: json['exp'] as int,
      rarity: json['rarity'] as String,
      unlocked: json['unlocked'] as bool? ?? false,
      unlockedAt: json['unlockedAt'] != null
          ? DateTime.parse(json['unlockedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'category': category,
      'condition': condition,
      'exp': exp,
      'rarity': rarity,
      'unlocked': unlocked,
      if (unlockedAt != null) 'unlockedAt': unlockedAt!.toIso8601String(),
    };
  }

  /// 解锁成就
  Achievement unlock() {
    return Achievement(
      id: id,
      name: name,
      description: description,
      icon: icon,
      category: category,
      condition: condition,
      exp: exp,
      rarity: rarity,
      unlocked: true,
      unlockedAt: DateTime.now(),
    );
  }
}

/// 成就集合
class AchievementCollection {
  final List<Achievement> achievements;
  final Map<String, String> rarityColors;

  AchievementCollection({
    required this.achievements,
    required this.rarityColors,
  });

  factory AchievementCollection.fromJson(Map<String, dynamic> json) {
    return AchievementCollection(
      achievements: (json['achievements'] as List<dynamic>)
          .map((item) => Achievement.fromJson(item as Map<String, dynamic>))
          .toList(),
      rarityColors: Map<String, String>.from(json['rarityColors'] as Map),
    );
  }

  factory AchievementCollection.fromJsonString(String jsonString) {
    final Map<String, dynamic> json = jsonDecode(jsonString);
    return AchievementCollection.fromJson(json);
  }

  /// 按分类筛选
  List<Achievement> getByCategory(String category) {
    return achievements.where((a) => a.category == category).toList();
  }

  /// 获取已解锁的成就
  List<Achievement> getUnlockedAchievements() {
    return achievements.where((a) => a.unlocked).toList();
  }

  /// 获取未解锁的成就
  List<Achievement> getLockedAchievements() {
    return achievements.where((a) => !a.unlocked).toList();
  }

  /// 按稀有度筛选
  List<Achievement> getByRarity(String rarity) {
    return achievements.where((a) => a.rarity == rarity).toList();
  }

  /// 获取解锁进度
  double getProgress() {
    if (achievements.isEmpty) return 0.0;
    final unlocked = achievements.where((a) => a.unlocked).length;
    return unlocked / achievements.length;
  }

  /// 获取总经验值奖励
  int getTotalExpFromAchievements() {
    return achievements.where((a) => a.unlocked).fold(0, (sum, a) => sum + a.exp);
  }
}
