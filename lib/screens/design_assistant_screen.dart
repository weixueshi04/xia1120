import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../services/design_assistant_service.dart';
import '../widgets/chat_bubble.dart';
import '../models/message.dart';

/// AI设计助手对话界面
class DesignAssistantScreen extends StatefulWidget {
  const DesignAssistantScreen({super.key});

  @override
  State<DesignAssistantScreen> createState() => _DesignAssistantScreenState();
}

class _DesignAssistantScreenState extends State<DesignAssistantScreen> {
  final DesignAssistantService _designService = DesignAssistantService();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Message> _messages = [];

  DesignTemplate? _currentTemplate;
  int _currentQuestionIndex = 0;
  final Map<String, String> _userAnswers = {};
  bool _isInGuidedMode = false;

  @override
  void initState() {
    super.initState();
    _addGreeting();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addGreeting() {
    setState(() {
      _messages.add(
        Message.assistant(
          _designService.getGreeting(),
          category: MessageCategory.design,
        ),
      );
    });
  }

  void _handleSend() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();
    _addUserMessage(text);

    if (_isInGuidedMode && _currentTemplate != null) {
      _handleGuidedAnswer(text);
    } else {
      _handleFreeInput(text);
    }
  }

  void _addUserMessage(String text) {
    setState(() {
      _messages.add(Message.user(text));
    });
    _scrollToBottom();
  }

  void _addAssistantMessage(String text, {MessageCategory? category}) {
    setState(() {
      _messages.add(
        Message.assistant(
          text,
          category: category ?? MessageCategory.design,
        ),
      );
    });
    _scrollToBottom();
  }

  void _handleFreeInput(String text) {
    // 尝试智能匹配模板
    final template = _designService.matchTemplate(text);

    if (template != null) {
      _startGuidedMode(template);
    } else {
      _addAssistantMessage(
        '我理解你想设计一些内容，但还需要更具体的信息。\n\n'
        '你可以：\n'
        '1. 告诉我具体想设计什么产品或活动\n'
        '2. 或者点击下方的快速入口选择一个设计模板',
      );
    }
  }

  void _handleGuidedAnswer(String answer) {
    if (_currentTemplate == null) return;

    final question = _currentTemplate!.guidingQuestions[_currentQuestionIndex];
    _userAnswers[question] = answer;

    _currentQuestionIndex++;

    if (_currentQuestionIndex < _currentTemplate!.guidingQuestions.length) {
      // 继续下一个问题
      _addAssistantMessage(
        '很好！接下来：\n\n'
        '${_currentTemplate!.guidingQuestions[_currentQuestionIndex]}',
      );
    } else {
      // 所有问题已回答，生成设计建议
      _generateDesignSuggestion();
    }
  }

  void _startGuidedMode(DesignTemplate template) {
    setState(() {
      _currentTemplate = template;
      _currentQuestionIndex = 0;
      _userAnswers.clear();
      _isInGuidedMode = true;
    });

    _addAssistantMessage(
      '太好了！我将引导你完成【${template.name}】的设计。\n\n'
      '我会问你几个问题，以便为你提供更精准的设计建议。\n\n'
      '${template.guidingQuestions[0]}',
    );
  }

  void _generateDesignSuggestion() {
    if (_currentTemplate == null) return;

    final suggestion = _designService.generateDesignSuggestion(
      template: _currentTemplate!,
      userAnswers: _userAnswers,
    );

    _addAssistantMessage(suggestion);

    _addAssistantMessage(
      '设计建议已生成！\n\n'
      '你可以：\n'
      '1. 继续优化这个设计（告诉我需要调整的地方）\n'
      '2. 开始新的设计（选择其他模板）\n'
      '3. 询问设计相关的问题',
    );

    setState(() {
      _isInGuidedMode = false;
      _currentTemplate = null;
      _currentQuestionIndex = 0;
    });
  }

  void _selectQuickOption(String templateId) {
    final template = _designService.getTemplateById(templateId);
    if (template != null) {
      _addUserMessage('我想设计${template.name}');
      _startGuidedMode(template);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          if (!_isInGuidedMode) _buildQuickOptions(),
          Expanded(child: _buildMessageList()),
          _buildInputArea(),
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
              MiaoTheme.scholarGold,
              MiaoTheme.scholarGold.withAlpha((0.8 * 255).round()),
            ],
          ),
        ),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha((0.2 * 255).round()),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.palette,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'AI设计助手',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_isInGuidedMode && _currentTemplate != null)
                Text(
                  '正在设计: ${_currentTemplate!.name}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
            ],
          ),
        ],
      ),
      actions: [
        if (_isInGuidedMode)
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: '退出引导模式',
            onPressed: () {
              setState(() {
                _isInGuidedMode = false;
                _currentTemplate = null;
                _currentQuestionIndex = 0;
                _userAnswers.clear();
              });
              _addAssistantMessage('已退出引导模式，有什么其他需要帮助的吗？');
            },
          ),
      ],
    );
  }

  Widget _buildQuickOptions() {
    final options = _designService.getQuickOptions();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: MiaoTheme.waxWhite,
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
          const Padding(
            padding: EdgeInsets.only(left: 8, bottom: 8),
            child: Text(
              '快速开始',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: MiaoTheme.indigoDye,
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: options
                  .map(
                    (option) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ActionChip(
                        avatar: Text(
                          option['icon']!,
                          style: const TextStyle(fontSize: 16),
                        ),
                        label: Text(
                          option['label']!,
                          style: const TextStyle(fontSize: 12),
                        ),
                        onPressed: () =>
                            _selectQuickOption(option['templateId']!),
                        backgroundColor: MiaoTheme.scholarGold
                            .withAlpha((0.1 * 255).round()),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            MiaoTheme.waxWhite,
            Colors.white.withAlpha((0.8 * 255).round()),
          ],
        ),
      ),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _messages.length +
            (_isInGuidedMode && _currentTemplate != null ? 1 : 0),
        itemBuilder: (context, index) {
          if (index < _messages.length) {
            return ChatBubble(message: _messages[index]);
          } else {
            return _buildProgressIndicator();
          }
        },
      ),
    );
  }

  Widget _buildProgressIndicator() {
    if (_currentTemplate == null) return const SizedBox.shrink();

    final totalQuestions = _currentTemplate!.guidingQuestions.length;
    final answeredQuestions = _currentQuestionIndex;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.checklist,
                    size: 16,
                    color: MiaoTheme.scholarGold,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '设计进度: $answeredQuestions / $totalQuestions',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: MiaoTheme.indigoDye,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: answeredQuestions / totalQuestions,
                  minHeight: 6,
                  backgroundColor: MiaoTheme.waxWhite,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    MiaoTheme.scholarGold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.05 * 255).round()),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: MiaoTheme.waxWhite,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: MiaoTheme.scholarGold.withAlpha((0.3 * 255).round()),
                  ),
                ),
                child: TextField(
                  controller: _textController,
                  decoration: InputDecoration(
                    hintText: _isInGuidedMode
                        ? '输入你的答案...'
                        : '告诉我你想设计什么...',
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _handleSend(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    MiaoTheme.scholarGold,
                    Color(0xFFD4A017),
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: MiaoTheme.scholarGold.withAlpha((0.4 * 255).round()),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.send,
                  color: Colors.white,
                ),
                onPressed: _handleSend,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
