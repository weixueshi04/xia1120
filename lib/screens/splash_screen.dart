// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../config/theme.dart';
import 'chat_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();

    // 3秒后跳转到聊天界面
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ChatScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              MiaoTheme.indigoDye,
              MiaoTheme.indigoDye.withAlpha((0.8 * 255).round()),
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 蜡染纹样装饰
                _buildBatikDecoration(),

                const SizedBox(height: 40),

                // 夏同龢形象
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: MiaoTheme.scholarGold,
                      width: 4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: MiaoTheme.scholarGold
                            .withAlpha((0.3 * 255).round()),
                        blurRadius: 30,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Lottie.asset(
                      'assets/lottie/xia_idle.json',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: MiaoTheme.indigoDye
                              .withAlpha((0.3 * 255).round()),
                          child: const Icon(
                            Icons.person,
                            size: 100,
                            color: MiaoTheme.scholarGold,
                          ),
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // 标题
                const Text(
                  '夏同龢 · 麻江非遗',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: MiaoTheme.scholarGold,
                    letterSpacing: 2,
                  ),
                ),

                const SizedBox(height: 16),

                // 副标题
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: MiaoTheme.scholarGold
                            .withAlpha((0.5 * 255).round()),
                      ),
                      bottom: BorderSide(
                        color: MiaoTheme.scholarGold
                            .withAlpha((0.5 * 255).round()),
                      ),
                    ),
                  ),
                  child: const Text(
                    '大学生共创苗侗新国潮',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                      letterSpacing: 3,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                const Text(
                  '记录技艺 · 共创产品 · 讲好故事',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                ),

                const SizedBox(height: 40),

                // 加载动画
                SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor:
                        const AlwaysStoppedAnimation(MiaoTheme.scholarGold),
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  '正在加载麻江非遗数字基因库...',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white60,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBatikDecoration() {
    return CustomPaint(
      size: const Size(300, 60),
      painter: const BatikPatternPainter(),
    );
  }
}

/// 蜡染纹样绘制
class BatikPatternPainter extends CustomPainter {
  const BatikPatternPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = MiaoTheme.scholarGold.withAlpha((0.3 * 255).round())
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // 绘制简化的蜡染纹样
    final path = Path();

    // 波浪线
    for (double i = 0; i < size.width; i += 20) {
      if (i == 0) {
        path.moveTo(i, size.height / 2);
      } else {
        path.quadraticBezierTo(
          i - 10,
          size.height / 2 - 10,
          i,
          size.height / 2,
        );
        path.quadraticBezierTo(
          i + 10,
          size.height / 2 + 10,
          i + 20,
          size.height / 2,
        );
      }
    }

    canvas.drawPath(path, paint);

    // 小圆点装饰
    for (double i = 10; i < size.width; i += 30) {
      canvas.drawCircle(Offset(i, 10), 3, paint..style = PaintingStyle.fill);
      canvas.drawCircle(Offset(i, size.height - 10), 3, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

