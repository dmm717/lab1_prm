enum MessageRole { user, assistant, system }

class ChatMessage {
  final String id;
  final MessageRole role;
  String content;
  final List<String> citations;
  final DateTime timestamp;
  bool isStreaming;
  bool isError;

  ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    this.citations = const [],
    DateTime? timestamp,
    this.isStreaming = false,
    this.isError = false,
  }) : timestamp = timestamp ?? DateTime.now();

  factory ChatMessage.user(String content) {
    return ChatMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      role: MessageRole.user,
      content: content,
    );
  }

  factory ChatMessage.assistant(String content, {List<String> citations = const []}) {
    return ChatMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      role: MessageRole.assistant,
      content: content,
      citations: citations,
    );
  }

  factory ChatMessage.streaming() {
    return ChatMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      role: MessageRole.assistant,
      content: '',
      isStreaming: true,
    );
  }
}
