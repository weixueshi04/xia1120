import 'package:flutter/material.dart';
import '../config/theme.dart';
import 'feedback_center_screen.dart';
import 'module_manager_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [MiaoTheme.indigoDye, MiaoTheme.indigoDye.withAlpha(204)],
            ),
          ),
        ),
        title: const Text('我的'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: MiaoTheme.indigoDye.withAlpha(25),
                    child: const Icon(Icons.person, size: 40, color: MiaoTheme.indigoDye),
                  ),
                  const SizedBox(height: 12),
                  const Text('大学生共创者', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: MiaoTheme.scholarGold.withAlpha(51),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('Lv.1 见习采撷者', style: TextStyle(fontSize: 12, color: MiaoTheme.scholarGold)),
                  ),
                ],
              ),
            ),
            _buildDataPanel(),
            _buildMenuList(),
          ],
        ),
      ),
    );
  }

  Widget _buildDataPanel() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('我的数据', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildDataItem('学习天数', '0', Icons.calendar_today)),
              Expanded(child: _buildDataItem('完成任务', '0', Icons.task_alt)),
              Expanded(child: _buildDataItem('获得成就', '0', Icons.emoji_events)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDataItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: MiaoTheme.indigoDye, size: 28),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: MiaoTheme.indigoDye)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: MiaoTheme.silverThread.withAlpha(178))),
      ],
    );
  }

  Widget _buildMenuList() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(13), blurRadius: 8)],
      ),
      child: Column(
        children: [
          _buildMenuItem(Icons.favorite, '我的收藏', () {}),
          const Divider(height: 1),
          _buildMenuItem(Icons.emoji_events, '我的成就', () {}),
          const Divider(height: 1),
          _buildMenuItem(Icons.feedback, '反馈中心', () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const FeedbackCenterScreen()));
          }),
          const Divider(height: 1),
          _buildMenuItem(Icons.storage, '知识模块管理', () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ModuleManagerScreen()));
          }),
          const Divider(height: 1),
          _buildMenuItem(Icons.info_outline, '关于', () {}),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: MiaoTheme.indigoDye),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}
