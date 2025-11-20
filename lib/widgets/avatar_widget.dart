import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// 数字人状态
enum AvatarState {
  idle,      // 待机
  thinking,  // 思考中
  talking,   // 说话中
}

/// 夏同龢数字人组件（自适应版本）
class AvatarWidget extends StatefulWidget {
  final AvatarState state;
  final double size;

  const AvatarWidget({
    super.key,
    this.state = AvatarState.idle,
    this.size = 200,
  });

  @override
  State<AvatarWidget> createState() => _AvatarWidgetState();
}

class _AvatarWidgetState extends State<AvatarWidget> {
  @override
  Widget build(BuildContext context) {
    // ⬇️ 关键修改：使用 Lottie 直接填充，不使用圆形裁剪
    return LayoutBuilder(
      builder: (context, constraints) {
        return _buildAnimation();
      },
    );
  }

  Widget _buildAnimation() {
    String animationPath;
    
    switch (widget.state) {
      case AvatarState.idle:
        animationPath = 'assets/lottie/xia_idle.json';
        break;
      case AvatarState.thinking:
        animationPath = 'assets/lottie/xia_thinking.json';
        break;
      case AvatarState.talking:
        animationPath = 'assets/lottie/xia_talking.json';
        break;
    }

    return Lottie.asset(
      animationPath,
      fit: BoxFit.contain, // ⬇️ 改为 contain，保持完整显示
      errorBuilder: (context, error, stackTrace) {
        return _buildFallbackAvatar();
      },
    );
  }

  /// 备用头像（如果Lottie加载失败）
  Widget _buildFallbackAvatar() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person,
            size: widget.size * 0.4,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 8),
          Text(
            '夏同龢',
            style: TextStyle(
              fontSize: widget.size * 0.08,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          if (widget.state == AvatarState.thinking)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
