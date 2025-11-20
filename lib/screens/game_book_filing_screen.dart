import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/book_filing_task.dart';
import '../services/book_filing_game_service.dart';

class GameBookFilingScreen extends StatefulWidget {
  const GameBookFilingScreen({super.key});

  @override
  State<GameBookFilingScreen> createState() => _GameBookFilingScreenState();
}

class _GameBookFilingScreenState extends State<GameBookFilingScreen> {
  final BookFilingGameService _service = BookFilingGameService();
  late FilingTask _task;
  late Map<String, String?> _assignments; // fragmentId -> category or null
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _task = _service.createDemoTask();
    _assignments = {
      for (final f in _task.fragments) f.id: null,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('古籍归档'),
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
      ),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              MiaoTheme.waxWhite,
              MiaoTheme.indigoDye.withAlpha((0.05 * 255).round()),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 12),
                _buildProgress(),
                const SizedBox(height: 12),
                Expanded(
                  child: Column(
                    children: [
                      _buildFragmentsArea(),
                      const SizedBox(height: 16),
                      _buildCategoryTargets(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _task.title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: MiaoTheme.indigoDye,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _task.description,
          style: const TextStyle(
            fontSize: 13,
            color: MiaoTheme.silverThread,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildProgress() {
    final total = _task.fragments.length;
    final done = _assignments.values.where((c) => c != null).length;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '已归档 $done / $total',
          style: const TextStyle(
            fontSize: 13,
            color: MiaoTheme.indigoDye,
          ),
        ),
        if (_completed)
          const Text(
            '完成！',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: MiaoTheme.scholarGold,
            ),
          ),
      ],
    );
  }

  Widget _buildFragmentsArea() {
    final remaining = _task.fragments
        .where((f) => _assignments[f.id] == null)
        .toList();

    if (remaining.isEmpty) {
      return Container(
        height: 120,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withAlpha((0.6 * 255).round()),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Text(
          '太棒了，所有残片都已归档！',
          style: TextStyle(
            fontSize: 14,
            color: MiaoTheme.indigoDye,
          ),
        ),
      );
    }

    return Container(
      height: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha((0.7 * 255).round()),
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView(
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: remaining.map(_buildDraggableFragment).toList(),
        ),
      ),
    );
  }

  Widget _buildDraggableFragment(BookFragment fragment) {
    return Draggable<BookFragment>(
      data: fragment,
      feedback: _buildFragmentChip(fragment, isPreview: true),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _buildFragmentChip(fragment),
      ),
      child: _buildFragmentChip(fragment),
    );
  }

  Widget _buildFragmentChip(BookFragment fragment, {bool isPreview = false}) {
    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 220),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: MiaoTheme.waxWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: MiaoTheme.indigoDye.withAlpha((0.4 * 255).round()),
          ),
          boxShadow: isPreview
              ? [
                  BoxShadow(
                    color: MiaoTheme.indigoDye.withAlpha((0.3 * 255).round()),
                    blurRadius: 8,
                    offset: const Offset(2, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          fragment.text,
          style: const TextStyle(
            fontSize: 12,
            color: MiaoTheme.indigoDye,
            height: 1.3,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryTargets() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha((0.6 * 255).round()),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: _task.categories.map(_buildCategoryBox).toList(),
      ),
    );
  }

  Widget _buildCategoryBox(String category) {
    return DragTarget<BookFragment>(
      builder: (context, candidateData, rejected) {
        final isHighlighted = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 100,
          height: 80,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isHighlighted
                ? MiaoTheme.indigoDye.withAlpha((0.12 * 255).round())
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: MiaoTheme.indigoDye.withAlpha((0.5 * 255).round()),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                category,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: MiaoTheme.indigoDye,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                '拖动到此',
                style: TextStyle(
                  fontSize: 11,
                  color: MiaoTheme.silverThread,
                ),
              ),
            ],
          ),
        );
      },
      onAcceptWithDetails: (details) => _handleDrop(details.data, category),
    );
  }

  void _handleDrop(BookFragment fragment, String category) {
    final correct = _service.isCorrectCategory(fragment, category);

    if (!correct) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('这个残片不属于这个分类，再想想～'),
          duration: Duration(milliseconds: 800),
        ),
      );
      return;
    }

    setState(() {
      _assignments[fragment.id] = category;
      final total = _task.fragments.length;
      final done = _assignments.values.where((c) => c != null).length;
      if (done == total && !_completed) {
        _completed = true;
        _showCompletionDialog();
      }
    });
  }

  Future<void> _showCompletionDialog() async {
    final question = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('整理完成'),
          content: const Text(
            '你已经按照类别成功整理了这一批古籍残片。\n\n'
            '如果想深入了解这一关涉及的经典内容，可以让夏同龢继续为你讲解。',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('继续整理'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(
                '请帮我讲讲这一关涉及的四书、诗经和史书的背景与故事。',
              ),
              child: const Text('问夏同龢'),
            ),
          ],
        );
      },
    );

    if (question != null && question.isNotEmpty && mounted) {
      Navigator.of(context).pop<String>(question);
    }
  }
}
