import 'package:flutter/material.dart';

import '../config/theme.dart';
import 'home_screen.dart';
import 'heritage_library_screen.dart';
import 'creative_market_screen.dart';
import 'cocreation_screen.dart';
import 'profile_screen.dart';

/// 主导航屏幕 - 包含5个Tab页面
/// 1. 首页 (聊天+AI顾问)
/// 2. 非遗库 (技艺/故事/人物档案)
/// 3. 文创集 (产品展示/设计灵感)
/// 4. 共创 (任务系统/能力成长)
/// 5. 我的 (个人中心/数据面板)
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomeScreen(),
    HeritageLibraryScreen(),
    CreativeMarketScreen(),
    CocreationScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.05 * 255).round()),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                index: 0,
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: '首页',
              ),
              _buildNavItem(
                index: 1,
                icon: Icons.inventory_2_outlined,
                activeIcon: Icons.inventory_2,
                label: '非遗库',
              ),
              _buildNavItem(
                index: 2,
                icon: Icons.storefront_outlined,
                activeIcon: Icons.storefront,
                label: '文创集',
              ),
              _buildNavItem(
                index: 3,
                icon: Icons.rocket_launch_outlined,
                activeIcon: Icons.rocket_launch,
                label: '共创',
              ),
              _buildNavItem(
                index: 4,
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: '我的',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isActive = _currentIndex == index;
    final color = isActive ? MiaoTheme.indigoDye : MiaoTheme.silverThread;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
