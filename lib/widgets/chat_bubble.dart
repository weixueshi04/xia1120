import 'package:flutter/material.dart';
import '../models/message.dart';
import '../config/theme.dart';

/// 聊天气泡组件（简洁圆角矩形）
class ChatBubble extends StatelessWidget {
  final Message message;

  const ChatBubble({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) _buildAvatar(context),
          if (!message.isUser) const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: message.isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                _buildBubble(context),
                const SizedBox(height: 4),
                _buildTimestamp(context),
              ],
            ),
          ),
          if (message.isUser) const SizedBox(width: 10),
          if (message.isUser) _buildAvatar(context),
        ],
      ),
    );
  }

  /// 头像（使用夏同龢静态图片）
  Widget _buildAvatar(BuildContext context) {
    if (message.isUser) {
      // ⬇️ 用户头像（使用 user_avatar.png）
      return Container(
        width: 36,
        height: 36,
          decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: MiaoTheme.scholarGold.withAlpha((0.5 * 255).round()),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: MiaoTheme.scholarGold.withAlpha((0.2 * 255).round()),
              blurRadius: 6,
              spreadRadius: 1,
            ),
          ],
        ),
        child: ClipOval(
          child: Image.asset(
            'images/xia_avatar.png', // ✅ 正确
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              // 如果图片加载失败，显示默认图标
              return Container(
                color: MiaoTheme.scholarGold.withAlpha((0.2 * 255).round()),
                child: const Icon(
                  Icons.person,
                  color: MiaoTheme.scholarGold,
                  size: 20,
                ),
              );
            },
          ),
        ),
      );
    }
    
    // 夏同龢静态图片头像
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: MiaoTheme.indigoDye.withAlpha((0.3 * 255).round()),
          width: 2,
        ),
          boxShadow: [
            BoxShadow(
              color: MiaoTheme.indigoDye.withAlpha((0.1 * 255).round()),
              blurRadius: 6,
              spreadRadius: 1,
            ),
          ],
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/images/xia_avatar.png', // ⬅️ 你提供的夏同龢图片
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // 如果图片加载失败，显示默认图标
            return Container(
              color: MiaoTheme.indigoDye.withAlpha((0.1 * 255).round()),
              child: const Icon(
                Icons.auto_awesome,
                color: MiaoTheme.indigoDye,
                size: 20,
              ),
            );
          },
        ),
      ),
    );
  }

  /// 简洁圆角矩形气泡（根据分类变色）
  Widget _buildBubble(BuildContext context) {
    // 根据消息分类获取边框颜色
    Color borderColor = _getBorderColor();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: message.isUser ? MiaoTheme.indigoDye : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: message.isUser ? MiaoTheme.indigoDye : borderColor,
          width: message.isUser ? 0 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.05 * 255).round()),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 助手消息：分类标签
          if (!message.isUser && message.category != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildCategoryTag(),
            ),

          // 消息内容
          Text(
            message.content,
            style: TextStyle(
              fontSize: 15,
              color: message.isUser ? Colors.white : Colors.black87,
              height: 1.5,
            ),
          ),

          // 状态指示器
          if (message.status == MessageStatus.sending) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(
                      message.isUser ? Colors.white : MiaoTheme.indigoDye,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '发送中...',
                  style: TextStyle(
                    fontSize: 11,
                    color: message.isUser
                        ? Colors.white70
                        : MiaoTheme.silverThread,
                  ),
                ),
              ],
            ),
          ],

          if (message.status == MessageStatus.error) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 14,
                  color: message.isUser ? Colors.white70 : MiaoTheme.mapleRed,
                ),
                const SizedBox(width: 4),
                Text(
                  '发送失败',
                  style: TextStyle(
                    fontSize: 11,
                    color: message.isUser ? Colors.white70 : MiaoTheme.mapleRed,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// 获取边框颜色（根据消息分类）
  Color _getBorderColor() {
    if (message.category == null) {
      return MiaoTheme.indigoDye.withAlpha((0.3 * 255).round()); // 默认蓝色
    }
    
    switch (message.category!) {
      case MessageCategory.culture:
        return MiaoTheme.indigoDye; // 非遗文化 - 蓝色
      case MessageCategory.agriculture:
        return Colors.green[600]!; // 农业知识 - 绿色
      case MessageCategory.education:
        return MiaoTheme.scholarGold; // 教育辅导 - 金色
      case MessageCategory.story:
        return MiaoTheme.silverThread; // 故事对话 - 灰白色
    }
  }

  /// 分类标签
  Widget _buildCategoryTag() {
    final (icon, text, color) = _getCategoryInfo();
    
      return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha((0.15 * 255).round()),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// 获取分类信息（图标、文字、颜色）
  (IconData, String, Color) _getCategoryInfo() {
    switch (message.category!) {
      case MessageCategory.culture:
        return (Icons.palette, '非遗文化', MiaoTheme.indigoDye);
      case MessageCategory.agriculture:
        return (Icons.agriculture, '农业知识', Colors.green[600]!);
      case MessageCategory.education:
        return (Icons.school, '教育辅导', MiaoTheme.scholarGold);
      case MessageCategory.story:
        return (Icons.auto_stories, '苗族故事', MiaoTheme.silverThread);
    }
  }

  /// 时间戳
  Widget _buildTimestamp(BuildContext context) {
    final timeStr = _formatTime(message.timestamp);
    return Text(
      timeStr,
      style: const TextStyle(
        fontSize: 11,
        color: MiaoTheme.silverThread,
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inSeconds < 60) {
      return '刚刚';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}分钟前';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}小时前';
    } else {
      return '${time.month}月${time.day}日 ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
  }
}
