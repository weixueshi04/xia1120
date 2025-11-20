import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../config/theme.dart';

/// 反馈类型
enum FeedbackType {
  archive, // 提交档案
  suggestion, // 反馈建议
}

/// 反馈记录
class FeedbackRecord {
  final String id;
  final FeedbackType type;
  final String title;
  final String content;
  final DateTime submittedAt;
  final String status; // pending, reviewed, adopted

  FeedbackRecord({
    required this.id,
    required this.type,
    required this.title,
    required this.content,
    required this.submittedAt,
    this.status = 'pending',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString(),
      'title': title,
      'content': content,
      'submittedAt': submittedAt.toIso8601String(),
      'status': status,
    };
  }

  factory FeedbackRecord.fromJson(Map<String, dynamic> json) {
    return FeedbackRecord(
      id: json['id'] as String,
      type: FeedbackType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => FeedbackType.suggestion,
      ),
      title: json['title'] as String,
      content: json['content'] as String,
      submittedAt: DateTime.parse(json['submittedAt'] as String),
      status: json['status'] as String? ?? 'pending',
    );
  }
}

/// 反馈中心
class FeedbackCenterScreen extends StatefulWidget {
  const FeedbackCenterScreen({super.key});

  @override
  State<FeedbackCenterScreen> createState() => _FeedbackCenterScreenState();
}

class _FeedbackCenterScreenState extends State<FeedbackCenterScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<FeedbackRecord> _records = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadRecords();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRecords() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? recordsJson = prefs.getString('feedback_records');
      if (recordsJson != null) {
        final List<dynamic> recordsList = jsonDecode(recordsJson);
        setState(() {
          _records.clear();
          _records.addAll(
            recordsList
                .map((json) => FeedbackRecord.fromJson(json))
                .toList(),
          );
        });
      }
    } catch (e) {
      print('加载反馈记录失败: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveRecords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recordsJson =
          jsonEncode(_records.map((r) => r.toJson()).toList());
      await prefs.setString('feedback_records', recordsJson);
    } catch (e) {
      print('保存反馈记录失败: $e');
    }
  }

  Future<void> _submitFeedback(
    FeedbackType type,
    String title,
    Map<String, String> fields,
  ) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final content = fields.entries
        .map((e) => '${e.key}: ${e.value}')
        .join('\n');

    final record = FeedbackRecord(
      id: id,
      type: type,
      title: title,
      content: content,
      submittedAt: DateTime.now(),
    );

    setState(() {
      _records.insert(0, record);
    });

    await _saveRecords();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('提交成功！感谢你的参与'),
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildSubmissionTab(),
                      _buildHistoryTab(),
                    ],
                  ),
          ),
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
          Icon(Icons.feedback, size: 24),
          SizedBox(width: 8),
          Text('反馈中心'),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MiaoTheme.waxWhite,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: MiaoTheme.indigoDye.withAlpha((0.15 * 255).round()),
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: MiaoTheme.indigoDye,
        unselectedLabelColor: MiaoTheme.silverThread,
        tabs: const [
          Tab(text: '提交'),
          Tab(text: '记录'),
        ],
      ),
    );
  }

  Widget _buildSubmissionTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          '选择提交类型',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: MiaoTheme.indigoDye,
          ),
        ),
        const SizedBox(height: 16),
        _buildSubmissionCard(
          title: '提交非遗档案',
          description: '记录你发现的非遗技艺、故事或传承人信息',
          icon: Icons.folder_special,
          color: MiaoTheme.indigoDye,
          onTap: () => _showArchiveSubmissionDialog(),
        ),
        const SizedBox(height: 12),
        _buildSubmissionCard(
          title: '反馈建议',
          description: '告诉我们你对平台的意见和改进建议',
          icon: Icons.lightbulb,
          color: MiaoTheme.scholarGold,
          onTap: () => _showSuggestionDialog(),
        ),
      ],
    );
  }

  Widget _buildSubmissionCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withAlpha((0.1 * 255).round()),
                Colors.white,
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withAlpha((0.2 * 255).round()),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: color, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 14,
                          color: MiaoTheme.silverThread
                              .withAlpha((0.8 * 255).round()),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 20,
                  color: color.withAlpha((0.5 * 255).round()),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (_records.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 80,
              color: MiaoTheme.silverThread.withAlpha((0.3 * 255).round()),
            ),
            const SizedBox(height: 16),
            Text(
              '暂无提交记录',
              style: TextStyle(
                fontSize: 16,
                color: MiaoTheme.silverThread.withAlpha((0.6 * 255).round()),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _records.length,
      itemBuilder: (context, index) {
        return _buildRecordCard(_records[index]);
      },
    );
  }

  Widget _buildRecordCard(FeedbackRecord record) {
    final Color typeColor = record.type == FeedbackType.archive
        ? MiaoTheme.indigoDye
        : MiaoTheme.scholarGold;

    final String statusText = record.status == 'pending'
        ? '待审核'
        : record.status == 'reviewed'
            ? '已查看'
            : '已采纳';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: typeColor.withAlpha((0.15 * 255).round()),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    record.type == FeedbackType.archive
                        ? '档案'
                        : '建议',
                    style: TextStyle(
                      fontSize: 12,
                      color: typeColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    record.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: MiaoTheme.indigoDye,
                    ),
                  ),
                ),
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 12,
                    color: MiaoTheme.silverThread
                        .withAlpha((0.6 * 255).round()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              record.content.length > 100
                  ? '${record.content.substring(0, 100)}...'
                  : record.content,
              style: TextStyle(
                fontSize: 13,
                color: MiaoTheme.silverThread.withAlpha((0.8 * 255).round()),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 14,
                  color: MiaoTheme.silverThread.withAlpha((0.5 * 255).round()),
                ),
                const SizedBox(width: 4),
                Text(
                  '${record.submittedAt.year}-${record.submittedAt.month.toString().padLeft(2, '0')}-${record.submittedAt.day.toString().padLeft(2, '0')} '
                  '${record.submittedAt.hour.toString().padLeft(2, '0')}:${record.submittedAt.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        MiaoTheme.silverThread.withAlpha((0.5 * 255).round()),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showArchiveSubmissionDialog() {
    final titleController = TextEditingController();
    final categoryController = TextEditingController();
    final locationController = TextEditingController();
    final descriptionController = TextEditingController();
    final sourceController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.folder_special, color: MiaoTheme.indigoDye),
            SizedBox(width: 8),
            Text('提交非遗档案'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '感谢你为麻江非遗数字基因库添砖加瓦！',
                style: TextStyle(
                  fontSize: 13,
                  color: MiaoTheme.silverThread,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: '档案标题 *',
                  hintText: '例如：苗族蜡染技艺',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: categoryController,
                decoration: const InputDecoration(
                  labelText: '分类 *',
                  hintText: '例如：蜡染/银饰/刺绣',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: locationController,
                decoration: const InputDecoration(
                  labelText: '地点',
                  hintText: '例如：麻江县宣威镇',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: '详细描述 *',
                  hintText: '请描述技艺特点、传承故事等',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: sourceController,
                decoration: const InputDecoration(
                  labelText: '信息来源',
                  hintText: '例如：现场采访/文献资料',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              if (titleController.text.trim().isEmpty ||
                  categoryController.text.trim().isEmpty ||
                  descriptionController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('请填写必填项')),
                );
                return;
              }

              _submitFeedback(
                FeedbackType.archive,
                titleController.text.trim(),
                {
                  '标题': titleController.text.trim(),
                  '分类': categoryController.text.trim(),
                  '地点': locationController.text.trim(),
                  '描述': descriptionController.text.trim(),
                  '来源': sourceController.text.trim(),
                },
              );
            },
            child: const Text('提交'),
          ),
        ],
      ),
    );
  }

  void _showSuggestionDialog() {
    final titleController = TextEditingController();
    final typeController = TextEditingController();
    final contentController = TextEditingController();
    final contactController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lightbulb, color: MiaoTheme.scholarGold),
            SizedBox(width: 8),
            Text('反馈建议'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '你的意见对我们非常重要！',
                style: TextStyle(
                  fontSize: 13,
                  color: MiaoTheme.silverThread,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: '标题 *',
                  hintText: '简要概括你的建议',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: typeController,
                decoration: const InputDecoration(
                  labelText: '类型',
                  hintText: '功能建议/Bug反馈/内容建议',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contentController,
                decoration: const InputDecoration(
                  labelText: '详细内容 *',
                  hintText: '请详细描述你的建议或遇到的问题',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contactController,
                decoration: const InputDecoration(
                  labelText: '联系方式（选填）',
                  hintText: '方便我们与你进一步沟通',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              if (titleController.text.trim().isEmpty ||
                  contentController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('请填写必填项')),
                );
                return;
              }

              _submitFeedback(
                FeedbackType.suggestion,
                titleController.text.trim(),
                {
                  '标题': titleController.text.trim(),
                  '类型': typeController.text.trim(),
                  '内容': contentController.text.trim(),
                  '联系方式': contactController.text.trim(),
                },
              );
            },
            child: const Text('提交'),
          ),
        ],
      ),
    );
  }
}
