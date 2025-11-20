import 'package:flutter/material.dart';

import '../config/theme.dart';
import 'chat_screen.dart';

/// 首页 - 聊天+AI顾问
/// 功能:
/// 1. AI顾问对话(原ChatScreen)
/// 2. 快捷功能入口
/// 3. 每日推荐
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 当前直接使用原有的ChatScreen
    // 后续可以在外层添加更多功能模块
    return const ChatScreen();
  }
}
