import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/theme.dart';
import '../models/knowledge.dart';
import '../models/user_progress.dart';

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
  KnowledgeBase? _knowledgeBase;
  UserProgress? _userProgress;
  List<Knowledge> _allItems = [];
  List<Knowledge> _filteredItems = [];
  String _selectedCategory = '全部';
  String _searchQuery = '';
  bool _isLoading = true;
  bool _showFavoritesOnly = false;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // 加载知识库
      final knowledgeJson =
          await rootBundle.loadString('assets/data/knowledge.json');
      _knowledgeBase = KnowledgeBase.fromJsonString(knowledgeJson);
      _allItems = _knowledgeBase!.knowledge;

      // 加载用户进度
      final prefs = await SharedPreferences.getInstance();
      final progressJson = prefs.getString('user_progress');
      if (progressJson != null) {
        _userProgress = UserProgress.fromJsonString(progressJson);
      } else {
        _userProgress = UserProgress();
      }

      _applyFilters();
    } catch (e) {
      debugPrint('加载数据失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载数据失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveUserProgress() async {
    if (_userProgress == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_progress', _userProgress!.toJsonString());
  }

  void _applyFilters() {
    List<Knowledge> filtered = List.from(_allItems);

    // 分类筛选
    if (_selectedCategory != '全部') {
      filtered =
          filtered.where((item) => item.category == _selectedCategory).toList();
    }

    // 搜索筛选
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((item) {
        return item.question.toLowerCase().contains(query) ||
            item.answer.toLowerCase().contains(query) ||
            item.keywords.any((k) => k.toLowerCase().contains(query));
      }).toList();
    }

    // 收藏筛选
    if (_showFavoritesOnly && _userProgress != null) {
      filtered = filtered
          .where((item) => _userProgress!.favoriteKnowledgeIds.contains(item.id))
          .toList();
    }

    setState(() {
      _filteredItems = filtered;
    });
  }

  List<String> get _categories {
    if (_knowledgeBase == null) return ['全部'];
    final categories = _knowledgeBase!.getAllCategories();
    return ['全部', ...categories];
  }

  void _toggleFavorite(Knowledge item) {
    if (_userProgress == null) return;

    setState(() {
      _userProgress!.toggleFavoriteKnowledge(item.id);
    });
    _saveUserProgress();

    final isFavorited = _userProgress!.favoriteKnowledgeIds.contains(item.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isFavorited ? '已收藏到我的档案' : '已取消收藏'),
        duration: const Duration(seconds: 1),
      ),
    );

    // 如果在收藏模式下取消收藏，需要刷新列表
    if (_showFavoritesOnly) {
      _applyFilters();
    }
  }

  bool _isFavorited(Knowledge item) {
    return _userProgress?.favoriteKnowledgeIds.contains(item.id) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildSearchBar(),
                _buildCategoryFilter(),
                Expanded(child: _buildLibraryGrid()),
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
          icon: Icon(
            _showFavoritesOnly ? Icons.favorite : Icons.favorite_border,
            color: _showFavoritesOnly ? Colors.red : Colors.white,
          ),
          onPressed: () {
            setState(() {
              _showFavoritesOnly = !_showFavoritesOnly;
            });
            _applyFilters();
          },
          tooltip: _showFavoritesOnly ? '显示全部' : '仅看收藏',
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: '搜索非遗档案、关键词...',
          prefixIcon: const Icon(Icons.search, color: MiaoTheme.indigoDye),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                    _applyFilters();
                  },
                )
              : null,
          filled: true,
          fillColor: MiaoTheme.waxWhite,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        onChanged: (value) {
          setState(() => _searchQuery = value);
          _applyFilters();
        },
      ),
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
                  _applyFilters();
                },
                backgroundColor: Colors.white,
                selectedColor:
                    MiaoTheme.indigoDye.withAlpha((0.15 * 255).round()),
                labelStyle: TextStyle(
                  color:
                      isSelected ? MiaoTheme.indigoDye : MiaoTheme.silverThread,
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
              _showFavoritesOnly
                  ? '还没有收藏任何档案\n快去探索非遗宝库吧！'
                  : (_searchQuery.isNotEmpty ? '没有找到相关档案' : '暂无档案'),
              style: TextStyle(
                fontSize: 16,
                color: MiaoTheme.silverThread.withAlpha((0.7 * 255).round()),
              ),
              textAlign: TextAlign.center,
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
    final isFav = _isFavorited(item);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          _showDetailDialog(item);
          // 记录阅读
          if (_userProgress != null) {
            _userProgress!.readKnowledge(item.id);
            _saveUserProgress();
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Padding(
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
                          color:
                              MiaoTheme.indigoDye.withAlpha((0.1 * 255).round()),
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: MiaoTheme.scholarGold
                              .withAlpha((0.2 * 255).round()),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          item.category,
                          style: TextStyle(
                            fontSize: 10,
                            color: MiaoTheme.scholarGold
                                .withAlpha((0.9 * 255).round()),
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
                        color:
                            MiaoTheme.silverThread.withAlpha((0.8 * 255).round()),
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: MiaoTheme.waxWhite,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: MiaoTheme.indigoDye
                                .withAlpha((0.2 * 255).round()),
                          ),
                        ),
                        child: Text(
                          keyword,
                          style: TextStyle(
                            fontSize: 10,
                            color: MiaoTheme.indigoDye
                                .withAlpha((0.7 * 255).round()),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            // 收藏按钮
            Positioned(
              top: 8,
              right: 8,
              child: InkWell(
                onTap: () => _toggleFavorite(item),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha((0.9 * 255).round()),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isFav ? Icons.favorite : Icons.favorite_border,
                    color: isFav ? Colors.red : MiaoTheme.silverThread,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    if (category.contains('非遗') || category.contains('文化')) {
      return Icons.palette;
    } else if (category.contains('人物') || category.contains('故事')) {
      return Icons.person;
    } else if (category.contains('节') || category.contains('民俗')) {
      return Icons.festival;
    } else if (category.contains('商业') || category.contains('模式')) {
      return Icons.business_center;
    } else if (category.contains('历史')) {
      return Icons.history_edu;
    }
    return Icons.article;
  }

  void _showDetailDialog(Knowledge item) {
    final isFav = _isFavorited(item);

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
              _toggleFavorite(item);
              Navigator.pop(context);
            },
            icon: Icon(isFav ? Icons.favorite : Icons.favorite_border, size: 16),
            label: Text(isFav ? '取消收藏' : '收藏'),
          ),
        ],
      ),
    );
  }
}
