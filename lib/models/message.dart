/// 聊天消息模型
class Message {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final MessageStatus status;
  final MessageCategory? category; // ⬅️ 新增：消息分类

  Message({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.status = MessageStatus.sent,
    this.category, // ⬅️ 可选参数
  });

  factory Message.user(String content) {
    return Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      isUser: true,
      timestamp: DateTime.now(),
    );
  }

  factory Message.assistant(String content, {
    MessageStatus status = MessageStatus.sent,
    MessageCategory? category, // ⬅️ 新增参数
  }) {
    return Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      isUser: false,
      timestamp: DateTime.now(),
      status: status,
      category: category,
    );
  }

  Message copyWith({MessageStatus? status, MessageCategory? category}) {
    return Message(
      id: id,
      content: content,
      isUser: isUser,
      timestamp: timestamp,
      status: status ?? this.status,
      category: category ?? this.category,
    );
  }
}

enum MessageStatus {
  sending,
  sent,
  error,
}

/// 消息分类（用于边框颜色和知识盲盒）
enum MessageCategory {
  culture,     // 非遗文化 - 靛蓝色
  agriculture, // 农业知识 - 绿色
  education,   // 教育辅导 - 金色
  story,       // 故事对话 - 枫红色
}
