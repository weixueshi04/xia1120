import 'dart:convert';

/// 任务奖励
class TaskRewards {
  final int exp;
  final int coins;
  final String? achievement;

  TaskRewards({
    required this.exp,
    required this.coins,
    this.achievement,
  });

  factory TaskRewards.fromJson(Map<String, dynamic> json) {
    return TaskRewards(
      exp: json['exp'] as int,
      coins: json['coins'] as int,
      achievement: json['achievement'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exp': exp,
      'coins': coins,
      if (achievement != null) 'achievement': achievement,
    };
  }
}

/// 任务模型
class Task {
  final int id;
  final String title;
  final String description;
  final String role; // archivist, designer, operator
  final String difficulty; // 初级, 中级, 高级
  final int exp;
  final List<String> steps;
  final TaskRewards rewards;
  final String estimatedTime;
  final String category;
  final String status; // available, locked, in_progress, completed

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.role,
    required this.difficulty,
    required this.exp,
    required this.steps,
    required this.rewards,
    required this.estimatedTime,
    required this.category,
    required this.status,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      role: json['role'] as String,
      difficulty: json['difficulty'] as String,
      exp: json['exp'] as int,
      steps: (json['steps'] as List<dynamic>).map((e) => e.toString()).toList(),
      rewards: TaskRewards.fromJson(json['rewards'] as Map<String, dynamic>),
      estimatedTime: json['estimatedTime'] as String,
      category: json['category'] as String,
      status: json['status'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'role': role,
      'difficulty': difficulty,
      'exp': exp,
      'steps': steps,
      'rewards': rewards.toJson(),
      'estimatedTime': estimatedTime,
      'category': category,
      'status': status,
    };
  }

  /// 复制任务并更新状态
  Task copyWith({String? status}) {
    return Task(
      id: id,
      title: title,
      description: description,
      role: role,
      difficulty: difficulty,
      exp: exp,
      steps: steps,
      rewards: rewards,
      estimatedTime: estimatedTime,
      category: category,
      status: status ?? this.status,
    );
  }
}

/// 任务集合
class TaskCollection {
  final List<Task> tasks;

  TaskCollection({required this.tasks});

  factory TaskCollection.fromJson(Map<String, dynamic> json) {
    return TaskCollection(
      tasks: (json['tasks'] as List<dynamic>)
          .map((item) => Task.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  factory TaskCollection.fromJsonString(String jsonString) {
    final Map<String, dynamic> json = jsonDecode(jsonString);
    return TaskCollection.fromJson(json);
  }

  /// 按角色筛选
  List<Task> getByRole(String role) {
    return tasks.where((t) => t.role == role).toList();
  }

  /// 按难度筛选
  List<Task> getByDifficulty(String difficulty) {
    return tasks.where((t) => t.difficulty == difficulty).toList();
  }

  /// 获取可用任务
  List<Task> getAvailableTasks() {
    return tasks.where((t) => t.status == 'available').toList();
  }

  /// 获取进行中的任务
  List<Task> getInProgressTasks() {
    return tasks.where((t) => t.status == 'in_progress').toList();
  }

  /// 获取已完成的任务
  List<Task> getCompletedTasks() {
    return tasks.where((t) => t.status == 'completed').toList();
  }
}
