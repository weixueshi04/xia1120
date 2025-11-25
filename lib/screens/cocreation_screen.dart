import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../services/task_service.dart';
import '../models/task.dart';
import '../models/achievement.dart';
import '../models/user_progress.dart';
import 'game_book_filing_screen.dart';
import 'game_farm_management_screen.dart';

/// 共创 - 任务系统/能力成长
/// 功能:
/// 1. 大学生角色选择(数字采撷者/AI设计师/新媒体运营)
/// 2. 任务系统
/// 3. 成长等级和成就
/// 4. 学习资源
class CocreationScreen extends StatefulWidget {
  const CocreationScreen({super.key});

  @override
  State<CocreationScreen> createState() => _CocreationScreenState();
}

class _CocreationScreenState extends State<CocreationScreen>
    with SingleTickerProviderStateMixin {
  final TaskService _taskService = TaskService();
  late TabController _tabController;
  bool _isLoading = true;
  UserProgress? _userProgress;

  final List<Map<String, dynamic>> _roles = [
    {
      'id': 'archivist',
      'name': '数字采撷者',
      'description': '记录非遗技艺,建设数字档案',
      'icon': Icons.folder_special,
      'color': MiaoTheme.indigoDye,
      'tasks': ['采集非遗故事', '整理档案资料', '录入知识库'],
    },
    {
      'id': 'designer',
      'name': 'AI辅助设计师',
      'description': '用AI共创文创产品',
      'icon': Icons.palette,
      'color': MiaoTheme.scholarGold,
      'tasks': ['设计文创产品', '优化产品方案', '撰写产品文案'],
    },
    {
      'id': 'operator',
      'name': '新媒体运营者',
      'description': '策划体验活动,运营传播',
      'icon': Icons.campaign,
      'color': MiaoTheme.mapleRed,
      'tasks': ['设计研学路线', '撰写营销脚本', '制作宣传内容'],
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await _taskService.initialize();
    setState(() {
      _userProgress = _taskService.userProgress;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildUserProgressCard(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTasksTab(),
                _buildAchievementsTab(),
                _buildGamesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              MiaoTheme.scholarGold,
              MiaoTheme.scholarGold.withAlpha((0.8 * 255).round()),
            ],
          ),
        ),
      ),
      title: const Row(
        children: [
          Icon(Icons.emoji_events, size: 24),
          SizedBox(width: 8),
          Text('游戏打榜'),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadData,
          tooltip: '刷新',
        ),
      ],
    );
  }

  Widget _buildUserProgressCard() {
    if (_userProgress == null) return const SizedBox.shrink();

    final progress = _userProgress!.getLevelProgress();
    final currentRole = _roles.firstWhere(
      (r) => r['id'] == _userProgress!.currentRole,
      orElse: () => _roles[0],
    );

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            (currentRole['color'] as Color).withAlpha((0.1 * 255).round()),
            MiaoTheme.waxWhite,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (currentRole['color'] as Color).withAlpha((0.3 * 255).round()),
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: (currentRole['color'] as Color)
                        .withAlpha((0.2 * 255).round()),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    currentRole['icon'] as IconData,
                    color: currentRole['color'] as Color,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Lv.${_userProgress!.level}',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: currentRole['color'] as Color,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _userProgress!.getLevelTitle(),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: MiaoTheme.indigoDye,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currentRole['name'] as String,
                        style: TextStyle(
                          fontSize: 14,
                          color: MiaoTheme.silverThread
                              .withAlpha((0.8 * 255).round()),
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => _showRoleSelectionDialog(),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: (currentRole['color'] as Color)
                          .withAlpha((0.15 * 255).round()),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '切换角色',
                          style: TextStyle(
                            fontSize: 12,
                            color: currentRole['color'] as Color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.swap_horiz,
                          size: 16,
                          color: currentRole['color'] as Color,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '经验值',
                            style: TextStyle(
                              fontSize: 12,
                              color: MiaoTheme.silverThread
                                  .withAlpha((0.7 * 255).round()),
                            ),
                          ),
                          Text(
                            '${_userProgress!.exp} / ${_userProgress!.getTotalExpForLevel(_userProgress!.level + 1)}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: MiaoTheme.scholarGold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          backgroundColor: MiaoTheme.waxWhite,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            currentRole['color'] as Color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildStatItem(
                  Icons.assignment_turned_in,
                  '已完成',
                  _userProgress!.completedTaskIds.length.toString(),
                  MiaoTheme.indigoDye,
                ),
                const SizedBox(width: 16),
                _buildStatItem(
                  Icons.emoji_events,
                  '成就',
                  _userProgress!.unlockedAchievementIds.length.toString(),
                  MiaoTheme.scholarGold,
                ),
                const SizedBox(width: 16),
                _buildStatItem(
                  Icons.local_fire_department,
                  '连续登录',
                  '${_userProgress!.consecutiveLoginDays}天',
                  MiaoTheme.mapleRed,
                ),
                const Spacer(),
                _buildStatItem(
                  Icons.monetization_on,
                  '金币',
                  _userProgress!.coins.toString(),
                  MiaoTheme.scholarGold,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: MiaoTheme.silverThread.withAlpha((0.7 * 255).round()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: MiaoTheme.waxWhite,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: MiaoTheme.scholarGold.withAlpha((0.2 * 255).round()),
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: MiaoTheme.scholarGold,
        unselectedLabelColor: MiaoTheme.silverThread,
        tabs: const [
          Tab(text: '任务'),
          Tab(text: '成就'),
          Tab(text: '实践'),
        ],
      ),
    );
  }

  Widget _buildTasksTab() {
    final tasks = _taskService.getTasksByRole(_userProgress!.currentRole);
    final availableTasks = tasks.where((t) => t.status == 'available').toList();
    final inProgressTasks =
        tasks.where((t) => t.status == 'in_progress').toList();
    final completedTasks = tasks.where((t) => t.status == 'completed').toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (inProgressTasks.isNotEmpty) ...[
          _buildSectionHeader('进行中', Icons.play_circle_outline, MiaoTheme.scholarGold),
          ...inProgressTasks.map((task) => _buildTaskCard(task)),
          const SizedBox(height: 16),
        ],
        if (availableTasks.isNotEmpty) ...[
          _buildSectionHeader('可接取', Icons.assignment, MiaoTheme.indigoDye),
          ...availableTasks.map((task) => _buildTaskCard(task)),
          const SizedBox(height: 16),
        ],
        if (completedTasks.isNotEmpty) ...[
          _buildSectionHeader('已完成', Icons.check_circle, MiaoTheme.forestGreen),
          ...completedTasks.map((task) => _buildTaskCard(task)),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(Task task) {
    final Color difficultyColor = task.difficulty == '初级'
        ? MiaoTheme.forestGreen
        : task.difficulty == '中级'
            ? MiaoTheme.scholarGold
            : MiaoTheme.mapleRed;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showTaskDetail(task),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: task.status == 'completed'
                            ? MiaoTheme.silverThread
                            : MiaoTheme.indigoDye,
                        decoration: task.status == 'completed'
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: difficultyColor.withAlpha((0.15 * 255).round()),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      task.difficulty,
                      style: TextStyle(
                        fontSize: 12,
                        color: difficultyColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                task.description,
                style: TextStyle(
                  fontSize: 13,
                  color: MiaoTheme.silverThread.withAlpha((0.8 * 255).round()),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 16,
                    color: MiaoTheme.silverThread.withAlpha((0.6 * 255).round()),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    task.estimatedTime,
                    style: TextStyle(
                      fontSize: 12,
                      color: MiaoTheme.silverThread.withAlpha((0.6 * 255).round()),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.star_outline,
                    size: 16,
                    color: MiaoTheme.scholarGold.withAlpha((0.8 * 255).round()),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '+${task.exp} EXP',
                    style: const TextStyle(
                      fontSize: 12,
                      color: MiaoTheme.scholarGold,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.monetization_on_outlined,
                    size: 16,
                    color: MiaoTheme.scholarGold.withAlpha((0.8 * 255).round()),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '+${task.rewards.coins}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: MiaoTheme.scholarGold,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  if (task.status == 'completed')
                    const Icon(
                      Icons.check_circle,
                      color: MiaoTheme.forestGreen,
                      size: 24,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAchievementsTab() {
    final achievements = _taskService.getAllAchievements();
    final unlocked = achievements.where((a) => a.unlocked).toList();
    final locked = achievements.where((a) => !a.unlocked).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildAchievementProgress(achievements),
        const SizedBox(height: 16),
        if (unlocked.isNotEmpty) ...[
          _buildSectionHeader(
            '已解锁 (${unlocked.length})',
            Icons.emoji_events,
            MiaoTheme.scholarGold,
          ),
          ...unlocked.map((achievement) => _buildAchievementCard(achievement)),
          const SizedBox(height: 16),
        ],
        if (locked.isNotEmpty) ...[
          _buildSectionHeader(
            '未解锁 (${locked.length})',
            Icons.lock_outline,
            MiaoTheme.silverThread,
          ),
          ...locked.map((achievement) => _buildAchievementCard(achievement)),
        ],
      ],
    );
  }

  Widget _buildAchievementProgress(List<Achievement> achievements) {
    final unlockedCount = achievements.where((a) => a.unlocked).length;
    final totalCount = achievements.length;
    final progress = totalCount > 0 ? unlockedCount / totalCount : 0.0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.emoji_events,
                  color: MiaoTheme.scholarGold,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '成就收集进度',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: MiaoTheme.indigoDye,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$unlockedCount / $totalCount 已解锁',
                        style: TextStyle(
                          fontSize: 13,
                          color: MiaoTheme.silverThread
                              .withAlpha((0.8 * 255).round()),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${(progress * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: MiaoTheme.scholarGold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: MiaoTheme.waxWhite,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  MiaoTheme.scholarGold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementCard(Achievement achievement) {
    final Color rarityColor = _getRarityColor(achievement.rarity);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: achievement.unlocked ? 2 : 1,
      color: achievement.unlocked ? null : Colors.grey[100],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: achievement.unlocked
              ? rarityColor.withAlpha((0.3 * 255).round())
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: achievement.unlocked
                    ? rarityColor.withAlpha((0.15 * 255).round())
                    : Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  achievement.icon,
                  style: TextStyle(
                    fontSize: 32,
                    color: achievement.unlocked ? null : Colors.grey,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          achievement.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: achievement.unlocked
                                ? MiaoTheme.indigoDye
                                : MiaoTheme.silverThread,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: rarityColor.withAlpha((0.15 * 255).round()),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          achievement.rarity,
                          style: TextStyle(
                            fontSize: 11,
                            color: rarityColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    achievement.description,
                    style: TextStyle(
                      fontSize: 13,
                      color: MiaoTheme.silverThread
                          .withAlpha((0.8 * 255).round()),
                    ),
                  ),
                  if (achievement.unlocked && achievement.unlockedAt != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      '解锁时间: ${achievement.unlockedAt!.month}月${achievement.unlockedAt!.day}日',
                      style: TextStyle(
                        fontSize: 11,
                        color: MiaoTheme.scholarGold
                            .withAlpha((0.8 * 255).round()),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRarityColor(String rarity) {
    switch (rarity) {
      case '稀有':
        return const Color(0xFF3498DB);
      case '史诗':
        return const Color(0xFF9B59B6);
      case '传说':
        return const Color(0xFFF39C12);
      default:
        return const Color(0xFF95A5A6);
    }
  }

  Widget _buildGamesTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          '实践游戏',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: MiaoTheme.indigoDye,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          '通过游戏化体验，深入了解非遗文化，完成实践任务',
          style: TextStyle(
            fontSize: 13,
            color: MiaoTheme.silverThread,
          ),
        ),
        const SizedBox(height: 16),
        _buildGameCard(
          title: '非遗档案整理',
          description: '和夏同龢一起建设数字基因库',
          icon: Icons.folder_special,
          color: MiaoTheme.indigoDye,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const GameBookFilingScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        _buildGameCard(
          title: '麻江非遗小镇',
          description: '平衡工坊、体验、社区收益',
          icon: Icons.villa,
          color: MiaoTheme.mapleRed,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const GameFarmManagementScreen(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildGameCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withAlpha((0.1 * 255).round()),
                Colors.white,
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withAlpha((0.2 * 255).round()),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: color, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 14,
                          color: MiaoTheme.silverThread
                              .withAlpha((0.8 * 255).round()),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.play_circle_filled,
                  size: 48,
                  color: color.withAlpha((0.6 * 255).round()),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showRoleSelectionDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择角色'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _roles.map((role) {
            final isSelected = role['id'] == _userProgress!.currentRole;
            return Card(
              elevation: isSelected ? 3 : 1,
              color: isSelected
                  ? (role['color'] as Color).withAlpha((0.1 * 255).round())
                  : null,
              child: ListTile(
                leading: Icon(
                  role['icon'] as IconData,
                  color: role['color'] as Color,
                ),
                title: Text(role['name'] as String),
                subtitle: Text(role['description'] as String),
                trailing: isSelected
                    ? Icon(
                        Icons.check_circle,
                        color: role['color'] as Color,
                      )
                    : null,
                onTap: () async {
                  await _taskService.changeRole(role['id'] as String);
                  setState(() {
                    _userProgress = _taskService.userProgress;
                  });
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('已切换为: ${role['name']}'),
                      ),
                    );
                  }
                },
              ),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  void _showTaskDetail(Task task) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskDetailScreen(
          task: task,
          taskService: _taskService,
          onTaskUpdated: () {
            _loadData();
          },
        ),
      ),
    );
  }
}

/// 任务详情页
class TaskDetailScreen extends StatelessWidget {
  final Task task;
  final TaskService taskService;
  final VoidCallback onTaskUpdated;

  const TaskDetailScreen({
    super.key,
    required this.task,
    required this.taskService,
    required this.onTaskUpdated,
  });

  @override
  Widget build(BuildContext context) {
    final Color difficultyColor = task.difficulty == '初级'
        ? MiaoTheme.forestGreen
        : task.difficulty == '中级'
            ? MiaoTheme.scholarGold
            : MiaoTheme.mapleRed;

    return Scaffold(
      appBar: AppBar(
        title: const Text('任务详情'),
        backgroundColor: difficultyColor,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    difficultyColor.withAlpha((0.15 * 255).round()),
                    Colors.white,
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: difficultyColor.withAlpha((0.2 * 255).round()),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      task.difficulty,
                      style: TextStyle(
                        fontSize: 14,
                        color: difficultyColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    task.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: MiaoTheme.indigoDye,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    task.description,
                    style: TextStyle(
                      fontSize: 15,
                      color: MiaoTheme.silverThread
                          .withAlpha((0.8 * 255).round()),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow(
                    Icons.timer_outlined,
                    '预计时长',
                    task.estimatedTime,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.category_outlined,
                    '任务分类',
                    task.category,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    '任务步骤',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: MiaoTheme.indigoDye,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...task.steps.asMap().entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: difficultyColor
                                  .withAlpha((0.15 * 255).round()),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${entry.key + 1}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: difficultyColor,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                entry.value,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: MiaoTheme.indigoDye,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 24),
                  const Text(
                    '任务奖励',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: MiaoTheme.indigoDye,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          _buildRewardItem(
                            Icons.star,
                            '经验值',
                            '+${task.rewards.exp}',
                            MiaoTheme.scholarGold,
                          ),
                          const SizedBox(width: 24),
                          _buildRewardItem(
                            Icons.monetization_on,
                            '金币',
                            '+${task.rewards.coins}',
                            MiaoTheme.scholarGold,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomActions(context),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: MiaoTheme.silverThread.withAlpha((0.6 * 255).round()),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: MiaoTheme.silverThread.withAlpha((0.8 * 255).round()),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: MiaoTheme.indigoDye,
          ),
        ),
      ],
    );
  }

  Widget _buildRewardItem(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: MiaoTheme.silverThread.withAlpha((0.7 * 255).round()),
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context) {
    if (task.status == 'completed') {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((0.05 * 255).round()),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(
              Icons.check_circle,
              color: MiaoTheme.forestGreen,
              size: 24,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                '任务已完成',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: MiaoTheme.forestGreen,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.05 * 255).round()),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (task.status == 'in_progress')
            Expanded(
              child: FilledButton(
                onPressed: () async {
                  await taskService.completeTask(task.id);
                  onTaskUpdated();
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('任务已完成！')),
                    );
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: MiaoTheme.forestGreen,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  '完成任务',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            )
          else
            Expanded(
              child: FilledButton(
                onPressed: () async {
                  await taskService.startTask(task.id);
                  onTaskUpdated();
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('任务已开始！')),
                    );
                  }
                },
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  '开始任务',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
