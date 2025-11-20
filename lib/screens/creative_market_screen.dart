import 'package:flutter/material.dart';

import '../config/theme.dart';

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
  final List<Map<String, dynamic>> _products = [
    {
      'title': '苗绣帆布包',
      'description': '传统苗绣元素+现代设计',
      'price': '¥128',
      'type': '服饰配件',
      'icon': Icons.shopping_bag,
    },
    {
      'title': '蜡染笔记本',
      'description': '手工蜡染封面,独一无二',
      'price': '¥58',
      'type': '文具用品',
      'icon': Icons.book,
    },
    {
      'title': '银饰耳环',
      'description': '简约现代风格苗银饰品',
      'price': '¥268',
      'type': '首饰配件',
      'icon': Icons.diamond,
    },
    {
      'title': '蓝莓果酒',
      'description': '麻江蓝莓酿造,甜而不腻',
      'price': '¥88',
      'type': '特色食品',
      'icon': Icons.local_drink,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _buildProductGrid(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showAIDesignDialog();
        },
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
          icon: const Icon(Icons.favorite_border),
          onPressed: () {
            // TODO: 查看收藏
          },
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

  Widget _buildProductGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final product = _products[index];
        return _buildProductCard(product);
      },
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          _showProductDetail(product);
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
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
                  child: Icon(
                    product['icon'] as IconData,
                    size: 48,
                    color: MiaoTheme.indigoDye.withAlpha((0.3 * 255).round()),
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
                    product['title'] as String,
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
                    product['description'] as String,
                    style: TextStyle(
                      fontSize: 11,
                      color: MiaoTheme.silverThread.withAlpha((0.7 * 255).round()),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        product['price'] as String,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: MiaoTheme.mapleRed,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: MiaoTheme.scholarGold.withAlpha((0.2 * 255).round()),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          product['type'] as String,
                          style: TextStyle(
                            fontSize: 9,
                            color: MiaoTheme.scholarGold.withAlpha((0.9 * 255).round()),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showProductDetail(Map<String, dynamic> product) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(product['title'] as String),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: MiaoTheme.waxWhite,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(
                  product['icon'] as IconData,
                  size: 80,
                  color: MiaoTheme.indigoDye.withAlpha((0.3 * 255).round()),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              product['description'] as String,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Text(
              '价格: ${product['price']}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: MiaoTheme.mapleRed,
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
                const SnackBar(content: Text('已加入购物车')),
              );
            },
            child: const Text('加入购物车'),
          ),
        ],
      ),
    );
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
              // TODO: 跳转到首页聊天界面,预填设计相关问题
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('请到首页与AI顾问对话开始设计')),
              );
            },
            child: const Text('开始设计'),
          ),
        ],
      ),
    );
  }
}
