import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../models/knowledge.dart';
import '../services/local_storage_service.dart';

/// 非遗库 - 技艺/故事/人物档案
/// 功能:
/// 1. 瀑布流展示非遗档案
/// 2. 分类筛选(技艺/故事/人物/节庆)
/// 3. 搜索功能
/// 4. 收藏管理
class HeritageLibraryScreen extends StatefulWidget {
  const HeritageLibraryScreen({super.key});

  @override
  State<HeritageLibraryScreen> createState() => _HeritageLibraryScreenState();
}

class _HeritageLibraryScreenState extends State<HeritageLibraryScreen> {
  final LocalStorageService _storage = LocalStorageService();
  List<Knowledge> _items = [];
  String _selectedCategory = '全部';

  final List<String> _categories = [
    '全部',
    '技艺档案',
    '人物故事',
    '节庆民俗',
    '商业模式',
  ];

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    // TODO: 从知识库加载数据
    // 这里先创建示例数据
    setState(() {
      _items = _generateSampleData();
    });
  }

  List<Knowledge> _generateSampleData() {
    // 示例数据,后续从knowledge.json加载
    return [
      Knowledge(
        id: 1,
        question: '枫香蜡染',
        answer: '麻江传统蓝染技艺,用枫香树脂防染,形成美丽纹样',
        keywords: ['蜡染', '技艺', '麻江'],
        category: '技艺档案',
        synonymQuestions: [],
      ),
      Knowledge(
        id: 2,
        question: '苗族银饰',
        answer: '精美的苗族传统装饰,承载历史记忆与文化传承',
        keywords: ['银饰', '苗族', '技艺'],
        category: '技艺档案',
        synonymQuestions: [],
      ),
      Knowledge(
        id: 3,
        question: '夏同龢',
        answer: '清朝光绪年间状元,贵州麻江人,致力于教育事业',
        keywords: ['状元', '历史', '麻江'],
        category: '人物故事',
        synonymQuestions: [],
      ),
    ];
  }

  List<Knowledge> get _filteredItems {
    if (_selectedCategory == '全部') {
      return _items;
    }
    return _items.where((item) => item.category == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildCategoryFilter(),
          Expanded(
            child: _buildLibraryGrid(),
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
              MiaoTheme.indigoDye,
              MiaoTheme.indigoDye.withAlpha((0.8 * 255).round()),
            ],
          ),
        ),
      ),
      title: const Row(
        children: [
          Icon(Icons.inventory_2, size: 24),
          SizedBox(width: 8),
          Text('麻江非遗数字基因库'),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {
            // TODO: 实现搜索功能
          },
        ),
      ],
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.03 * 255).round()),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _categories.map((category) {
            final isSelected = category == _selectedCategory;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(category),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedCategory = category;
                  });
                },
                backgroundColor: Colors.white,
                selectedColor: MiaoTheme.indigoDye.withAlpha((0.15 * 255).round()),
                labelStyle: TextStyle(
                  color: isSelected ? MiaoTheme.indigoDye : MiaoTheme.silverThread,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildLibraryGrid() {
    if (_filteredItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: MiaoTheme.silverThread.withAlpha((0.5 * 255).round()),
            ),
            const SizedBox(height: 16),
            Text(
              '暂无档案',
              style: TextStyle(
                fontSize: 16,
                color: MiaoTheme.silverThread.withAlpha((0.7 * 255).round()),
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _filteredItems.length,
      itemBuilder: (context, index) {
        final item = _filteredItems[index];
        return _buildLibraryCard(item);
      },
    );
  }

  Widget _buildLibraryCard(Knowledge item) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          _showDetailDialog(item);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 图标和分类
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: MiaoTheme.indigoDye.withAlpha((0.1 * 255).round()),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getCategoryIcon(item.category),
                      color: MiaoTheme.indigoDye,
                      size: 20,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: MiaoTheme.scholarGold.withAlpha((0.2 * 255).round()),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      item.category,
                      style: TextStyle(
                        fontSize: 10,
                        color: MiaoTheme.scholarGold.withAlpha((0.9 * 255).round()),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 标题
              Text(
                item.question,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: MiaoTheme.indigoDye,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              // 内容预览
              Expanded(
                child: Text(
                  item.answer,
                  style: TextStyle(
                    fontSize: 12,
                    color: MiaoTheme.silverThread.withAlpha((0.8 * 255).round()),
                    height: 1.4,
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // 关键词
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: item.keywords.take(3).map((keyword) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: MiaoTheme.waxWhite,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: MiaoTheme.indigoDye.withAlpha((0.2 * 255).round()),
                      ),
                    ),
                    child: Text(
                      keyword,
                      style: TextStyle(
                        fontSize: 10,
                        color: MiaoTheme.indigoDye.withAlpha((0.7 * 255).round()),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case '技艺档案':
        return Icons.palette;
      case '人物故事':
        return Icons.person;
      case '节庆民俗':
        return Icons.festival;
      case '商业模式':
        return Icons.business_center;
      default:
        return Icons.article;
    }
  }

  void _showDetailDialog(Knowledge item) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item.question),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: MiaoTheme.scholarGold.withAlpha((0.2 * 255).round()),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  item.category,
                  style: TextStyle(
                    fontSize: 12,
                    color: MiaoTheme.scholarGold.withAlpha((0.9 * 255).round()),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                item.answer,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
              if (item.keywords.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  '关键词',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: item.keywords.map((keyword) {
                    return Chip(
                      label: Text(
                        keyword,
                        style: const TextStyle(fontSize: 12),
                      ),
                      backgroundColor: MiaoTheme.waxWhite,
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
          FilledButton.icon(
            onPressed: () {
              // TODO: 实现收藏功能
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('已收藏到我的档案')),
              );
            },
            icon: const Icon(Icons.favorite, size: 16),
            label: const Text('收藏'),
          ),
        ],
      ),
    );
  }
}
