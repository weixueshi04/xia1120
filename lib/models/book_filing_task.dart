/// 古籍归档小游戏中的残片数据
class BookFragment {
  final String id;
  final String text;
  final String category; // 例如：四书 / 五经 / 史书

  const BookFragment({
    required this.id,
    required this.text,
    required this.category,
  });
}

/// 一局古籍归档任务
class FilingTask {
  final String id;
  final String title;
  final String description;
  final List<String> categories;
  final List<BookFragment> fragments;

  const FilingTask({
    required this.id,
    required this.title,
    required this.description,
    required this.categories,
    required this.fragments,
  });
}

