import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../models/game_definition.dart';
import '../models/message.dart';
import '../services/baidu_api.dart';
import '../services/baidu_speech_service.dart';
import '../services/rag_service.dart';
import '../utils/logger.dart';
import '../widgets/avatar_widget.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/game_entry_card.dart';
import 'design_assistant_screen.dart';
import 'game_book_filing_screen.dart';
import 'game_farm_management_screen.dart';
import 'module_manager_screen.dart';
import 'proxy_status_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<Message> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final RagService _ragService = RagService();
  final BaiduAPIService _baiduService = BaiduAPIService();
  final BaiduSpeechService _speechService = BaiduSpeechService();

  final List<GameDefinition> _games = const [
    GameDefinition(
      id: 'book_filing',
      title: '非遗档案整理',
      subtitle: '和夏同龢一起建数字基因库',
      estimatedDuration: '3-5 分钟',
      roleTag: '技艺守护',
    ),
    GameDefinition(
      id: 'farm_management',
      title: '麻江非遗小镇',
      subtitle: '平衡工坊 / 体验 / 社区收益',
      estimatedDuration: '5-8 分钟',
      roleTag: '运营策划',
    ),
  ];

  bool _isTTSEnabled = false;
  bool _isRecording = false;
  bool _isProcessing = false;
  AvatarState _avatarState = AvatarState.idle;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    await _ragService.initialize();
    // 语音服务使用默认配置，只控制开关
    _speechService.setTTSEnabled(_isTTSEnabled);
    if (!mounted) return;
    _addWelcomeMessage();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _speechService.dispose();
    super.dispose();
  }

  void _addWelcomeMessage() {
    setState(() {
      _messages.add(
        Message.assistant(
          '你好！这里是“夏同龢 · 麻江非遗数字文创平台”。\n\n'
          '我可以帮你：\n'
          '1）了解麻江非遗技艺与故事，搭建数字基因库；\n'
          '2）共创文创设计 / 体验方案，服务大学生和手艺人；\n'
          '3）讲好品牌故事、制定营销脚本，连接消费者。\n\n'
          '你想先聊哪一块？',
          category: MessageCategory.culture,
        ),
      );
    });
  }

  void _handleSend() {
    final text = _textController.text.trim();
    if (text.isEmpty || _isProcessing) return;

    _textController.clear();
    _addUserMessage(text);
    _sendAssistantReply(text);
  }

  void _addUserMessage(String text) {
    setState(() {
      _messages.add(Message.user(text));
    });
    _scrollToBottom();
  }

  Future<void> _sendAssistantReply(String query) async {
    setState(() {
      _isProcessing = true;
      _avatarState = AvatarState.thinking;
    });

    try {
      final localOrHybrid = await _ragService.search(query);
      String? answer = localOrHybrid?.content;

      if (answer == null || answer.trim().isEmpty) {
        answer = await _baiduService.chat(query);
      }

      answer ??= '这个问题暂时超出了我的知识范围，但我会继续学习麻江非遗相关内容。';

      if (!mounted) return;

      setState(() {
        _avatarState = AvatarState.talking;
        _messages.add(
          Message.assistant(
            answer!,
            category: MessageCategory.culture,
          ),
        );
      });
      _scrollToBottom();

      if (_isTTSEnabled) {
        await _speechService.speak(answer);
      }
    } catch (e, st) {
      Logger.error('生成回复失败', error: e, stackTrace: st);
      if (!mounted) return;
      setState(() {
        _messages.add(
          Message.assistant(
            '刚刚思考时出了点小问题，可以稍后再试一次。',
            status: MessageStatus.error,
          ),
        );
      });
    } finally {
      if (!mounted) {
        _isProcessing = false;
        _avatarState = AvatarState.idle;
      } else {
        setState(() {
          _isProcessing = false;
          _avatarState = AvatarState.idle;
        });
      }
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

  void _toggleTTS() {
    setState(() {
      _isTTSEnabled = !_isTTSEnabled;
      _speechService.setTTSEnabled(_isTTSEnabled);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isTTSEnabled ? '🔊 语音播报已开启' : '🔇 语音播报已关闭'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _openGame(GameDefinition game) {
    Widget? screen;
    switch (game.id) {
      case 'book_filing':
        screen = const GameBookFilingScreen();
        break;
      case 'farm_management':
        screen = const GameFarmManagementScreen();
        break;
      default:
        break;
    }

    if (screen == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen!),
    );
  }

  void _handleQuickQuestionTap(String key) {
    if (key == 'AI设计') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const DesignAssistantScreen(),
        ),
      );
      return;
    }

    String question;
    switch (key) {
      case '非遗':
        question = '麻江有哪些代表性的非遗技艺？';
        break;
      case '设计':
        question = '如何把苗族银饰元素做成年轻人喜欢的文创产品？';
        break;
      case '研学':
        question = '帮我设计一条麻江非遗研学一日游路线。';
        break;
      case '运营':
      default:
        question = '如何为麻江非遗文创品牌写一场直播带货脚本？';
        break;
    }
    _textController.text = question;
    _handleSend();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Container(
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
        child: Row(
          children: [
            _buildAvatarStage(),
            _buildChatPanel(),
          ],
        ),
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
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: MiaoTheme.scholarGold.withAlpha((0.2 * 255).round()),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.school,
              color: MiaoTheme.scholarGold,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '夏同龢 · 麻江非遗顾问',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '大学生共创实验室',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(_isTTSEnabled ? Icons.volume_up : Icons.volume_off),
          tooltip: _isTTSEnabled ? '关闭语音' : '开启语音',
          onPressed: _toggleTTS,
        ),
        IconButton(
          icon: const Icon(Icons.info_outline),
          tooltip: '关于',
          onPressed: _showAboutDialog,
        ),
        IconButton(
          icon: const Icon(Icons.storage),
          tooltip: '知识模块管理',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ModuleManagerScreen(),
              ),
            );
          },
        ),
        if (kIsWeb)
          IconButton(
            icon: const Icon(Icons.router),
            tooltip: '代理状态',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ProxyStatusScreen(),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildAvatarStage() {
    final width = MediaQuery.of(context).size.width;
    final stageWidth = width * 0.35;

    return Container(
      width: stageWidth.clamp(260.0, 420.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            MiaoTheme.indigoDye.withAlpha((0.05 * 255).round()),
            MiaoTheme.waxWhite.withAlpha((0.9 * 255).round()),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.05 * 255).round()),
            blurRadius: 15,
            offset: const Offset(5, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          _buildAvatarTitle(),
          const SizedBox(height: 8),
          Expanded(
            child: Center(
              child: AvatarWidget(
                state: _avatarState,
                size: stageWidth * 0.8,
              ),
            ),
          ),
          _buildAvatarStatus(),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildAvatarTitle() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.school,
          color: MiaoTheme.scholarGold,
          size: 20,
        ),
        SizedBox(width: 8),
        Text(
          '夏同龢 · 麻江非遗顾问',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: MiaoTheme.indigoDye,
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarStatus() {
    String text;
    switch (_avatarState) {
      case AvatarState.idle:
        text = '等你来聊聊麻江的非遗与故事～';
        break;
      case AvatarState.thinking:
        text = '让我想一想，怎样回答更有文化味…';
        break;
      case AvatarState.talking:
        text = '我有一个关于麻江非遗的灵感想分享给你。';
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          color: MiaoTheme.indigoDye.withAlpha((0.8 * 255).round()),
          height: 1.3,
        ),
      ),
    );
  }

  Widget _buildChatPanel() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            _buildQuickQuestions(),
            const SizedBox(height: 8),
            _buildGameEntrySection(),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha((0.9 * 255).round()),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha((0.03 * 255).round()),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: _buildMessageList(),
              ),
            ),
            const SizedBox(height: 4),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickQuestions() {
    final chips = [
      {'icon': '🎨', 'label': '非遗'},
      {'icon': '🤖', 'label': 'AI设计'},
      {'icon': '💡', 'label': '设计'},
      {'icon': '🧭', 'label': '研学'},
      {'icon': '📣', 'label': '运营'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: chips
            .map(
              (c) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ActionChip(
                  avatar: Text(
                    c['icon'] as String,
                    style: const TextStyle(fontSize: 14),
                  ),
                  label: Text(
                    c['label'] as String,
                    style: const TextStyle(fontSize: 11),
                  ),
                  onPressed: () =>
                      _handleQuickQuestionTap(c['label'] as String),
                  backgroundColor:
                      MiaoTheme.indigoDye.withAlpha((0.06 * 255).round()),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildGameEntrySection() {
    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _games.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final game = _games[index];
          return GameEntryCard(
            game: game,
            color: index == 0 ? MiaoTheme.indigoDye : MiaoTheme.mapleRed,
            icon: index == 0 ? Icons.folder_special : Icons.villa,
            onTap: () => _openGame(game),
          );
        },
      ),
    );
  }

  Widget _buildMessageList() {
    if (_messages.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            '开始对话吧～可以问我任何关于麻江非遗、文创设计或研学运营的问题。',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: MiaoTheme.silverThread,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        return ChatBubble(message: _messages[index]);
      },
    );
  }

  Widget _buildInputArea() {
    return SafeArea(
      child: Row(
        children: [
          // 语音按钮（只做 UI 提示）
          Container(
            decoration: BoxDecoration(
              color: _isRecording
                  ? MiaoTheme.mapleRed.withAlpha((0.2 * 255).round())
                  : MiaoTheme.indigoDye.withAlpha((0.08 * 255).round()),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                _isRecording ? Icons.mic : Icons.mic_none,
                color: _isRecording ? MiaoTheme.mapleRed : MiaoTheme.indigoDye,
              ),
              onPressed: () {
                setState(() {
                  _isRecording = !_isRecording;
                });
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: MiaoTheme.indigoDye.withAlpha((0.2 * 255).round()),
                ),
              ),
              child: TextField(
                controller: _textController,
                decoration: const InputDecoration(
                  hintText: '输入你对麻江非遗、文创或研学的想法…',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _handleSend(),
                enabled: !_isProcessing,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _isProcessing
                    ? [Colors.grey, Colors.grey]
                    : [
                        MiaoTheme.indigoDye,
                        MiaoTheme.indigoDye.withAlpha((0.85 * 255).round()),
                      ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (_isProcessing ? Colors.grey : MiaoTheme.indigoDye)
                      .withAlpha((0.35 * 255).round()),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(
                _isProcessing ? Icons.hourglass_empty : Icons.send,
                color: Colors.white,
              ),
              onPressed: _isProcessing ? null : _handleSend,
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('关于 夏同龢 · 麻江非遗数字文创平台'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('版本 1.0.0\n'),
              Text(
                '这是南京农业大学学生团队为贵州麻江打造的“非遗+AI+文创”实验平台，'
                '用来实践并验证少数民族文化经济效益转化路径。',
              ),
              SizedBox(height: 16),
              Text(
                '功能亮点',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('· 麻江非遗数字基因库（技艺 / 故事 / 人物档案）'),
              Text('· 非遗顾问：产品 / 体验 / 脚本的共创建议'),
              Text('· 大学生共创：设计师、档案编辑、运营策划'),
              Text('· 苗侗风格 UI 与小游戏'),
              SizedBox(height: 16),
              Text('试点地区：贵州省麻江县'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }
}

