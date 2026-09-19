import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
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

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
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
            // Top Decorative Gradient Strip
            Container(
              height: 2.5,
              decoration: const BoxDecoration(
                gradient: AppTheme.cardAccentGradient,
              ),
            ),

            // Header Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppTheme.border)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      gradient: AppTheme.mintPillGradient,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.primary.withValues(alpha: 0.25)),
                    ),
                    child: const Icon(Icons.forum_rounded, size: 15, color: AppTheme.primary),
                  ),
                  const SizedBox(width: 9),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Đối Thoại Bài Báo Thông Minh',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                      Text(
                        'Truy xuất ngữ cảnh bài báo qua Vector RAG (<500ms)',
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
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundSubtle,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: const Icon(Icons.file_download_outlined, size: 16, color: AppTheme.textSecondary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Tooltip(
                    message: 'Đặt lại cuộc trò chuyện',
                    child: InkWell(
                      onTap: () => controller.clearChat(),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundSubtle,
                          borderRadius: BorderRadius.circular(8),
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
                padding: const EdgeInsets.all(14),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  return _buildMessageBubble(message);
                },
              ),
            ),

            // Suggested Questions Pills (IMGRaD Framework)
            if (paper != null && !controller.isStreaming)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: const BoxDecoration(
                  color: AppTheme.backgroundSubtle,
                  border: Border(top: BorderSide(color: AppTheme.border)),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      const Icon(Icons.auto_awesome_rounded, size: 13, color: AppTheme.primary),
                      const SizedBox(width: 6),
                      Text(
                        'Hỏi theo IMGRaD:',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          color: AppTheme.textMuted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 6),
                      _buildQuickQuestionChip(
                        controller,
                        '📘 [I] Mục tiêu & Đặt vấn đề',
                        'Hãy phân tích chi tiết phần Đặt Vấn Đề & Mục Tiêu Nghiên Cứu (Introduction) của bài báo.',
                      ),
                      const SizedBox(width: 5),
                      _buildQuickQuestionChip(
                        controller,
                        '⚙️ [M] Phương pháp & Kỹ thuật',
                        'Hãy phân tích chi tiết Phương Pháp Luận & Thiết Kế Kỹ Thuật (Methodology) của bài báo.',
                      ),
                      const SizedBox(width: 5),
                      _buildQuickQuestionChip(
                        controller,
                        '📊 [R] Kết quả & Số liệu chính',
                        'Hãy tổng hợp các Kết Quả Thực Nghiệm & Số Liệu Phát Hiện (Results) quan trọng nhất.',
                      ),
                      const SizedBox(width: 5),
                      _buildQuickQuestionChip(
                        controller,
                        '💡 [D] Hạn chế & Thảo luận',
                        'Hãy phân tích các Thảo Luận, Hạn Chế Của Nghiên Cứu và Hướng Phát Triển (Discussion).',
                      ),
                      const SizedBox(width: 5),
                      _buildQuickQuestionChip(
                        controller,
                        '📌 Tóm tắt IMGRaD',
                        'Hãy tóm tắt toàn diện bài báo này theo 4 trụ cột IMGRaD (Introduction, Methodology, Results, Discussion).',
                      ),
                      const SizedBox(width: 5),
                      _buildQuickQuestionChip(
                        controller,
                        '🔑 Key word chính là j',
                        'Key word chính là j',
                      ),
                    ],
                  ),
                ),
              ),

            // Floating Dock Input Bar
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppTheme.border)),
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 3, 3, 3),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary, fontSize: 13),
                        decoration: InputDecoration(
                          isDense: true,
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          hintText: 'Hỏi về phương pháp, dữ liệu, công thức, kết quả...',
                          hintStyle: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 12.5),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 6),

                    // Button-in-Button Send CTA
                    InkWell(
                      onTap: controller.isStreaming ? null : _sendMessage,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          gradient: controller.isStreaming
                              ? const LinearGradient(colors: [AppTheme.textMuted, AppTheme.textMuted])
                              : AppTheme.emeraldGradient,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withValues(alpha: controller.isStreaming ? 0.0 : 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
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
      padding: const EdgeInsets.only(bottom: 12),
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
                gradient: AppTheme.mintPillGradient,
                border: Border.all(color: AppTheme.primary.withValues(alpha: 0.25)),
              ),
              child: const Icon(Icons.auto_awesome, size: 15, color: AppTheme.primary),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: isUser ? null : AppTheme.surface,
                gradient: isUser ? AppTheme.emeraldGradient : null,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(14),
                  topRight: const Radius.circular(14),
                  bottomLeft: Radius.circular(isUser ? 14 : 3),
                  bottomRight: Radius.circular(isUser ? 3 : 14),
                ),
                border: Border.all(
                  color: isUser ? AppTheme.primaryDark.withValues(alpha: 0.3) : AppTheme.border,
                ),
                boxShadow: isUser
                    ? [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.22),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : AppTheme.softShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.isStreaming && message.content.isEmpty) ...[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Đang trích xuất dữ liệu & suy luận câu trả lời...',
                          style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  ] else ...[
                    MarkdownBody(
                      data: message.content,
                      selectable: true,
                      styleSheet: MarkdownStyleSheet(
                        p: GoogleFonts.plusJakartaSans(
                          color: isUser ? Colors.white : AppTheme.textPrimary,
                          fontSize: 12.5,
                          height: 1.5,
                        ),
                        h1: GoogleFonts.plusJakartaSans(
                          color: isUser ? Colors.white : AppTheme.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                        h2: GoogleFonts.plusJakartaSans(
                          color: isUser ? Colors.white : AppTheme.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                        h3: GoogleFonts.plusJakartaSans(
                          color: isUser ? Colors.white : AppTheme.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                        code: GoogleFonts.jetBrainsMono(
                          backgroundColor: isUser
                              ? Colors.white.withValues(alpha: 0.15)
                              : AppTheme.backgroundSubtle,
                          color: isUser ? Colors.white : AppTheme.primaryDark,
                          fontSize: 11.5,
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
                              color: isUser ? Colors.white : AppTheme.primary,
                              width: 3,
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
            const SizedBox(width: 8),
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

  Widget _buildQuickQuestionChip(PaperController controller, String label, String query) {
    return InkWell(
      onTap: () {
        controller.sendMessage(query);
        _scrollToBottom();
      },
      borderRadius: BorderRadius.circular(99),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
        decoration: BoxDecoration(
          gradient: AppTheme.mintPillGradient,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: AppTheme.primaryDark,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 3),
            const Icon(Icons.north_east_rounded, size: 10, color: AppTheme.primary),
          ],
        ),
      ),
    );
  }
}

