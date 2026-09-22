import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:provider/provider.dart';
import '../../controllers/paper_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../models/chat_message.dart';

class ChatPanel extends StatefulWidget {
  const ChatPanel({super.key});

  @override
  State<ChatPanel> createState() => _ChatPanelState();
}

class _ChatPanelState extends State<ChatPanel> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _lastPaperId;
  int _lastMessageCount = 0;
  int _lastMessageLength = 0;

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isNotEmpty) {
      context.read<PaperController>().sendMessage(text);
      _textController.clear();
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PaperController>();
    final messages = controller.messages;
    final paper = controller.currentPaper;
    final latestLength = messages.isEmpty ? 0 : messages.last.content.length;
    final paperChanged = _lastPaperId != paper?.id;
    final hasNewMessage = paperChanged || messages.length != _lastMessageCount;
    final contentChanged = latestLength != _lastMessageLength;
    final nearBottom = !_scrollController.hasClients ||
        _scrollController.position.maxScrollExtent -
                _scrollController.position.pixels <
            120;
    if (hasNewMessage || (contentChanged && nearBottom)) {
      _scrollToBottom();
    }
    _lastPaperId = paper?.id;
    _lastMessageCount = messages.length;
    _lastMessageLength = latestLength;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border, width: 1),
        boxShadow: AppTheme.softShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            // Top Accent Strip
            Container(
              height: 3,
              decoration: const BoxDecoration(
                gradient: AppTheme.cardAccentGradient,
              ),
            ),

            // Header Bar (Claude Style)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: AppTheme.surfaceVariant,
                border: Border(bottom: BorderSide(color: AppTheme.border)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppTheme.primarySubtle,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.primary.withValues(alpha: 0.25)),
                    ),
                    child: const Icon(Icons.forum_rounded, size: 16, color: AppTheme.primaryDark),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Đối Thoại Bài Báo Thông Minh',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        'Hỏi đáp chuẩn xác theo nội dung PDF đã trích xuất',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          color: AppTheme.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Tooltip(
                    message: 'Xuất cuộc trò chuyện (Markdown)',
                    child: InkWell(
                      onTap: () {
                        final md = controller.exportChatAsMarkdown();
                        if (md.isNotEmpty) {
                          Clipboard.setData(ClipboardData(text: md));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Toàn bộ nội dung trò chuyện đã được sao chép dưới dạng Markdown!',
                                style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 13),
                              ),
                              backgroundColor: AppTheme.textPrimary,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: const Icon(Icons.file_download_outlined, size: 16, color: AppTheme.textSecondary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Tooltip(
                    message: 'Đặt lại cuộc trò chuyện',
                    child: InkWell(
                      onTap: () => controller.clearChat(),
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: const Icon(Icons.restart_alt_rounded, size: 16, color: AppTheme.textSecondary),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Message List
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  return _buildMessageBubble(message);
                },
              ),
            ),

            // Suggested Questions Pills (Claude Style Pastels)
            if (paper != null && !controller.isStreaming)
              Container(
                decoration: const BoxDecoration(
                  color: AppTheme.surfaceVariant,
                  border: Border(top: BorderSide(color: AppTheme.border)),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(14, 8, 16, 8),
                  child: Row(
                    children: [
                      const Icon(Icons.auto_awesome_rounded, size: 14, color: AppTheme.primaryDark),
                      const SizedBox(width: 6),
                      Text(
                        'Gợi ý IMGRaD:',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: AppTheme.textMuted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildQuickQuestionChip(
                        controller,
                        '📘 [I] Đặt vấn đề',
                        'Hãy phân tích chi tiết phần Đặt Vấn Đề & Mục Tiêu Nghiên Cứu (Introduction) của bài báo.',
                        const Color(0xFFEBF3FA),
                        const Color(0xFF2B5885),
                      ),
                      const SizedBox(width: 6),
                      _buildQuickQuestionChip(
                        controller,
                        '⚙️ [M] Phương pháp',
                        'Hãy phân tích chi tiết Phương Pháp Luận & Thiết Kế Kỹ Thuật (Methodology) của bài báo.',
                        const Color(0xFFEDF3EC),
                        const Color(0xFF2F5D38),
                      ),
                      const SizedBox(width: 6),
                      _buildQuickQuestionChip(
                        controller,
                        '📊 [R] Kết quả',
                        'Hãy tổng hợp các Kết Quả Thực Nghiệm & Số Liệu Phát Hiện (Results) quan trọng nhất.',
                        const Color(0xFFFDF2EE),
                        const Color(0xFFB54F2B),
                      ),
                      const SizedBox(width: 6),
                      _buildQuickQuestionChip(
                        controller,
                        '💡 [D] Hạn chế & Thảo luận',
                        'Hãy phân tích các Thảo Luận, Hạn Chế Của Nghiên Cứu và Hướng Phát Triển (Discussion).',
                        const Color(0xFFF4F0F9),
                        const Color(0xFF5E3D85),
                      ),
                      const SizedBox(width: 6),
                      _buildQuickQuestionChip(
                        controller,
                        '📌 Tóm tắt toàn diện',
                        'Hãy tóm tắt toàn diện bài báo này theo 4 trụ cột IMGRaD (Introduction, Methodology, Results, Discussion).',
                        AppTheme.primarySubtle,
                        AppTheme.primaryDark,
                      ),
                      const SizedBox(width: 14),
                    ],
                  ),
                ),
              ),

            // Floating Input Bar (Claude Style)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: AppTheme.surfaceVariant,
                border: Border(top: BorderSide(color: AppTheme.border)),
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 4, 4, 4),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                  boxShadow: AppTheme.softShadow,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary, fontSize: 13.5),
                        decoration: InputDecoration(
                          isDense: true,
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          hintText: 'Hỏi về phương pháp, thuật toán, công thức, kết quả...',
                          hintStyle: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 13),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Claude Style Send Button
                    InkWell(
                      onTap: controller.isStreaming ? null : _sendMessage,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: controller.isStreaming
                              ? AppTheme.textMuted
                              : AppTheme.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: controller.isStreaming
                            ? const Padding(
                                padding: EdgeInsets.all(9.0),
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.arrow_upward_rounded, size: 18, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.role == MessageRole.user;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: AppTheme.primarySubtle,
                border: Border.all(color: AppTheme.primary.withValues(alpha: 0.25)),
              ),
              child: const Icon(Icons.auto_awesome, size: 15, color: AppTheme.primaryDark),
            ),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? AppTheme.textPrimary : AppTheme.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(14),
                  topRight: const Radius.circular(14),
                  bottomLeft: Radius.circular(isUser ? 14 : 3),
                  bottomRight: Radius.circular(isUser ? 3 : 14),
                ),
                border: Border.all(
                  color: isUser
                      ? AppTheme.textPrimary
                      : AppTheme.border,
                ),
                boxShadow: AppTheme.softShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.isStreaming && message.content.isEmpty) ...[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 13,
                          height: 13,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryDark),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'AI đang trích xuất dữ liệu & suy luận...',
                          style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  ] else ...[
                    MarkdownBody(
                      data: message.content,
                      selectable: true,
                      inlineSyntaxes: [
                        _DisplayMathSyntax(),
                        _InlineMathSyntax(),
                      ],
                      builders: {
                        'math': _MathElementBuilder(),
                        'math-display': _MathElementBuilder(display: true),
                      },
                      styleSheet: MarkdownStyleSheet(
                        horizontalRuleDecoration: const BoxDecoration(
                          border: Border(top: BorderSide(color: AppTheme.border)),
                        ),
                        p: GoogleFonts.plusJakartaSans(
                          color: isUser ? Colors.white : AppTheme.textPrimary,
                          fontSize: 13,
                          height: 1.55,
                        ),
                        h1: GoogleFonts.plusJakartaSans(
                          color: isUser ? Colors.white : AppTheme.textPrimary,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                        ),
                        h2: GoogleFonts.plusJakartaSans(
                          color: isUser ? Colors.white : AppTheme.textPrimary,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                        ),
                        h3: GoogleFonts.plusJakartaSans(
                          color: isUser ? Colors.white : AppTheme.textPrimary,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                        code: GoogleFonts.jetBrainsMono(
                          backgroundColor: isUser
                              ? Colors.white.withValues(alpha: 0.15)
                              : AppTheme.backgroundSubtle,
                          color: isUser ? Colors.white : AppTheme.primaryDark,
                          fontSize: 12,
                        ),
                        codeblockDecoration: BoxDecoration(
                          color: isUser ? Colors.black.withValues(alpha: 0.2) : AppTheme.backgroundSubtle,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isUser ? Colors.white.withValues(alpha: 0.2) : AppTheme.border,
                          ),
                        ),
                        blockquoteDecoration: BoxDecoration(
                          border: Border(
                            left: BorderSide(
                              color: isUser ? Colors.white : AppTheme.primaryDark,
                              width: 3.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 10),
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: AppTheme.backgroundSubtle,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.border),
              ),
              child: const Icon(Icons.person_rounded, size: 16, color: AppTheme.textSecondary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickQuestionChip(
      PaperController controller, String label, String query, Color bgColor, Color textColor) {
    return InkWell(
      onTap: () {
        controller.sendMessage(query);
        _scrollToBottom();
      },
      borderRadius: BorderRadius.circular(99),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: textColor.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.north_east_rounded, size: 11, color: textColor),
          ],
        ),
      ),
    );
  }
}

class _InlineMathSyntax extends md.InlineSyntax {
  _InlineMathSyntax() : super(r'\$([^$\n]+)\$', startCharacter: 0x24);

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    parser.addNode(md.Element.text('math', match[1]!));
    return true;
  }
}

class _DisplayMathSyntax extends md.InlineSyntax {
  _DisplayMathSyntax() : super(r'\$\$([^$]+)\$\$', startCharacter: 0x24);

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    parser.addNode(md.Element.text('math-display', match[1]!));
    return true;
  }
}

class _MathElementBuilder extends MarkdownElementBuilder {
  _MathElementBuilder({this.display = false});

  final bool display;

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final expression = element.textContent;
    final mathWidget = Math.tex(
      expression,
      mathStyle: display ? MathStyle.display : MathStyle.text,
      textStyle: parentStyle,
      onErrorFallback: (_) => Text(
        expression,
        style: parentStyle,
      ),
    );

    if (display) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: mathWidget,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: mathWidget,
      ),
    );
  }
}
