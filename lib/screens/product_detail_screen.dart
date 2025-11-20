import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../models/product.dart';
import '../models/user_progress.dart';

/// 产品详情页
class ProductDetailScreen extends StatelessWidget {
  final Product product;
  final UserProgress? userProgress;
  final VoidCallback onFavoriteToggle;

  const ProductDetailScreen({
    required this.product,
    required this.userProgress,
    required this.onFavoriteToggle,
    super.key,
  });

  bool get _isFavorited {
    return userProgress?.favoriteProductIds.contains(product.id) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('产品详情'),
        actions: [
          IconButton(
            icon: Icon(
              _isFavorited ? Icons.favorite : Icons.favorite_border,
              color: _isFavorited ? Colors.red : null,
            ),
            onPressed: onFavoriteToggle,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProductImage(),
            _buildProductInfo(context),
            _buildProductStory(context),
            _buildDesignProcess(context),
            _buildDesignerInfo(context),
            _buildProductSpecs(context),
            const SizedBox(height: 80), // 为底部按钮留空间
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  Widget _buildProductImage() {
    return Container(
      height: 300,
      width: double.infinity,
      color: MiaoTheme.waxWhite,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getProductIcon(),
            size: 80,
            color: MiaoTheme.indigoDye.withAlpha((0.3 * 255).round()),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: MiaoTheme.scholarGold.withAlpha((0.2 * 255).round()),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              product.heritage,
              style: TextStyle(
                fontSize: 14,
                color: MiaoTheme.scholarGold.withAlpha((0.9 * 255).round()),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductInfo(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            product.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: MiaoTheme.indigoDye,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            product.description,
            style: TextStyle(
              fontSize: 14,
              color: MiaoTheme.silverThread.withAlpha((0.8 * 255).round()),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                '¥${product.price.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: MiaoTheme.mapleRed,
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: MiaoTheme.waxWhite,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: MiaoTheme.silverThread),
                ),
                child: Text(
                  product.type,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.star, color: MiaoTheme.scholarGold, size: 20),
              const SizedBox(width: 4),
              Text(
                '${product.rating} 评分',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(width: 16),
              Text(
                '已售 ${product.sales} 件',
                style: TextStyle(
                  fontSize: 14,
                  color: MiaoTheme.silverThread.withAlpha((0.7 * 255).round()),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '库存 ${product.stock} 件',
                style: TextStyle(
                  fontSize: 14,
                  color: MiaoTheme.silverThread.withAlpha((0.7 * 255).round()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductStory(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MiaoTheme.waxWhite,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_stories, color: MiaoTheme.indigoDye),
              SizedBox(width: 8),
              Text(
                '产品故事',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: MiaoTheme.indigoDye,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            product.story,
            style: const TextStyle(fontSize: 14, height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _buildDesignProcess(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MiaoTheme.scholarGold.withAlpha((0.1 * 255).round()),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: MiaoTheme.scholarGold.withAlpha((0.3 * 255).round()),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome, color: MiaoTheme.scholarGold),
              SizedBox(width: 8),
              Text(
                'AI 设计过程',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: MiaoTheme.indigoDye,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            product.aiDesignProcess,
            style: const TextStyle(fontSize: 13, height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _buildDesignerInfo(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MiaoTheme.waxWhite),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '设计师',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: MiaoTheme.indigoDye,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: MiaoTheme.indigoDye.withAlpha((0.1 * 255).round()),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.people, color: MiaoTheme.indigoDye),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  product.designer,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductSpecs(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MiaoTheme.waxWhite),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '产品规格',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: MiaoTheme.indigoDye,
            ),
          ),
          const SizedBox(height: 12),
          _buildSpecRow('材质', product.materials),
          _buildSpecRow('尺寸', product.size),
          _buildSpecRow('分类', product.category),
        ],
      ),
    );
  }

  Widget _buildSpecRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: MiaoTheme.silverThread.withAlpha((0.7 * 255).round()),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.1 * 255).round()),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('客服功能开发中...')),
                );
              },
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text('客服'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('已加入购物车')),
                  );
                },
                icon: const Icon(Icons.shopping_cart),
                label: const Text('加入购物车'),
                style: FilledButton.styleFrom(
                  backgroundColor: MiaoTheme.mapleRed,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getProductIcon() {
    switch (product.type) {
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
}
