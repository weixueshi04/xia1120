import 'dart:convert';

/// 设计模板类型
enum DesignTemplateType {
  product, // 文创产品设计
  experience, // 体验活动设计
  marketing, // 营销方案设计
}

/// 设计模板
class DesignTemplate {
  final String id;
  final String name;
  final String description;
  final DesignTemplateType type;
  final List<String> guidingQuestions; // 引导性问题
  final List<String> designElements; // 设计要素
  final Map<String, String> exampleSuggestions; // 示例建议

  DesignTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.guidingQuestions,
    required this.designElements,
    required this.exampleSuggestions,
  });
}

/// AI设计助手服务
class DesignAssistantService {
  static final DesignAssistantService _instance =
      DesignAssistantService._internal();
  factory DesignAssistantService() => _instance;
  DesignAssistantService._internal();

  /// 获取所有设计模板
  List<DesignTemplate> getAllTemplates() {
    return [
      // 文创产品设计模板
      DesignTemplate(
        id: 'batik_bookmark',
        name: '蜡染书签设计',
        description: '结合传统蜡染图案，设计现代感书签产品',
        type: DesignTemplateType.product,
        guidingQuestions: [
          '你希望书签的主要图案是什么？（花鸟、几何、人物等）',
          '你想要什么样的色彩风格？（传统蓝白、彩色、现代简约等）',
          '书签的目标用户是谁？（学生、文艺青年、商务人士等）',
          '你希望书签传达什么文化内涵？',
        ],
        designElements: [
          '蜡染纹样提取',
          '色彩方案设计',
          '形状与尺寸确定',
          '材质选择（纸质/金属/布艺）',
          '包装设计',
        ],
        exampleSuggestions: {
          '图案': '可以选择苗族传统的"蝴蝶妈妈"图腾，象征生命与传承',
          '色彩': '建议采用靛蓝+白色的经典配色，保持传统韵味',
          '形状': '建议设计成长条形（15cm×5cm），便于使用和携带',
          '文化': '在书签背面印制蜡染工艺小知识，增加文化教育价值',
        },
      ),
      DesignTemplate(
        id: 'silver_jewelry',
        name: '苗银饰品创新设计',
        description: '将苗族银饰元素融入现代首饰设计',
        type: DesignTemplateType.product,
        guidingQuestions: [
          '你想设计什么类型的银饰？（耳环、手链、胸针、项链等）',
          '你希望保留哪些苗族银饰的特色元素？',
          '目标用户的年龄层和消费场景是什么？',
          '你倾向于传统风格还是现代简约风格？',
        ],
        designElements: [
          '银饰元素提取与简化',
          '现代设计语言融合',
          '佩戴舒适度考虑',
          '工艺可行性分析',
          '价格定位',
        ],
        exampleSuggestions: {
          '元素': '可提取苗族银饰的"花鸟纹"、"龙凤纹"等经典纹样',
          '风格': '建议采用几何化简化处理，适合现代审美',
          '工艺': '结合传统錾刻工艺+现代抛光技术',
          '定位': '建议定位为轻奢文创，价格300-800元',
        },
      ),
      DesignTemplate(
        id: 'textile_bag',
        name: '蜡染帆布包设计',
        description: '将蜡染图案应用到实用帆布包上',
        type: DesignTemplateType.product,
        guidingQuestions: [
          '帆布包的使用场景是什么？（日常通勤、旅行、购物等）',
          '你希望蜡染图案覆盖整个包还是局部点缀？',
          '包的容量和尺寸有什么要求？',
          '希望添加哪些实用功能？（内袋、拉链、可调节背带等）',
        ],
        designElements: [
          '蜡染图案布局设计',
          '包型与尺寸确定',
          '功能性设计',
          '帆布材质选择',
          '配色方案',
        ],
        exampleSuggestions: {
          '图案': '建议采用对称式蜡染纹样，居中或满版印花',
          '尺寸': '推荐38cm×32cm×10cm，可容纳A4文件和日常用品',
          '功能': '内部设置手机袋、钥匙扣，外部拉链袋',
          '材质': '选用12安厚帆布，耐用且环保',
        },
      ),

      // 体验活动设计模板
      DesignTemplate(
        id: 'batik_workshop',
        name: '蜡染手工体验工作坊',
        description: '设计一场沉浸式蜡染制作体验活动',
        type: DesignTemplateType.experience,
        guidingQuestions: [
          '活动的目标人群是谁？（家庭、学生、企业团建等）',
          '活动时长预计多久？（1-2小时、半天、全天等）',
          '希望参与者体验哪些环节？',
          '活动场地有什么限制？',
        ],
        designElements: [
          '活动流程设计',
          '体验环节规划',
          '讲解内容准备',
          '材料工具清单',
          '成果展示形式',
        ],
        exampleSuggestions: {
          '流程': '文化讲解（15分钟）→示范教学（20分钟）→动手体验（60分钟）→作品展示（15分钟）',
          '环节': '包括画蜡、染色、脱蜡三个核心步骤',
          '成果': '每人完成一条蜡染手帕或小方巾，可带走留念',
          '人数': '建议15-20人/场，确保指导质量',
        },
      ),
      DesignTemplate(
        id: 'heritage_tour',
        name: '麻江非遗研学路线',
        description: '策划一条深度体验麻江非遗的研学路线',
        type: DesignTemplateType.experience,
        guidingQuestions: [
          '研学的时长是多久？（一日游、二日游等）',
          '参与者主要是什么群体？（中小学生、大学生、成人等）',
          '希望重点体验哪些非遗项目？',
          '对住宿和餐饮有什么要求？',
        ],
        designElements: [
          '景点/体验点选择',
          '时间行程安排',
          '学习任务设计',
          '导览讲解内容',
          '配套服务安排',
        ],
        exampleSuggestions: {
          '路线': '早上：蜡染博物馆参观 → 中午：苗家特色餐 → 下午：银饰工坊体验 → 晚上：篝火晚会',
          '任务': '设计研学手册，包含观察记录、手工体验、文化思考等模块',
          '讲解': '每个点配备1名文化讲解员+1名技艺传承人',
          '服务': '提供研学证书、纪念品、特色餐饮',
        },
      ),

      // 营销方案设计模板
      DesignTemplate(
        id: 'live_streaming',
        name: '非遗直播带货脚本',
        description: '策划一场非遗文创产品的直播带货活动',
        type: DesignTemplateType.marketing,
        guidingQuestions: [
          '直播的主推产品是什么？',
          '直播时长预计多久？',
          '有哪些亮点可以吸引观众？（传承人出镜、制作演示等）',
          '目标销售额和优惠策略是什么？',
        ],
        designElements: [
          '直播流程脚本',
          '产品介绍话术',
          '互动环节设计',
          '优惠促销策略',
          '场景布置方案',
        ],
        exampleSuggestions: {
          '开场': '以苗族传统歌舞开场，营造文化氛围（3分钟）',
          '讲解': '邀请蜡染传承人现场演示，讲述技艺故事（10分钟）',
          '互动': '设置答题抢红包、抽奖送产品等互动环节',
          '促销': '前100名下单享8折，满500元送蜡染小方巾',
          '场景': '搭建苗族传统工坊场景，展示原汁原味的制作环境',
        },
      ),
      DesignTemplate(
        id: 'social_media',
        name: '非遗社交媒体传播方案',
        description: '设计非遗文化的社交媒体内容传播策略',
        type: DesignTemplateType.marketing,
        guidingQuestions: [
          '主要使用哪些社交媒体平台？（抖音、小红书、微信等）',
          '内容的核心主题是什么？',
          '目标受众是谁？',
          '希望达到什么样的传播效果？',
        ],
        designElements: [
          '内容选题策划',
          '视觉风格定位',
          '发布节奏规划',
          '互动话题设计',
          'KOL合作策略',
        ],
        exampleSuggestions: {
          '选题': '技艺揭秘、传承人故事、产品开箱、用户UGC等系列内容',
          '风格': '采用温暖治愈的视觉风格，突出手工质感',
          '节奏': '每周3-5条，重点内容配合热点事件发布',
          '话题': '#非遗新生活 #手艺人的温度 #文化好物推荐',
          'KOL': '寻找文化类、手工类、生活方式类博主合作',
        },
      ),
    ];
  }

  /// 根据类型获取模板
  List<DesignTemplate> getTemplatesByType(DesignTemplateType type) {
    return getAllTemplates().where((t) => t.type == type).toList();
  }

  /// 根据ID获取模板
  DesignTemplate? getTemplateById(String id) {
    try {
      return getAllTemplates().firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }

  /// 生成设计建议
  String generateDesignSuggestion({
    required DesignTemplate template,
    required Map<String, String> userAnswers,
  }) {
    final buffer = StringBuffer();

    buffer.writeln('## ${template.name}设计建议\n');
    buffer.writeln('${template.description}\n');
    buffer.writeln('### 📋 你的设计需求\n');

    // 整理用户回答
    int questionIndex = 0;
    userAnswers.forEach((question, answer) {
      questionIndex++;
      buffer.writeln('**问题$questionIndex**: $question');
      buffer.writeln('**你的回答**: $answer\n');
    });

    buffer.writeln('### 💡 专业设计建议\n');

    // 根据模板提供建议
    template.exampleSuggestions.forEach((key, suggestion) {
      buffer.writeln('**$key建议**');
      buffer.writeln('$suggestion\n');
    });

    buffer.writeln('### 🎯 设计要素清单\n');
    for (var i = 0; i < template.designElements.length; i++) {
      buffer.writeln('${i + 1}. ${template.designElements[i]}');
    }

    buffer.writeln('\n### 📝 下一步行动\n');
    buffer.writeln('1. 根据以上建议，绘制初步设计草图');
    buffer.writeln('2. 考虑材料成本和工艺可行性');
    buffer.writeln('3. 制作样品进行测试和优化');
    buffer.writeln('4. 准备产品故事和宣传文案');

    return buffer.toString();
  }

  /// 智能匹配设计模板
  DesignTemplate? matchTemplate(String userQuery) {
    final query = userQuery.toLowerCase();

    // 关键词匹配
    final templates = getAllTemplates();

    for (final template in templates) {
      if (query.contains(template.name.toLowerCase())) {
        return template;
      }

      // 检查关键词
      final keywords = _getTemplateKeywords(template);
      for (final keyword in keywords) {
        if (query.contains(keyword)) {
          return template;
        }
      }
    }

    return null;
  }

  /// 获取模板相关关键词
  List<String> _getTemplateKeywords(DesignTemplate template) {
    switch (template.id) {
      case 'batik_bookmark':
        return ['书签', '蜡染', '文具'];
      case 'silver_jewelry':
        return ['银饰', '首饰', '耳环', '手链', '胸针', '项链'];
      case 'textile_bag':
        return ['帆布包', '手提袋', '包'];
      case 'batik_workshop':
        return ['工作坊', '体验', '手工', '蜡染体验'];
      case 'heritage_tour':
        return ['研学', '路线', '旅游', '一日游'];
      case 'live_streaming':
        return ['直播', '带货', '营销'];
      case 'social_media':
        return ['社交媒体', '传播', '推广', '抖音', '小红书'];
      default:
        return [];
    }
  }

  /// 获取引导性开场白
  String getGreeting() {
    return '你好！我是AI设计助手，可以帮你：\n\n'
        '🎨 **设计文创产品**（书签、银饰、帆布包等）\n'
        '🎯 **策划体验活动**（工作坊、研学路线）\n'
        '📣 **制定营销方案**（直播脚本、社交媒体）\n\n'
        '告诉我你想设计什么，我会引导你一步步完成创意！';
  }

  /// 获取快速入口选项
  List<Map<String, String>> getQuickOptions() {
    return [
      {'icon': '📚', 'label': '蜡染书签', 'templateId': 'batik_bookmark'},
      {'icon': '💍', 'label': '苗银饰品', 'templateId': 'silver_jewelry'},
      {'icon': '👜', 'label': '帆布包', 'templateId': 'textile_bag'},
      {'icon': '🎨', 'label': '手工体验', 'templateId': 'batik_workshop'},
      {'icon': '🧭', 'label': '研学路线', 'templateId': 'heritage_tour'},
      {'icon': '📺', 'label': '直播脚本', 'templateId': 'live_streaming'},
    ];
  }
}
