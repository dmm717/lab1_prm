
enum MessageRole { user, assistant }

class ChatMessage {
  final MessageRole role;
  String content;
  bool isStreaming;
  bool isError;

  ChatMessage({
    required this.role,
    required this.content,
    this.isStreaming = false,
    this.isError = false,
  });

  factory ChatMessage.user(String content) =>
      ChatMessage(role: MessageRole.user, content: content);

  factory ChatMessage.assistant(String content) =>
      ChatMessage(role: MessageRole.assistant, content: content);

  factory ChatMessage.streaming() =>
      ChatMessage(role: MessageRole.assistant, content: '', isStreaming: true);

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        role: json['role'] == 'user' ? MessageRole.user : MessageRole.assistant,
        content: json['content'] as String,
        isStreaming: json['isStreaming'] as bool? ?? false,
        isError: json['isError'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'role': role == MessageRole.user ? 'user' : 'assistant',
        'content': content,
        'isStreaming': isStreaming,
        'isError': isError,
      };
}
