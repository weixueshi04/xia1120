import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/theme.dart';
import '../models/product.dart';
import '../models/user_progress.dart';
import 'product_detail_screen.dart';

/// 文创集 - 产品展示/设计灵感
/// 功能:
/// 1. 文创产品瀑布流展示
/// 2. 设计案例分享
/// 3. AI辅助设计入口
/// 4. 产品收藏
class CreativeMarketScreen extends StatefulWidget {
  const CreativeMarketScreen({super.key});

  @override
  State<CreativeMarketScreen> createState() => _CreativeMarketScreenState();
}

class _CreativeMarketScreenState extends State<CreativeMarketScreen> {
  ProductCatalog? _productCatalog;
  UserProgress? _userProgress;
  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  String _selectedType = '全部';
  bool _isLoading = true;
  bool _showFavoritesOnly = false;

  final List<String> _productTypes = [
    '全部',
    '服饰配件',
    '文具用品',
    '首饰配件',
    '特色食品',
    '生活用品',
    '数码产品',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // 加载产品数据
      final productsJson =
          await rootBundle.loadString('assets/data/products.json');
      _productCatalog = ProductCatalog.fromJsonString(productsJson);
      _allProducts = _productCatalog!.products;

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
      debugPrint('加载产品数据失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载产品数据失败: $e')),
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
    List<Product> filtered = List.from(_allProducts);

    // 类型筛选
    if (_selectedType != '全部') {
      filtered = filtered.where((p) => p.type == _selectedType).toList();
    }

    // 收藏筛选
    if (_showFavoritesOnly && _userProgress != null) {
      filtered = filtered
          .where((p) => _userProgress!.favoriteProductIds.contains(p.id))
          .toList();
    }

    setState(() {
      _filteredProducts = filtered;
    });
  }

  void _toggleFavorite(Product product) {
    if (_userProgress == null) return;

    setState(() {
      _userProgress!.toggleFavoriteProduct(product.id);
    });
    _saveUserProgress();

    final isFavorited = _userProgress!.favoriteProductIds.contains(product.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isFavorited ? '已收藏' : '已取消收藏'),
        duration: const Duration(seconds: 1),
      ),
    );

    if (_showFavoritesOnly) {
      _applyFilters();
    }
  }

  bool _isFavorited(Product product) {
    return _userProgress?.favoriteProductIds.contains(product.id) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildHeader(),
                _buildTypeFilter(),
                Expanded(child: _buildProductGrid()),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAIDesignDialog,
        backgroundColor: MiaoTheme.indigoDye,
        icon: const Icon(Icons.auto_awesome),
        label: const Text('AI 设计助手'),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              MiaoTheme.mapleRed,
              MiaoTheme.mapleRed.withAlpha((0.8 * 255).round()),
            ],
          ),
        ),
      ),
      title: const Row(
        children: [
          Icon(Icons.storefront, size: 24),
          SizedBox(width: 8),
          Text('麻江非遗文创集'),
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

  Widget _buildHeader() {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '将非遗之美融入生活',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: MiaoTheme.indigoDye,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '这里展示大学生与手艺人共创的文创产品',
            style: TextStyle(
              fontSize: 13,
              color: MiaoTheme.silverThread.withAlpha((0.8 * 255).round()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeFilter() {
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
          children: _productTypes.map((type) {
            final isSelected = type == _selectedType;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(type),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedType = type;
                  });
                  _applyFilters();
                },
                backgroundColor: Colors.white,
                selectedColor:
                    MiaoTheme.mapleRed.withAlpha((0.15 * 255).round()),
                labelStyle: TextStyle(
                  color: isSelected ? MiaoTheme.mapleRed : MiaoTheme.silverThread,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildProductGrid() {
    if (_filteredProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: 64,
              color: MiaoTheme.silverThread.withAlpha((0.5 * 255).round()),
            ),
            const SizedBox(height: 16),
            Text(
              _showFavoritesOnly ? '还没有收藏任何产品\n快去探索文创宝库吧！' : '暂无产品',
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
      padding: const EdgeInsets.all(16).copyWith(bottom: 80), // 为FAB留空间
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _filteredProducts.length,
      itemBuilder: (context, index) {
        final product = _filteredProducts[index];
        return _buildProductCard(product);
      },
    );
  }

  Widget _buildProductCard(Product product) {
    final isFav = _isFavorited(product);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => ProductDetailScreen(
                product: product,
                userProgress: _userProgress,
                onFavoriteToggle: () => _toggleFavorite(product),
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 产品图片占位
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: MiaoTheme.waxWhite,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _getProductIcon(product.type),
                            size: 48,
                            color: MiaoTheme.indigoDye
                                .withAlpha((0.3 * 255).round()),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              product.heritage,
                              style: TextStyle(
                                fontSize: 10,
                                color: MiaoTheme.silverThread
                                    .withAlpha((0.6 * 255).round()),
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // 产品信息
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: MiaoTheme.indigoDye,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product.description,
                        style: TextStyle(
                          fontSize: 11,
                          color: MiaoTheme.silverThread
                              .withAlpha((0.7 * 255).round()),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            '¥${product.price.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: MiaoTheme.mapleRed,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.star,
                            size: 14,
                            color: MiaoTheme.scholarGold,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            product.rating.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 11,
                              color: MiaoTheme.silverThread
                                  .withAlpha((0.7 * 255).round()),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // 收藏按钮
            Positioned(
              top: 8,
              right: 8,
              child: InkWell(
                onTap: () => _toggleFavorite(product),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha((0.95 * 255).round()),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha((0.1 * 255).round()),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Icon(
                    isFav ? Icons.favorite : Icons.favorite_border,
                    color: isFav ? Colors.red : MiaoTheme.silverThread,
                    size: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getProductIcon(String type) {
    switch (type) {
      case '服饰配件':
        return Icons.shopping_bag;
      case '文具用品':
        return Icons.book;
      case '首饰配件':
        return Icons.diamond;
      case '特色食品':
        return Icons.local_drink;
      case '生活用品':
        return Icons.home;
      case '数码产品':
        return Icons.devices;
      default:
        return Icons.category;
    }
  }

  void _showAIDesignDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: MiaoTheme.scholarGold),
            SizedBox(width: 8),
            Text('AI 设计助手'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '我可以帮你:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text('• 从非遗元素生成文创设计方案'),
            Text('• 提供产品定价和市场建议'),
            Text('• 撰写产品文案和故事'),
            Text('• 设计文旅体验路线'),
            SizedBox(height: 12),
            Text(
              '点击"开始设计"后,我会引导你完成整个创作过程。',
              style: TextStyle(fontSize: 12, color: MiaoTheme.silverThread),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('稍后再说'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              // 跳转到首页聊天界面
              DefaultTabController.of(context).animateTo(0);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('请在首页对话框中输入设计需求，如："帮我设计一款蜡染笔记本"'),
                  duration: Duration(seconds: 3),
                ),
              );
            },
            child: const Text('开始设计'),
          ),
        ],
      ),
    );
  }
}
