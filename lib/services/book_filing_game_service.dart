import '../models/book_filing_task.dart';

/// 古籍归档小游戏核心逻辑
class BookFilingGameService {
  /// 创建一个简单的示例关卡
  FilingTask createDemoTask() {
    const fragments = <BookFragment>[
      BookFragment(
        id: 'lunyv_1',
        text: '学而时习之，不亦说乎？',
        category: '四书',
      ),
      BookFragment(
        id: 'mengzi_1',
        text: '得天下英才而教育之，三乐也。',
        category: '四书',
      ),
      BookFragment(
        id: 'shiji_1',
        text: '史记 · 项羽本纪',
        category: '史书',
      ),
      BookFragment(
        id: 'shijing_1',
        text: '关关雎鸠，在河之洲。',
        category: '诗经',
      ),
    ];

    return const FilingTask(
      id: 'demo_1',
      title: '整理经典文献',
      description: '请根据文献类别，将残片拖动到对应的分类盒中。',
      categories: ['四书', '诗经', '史书'],
      fragments: fragments,
    );
  }

  /// 校验某个残片是否被归入了正确的分类
  bool isCorrectCategory(BookFragment fragment, String targetCategory) {
    return fragment.category == targetCategory;
  }
}

