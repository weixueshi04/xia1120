import 'package:flutter/material.dart';

import '../config/theme.dart';
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

class _CocreationScreenState extends State<CocreationScreen> {
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildRoleSelection(),
            _buildGameEntries(),
            _buildProgressSection(),
          ],
        ),
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
          Icon(Icons.rocket_launch, size: 24),
          SizedBox(width: 8),
          Text('大学生共创实验室'),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            MiaoTheme.scholarGold.withAlpha((0.1 * 255).round()),
            MiaoTheme.waxWhite,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '选择你的角色,开始共创之旅',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: MiaoTheme.indigoDye,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '通过完成任务积累经验,解锁成就,提升能力',
            style: TextStyle(
              fontSize: 13,
              color: MiaoTheme.silverThread.withAlpha((0.8 * 255).round()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleSelection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '三种角色,三种体验',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: MiaoTheme.indigoDye,
            ),
          ),
          const SizedBox(height: 12),
          ...(_roles.map((role) => _buildRoleCard(role))),
        ],
      ),
    );
  }

  Widget _buildRoleCard(Map<String, dynamic> role) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showRoleDetail(role),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (role['color'] as Color).withAlpha((0.15 * 255).round()),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  role['icon'] as IconData,
                  color: role['color'] as Color,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      role['name'] as String,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: role['color'] as Color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      role['description'] as String,
                      style: TextStyle(
                        fontSize: 13,
                        color: MiaoTheme.silverThread.withAlpha((0.8 * 255).round()),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: MiaoTheme.silverThread.withAlpha((0.5 * 255).round()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameEntries() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '实践游戏',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: MiaoTheme.indigoDye,
            ),
          ),
          const SizedBox(height: 12),
          _buildGameCard(
            title: '非遗档案整理',
            description: '和夏同龢一起建数字基因库',
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
            description: '平衡工坊 / 体验 / 社区收益',
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
      ),
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
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withAlpha((0.15 * 255).round()),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        color: MiaoTheme.silverThread.withAlpha((0.8 * 255).round()),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.play_circle_outline,
                size: 32,
                color: color.withAlpha((0.6 * 255).round()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '我的成长',
            style: TextStyle(
              fontSize: 16,
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
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: MiaoTheme.scholarGold.withAlpha((0.15 * 255).round()),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.star,
                          color: MiaoTheme.scholarGold,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Lv.1 见习采撷者',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: MiaoTheme.indigoDye,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '经验值: 0 / 100',
                              style: TextStyle(
                                fontSize: 13,
                                color: MiaoTheme.silverThread,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: 0.0,
                    backgroundColor: MiaoTheme.waxWhite,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      MiaoTheme.scholarGold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '完成任务和学习可以获得经验值,提升等级解锁更多功能!',
                    style: TextStyle(
                      fontSize: 12,
                      color: MiaoTheme.silverThread,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRoleDetail(Map<String, dynamic> role) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              role['icon'] as IconData,
              color: role['color'] as Color,
            ),
            const SizedBox(width: 8),
            Text(role['name'] as String),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(role['description'] as String),
            const SizedBox(height: 16),
            const Text(
              '主要任务:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...(role['tasks'] as List<String>).map(
              (task) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 16,
                      color: role['color'] as Color,
                    ),
                    const SizedBox(width: 8),
                    Text(task),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('已选择角色: ${role['name']}'),
                ),
              );
            },
            child: const Text('选择此角色'),
          ),
        ],
      ),
    );
  }
}
