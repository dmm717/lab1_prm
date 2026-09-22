import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../controllers/paper_controller.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/chat_panel.dart';
import '../widgets/grobid_status_badge.dart';
import '../widgets/local_pdf_bar.dart';
import '../widgets/paper_overview_panel.dart';
import '../widgets/recent_papers_dialog.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PaperController>();
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 72,
              padding: const EdgeInsets.symmetric(horizontal: 28),
              decoration: const BoxDecoration(
                color: AppTheme.surface,
                border: Border(bottom: BorderSide(color: AppTheme.border)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(Icons.menu_book_rounded,
                        color: Colors.white, size: 21),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('PaperChat',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary)),
                      Text('BÀN NGHIÊN CỨU',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.7,
                              color: AppTheme.textMuted)),
                    ],
                  ),
                  const SizedBox(width: 32),
                  Container(width: 1, height: 24, color: AppTheme.border),
                  const SizedBox(width: 20),
                  Text(
                      controller.hasPaper
                          ? 'Đang đọc tài liệu'
                          : 'Không gian làm việc',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary)),
                  const Spacer(),
                  const GrobidStatusBadge(),
                  const SizedBox(width: 16),
                  TextButton.icon(
                    onPressed: () => RecentPapersDialog.show(context),
                    icon: const Icon(Icons.library_books_outlined, size: 18),
                    label: Text(
                        'Thư viện${controller.recentPapers.isEmpty ? '' : '  ${controller.recentPapers.length}'}'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 22, 28, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const LocalPdfBar(),
                    const SizedBox(height: 18),
                    Expanded(
                      child: controller.hasPaper
                          ? LayoutBuilder(builder: (context, constraints) {
                              if (constraints.maxWidth < 780) {
                                return Column(children: [
                                  Expanded(
                                      child: PaperOverviewPanel(
                                          paper: controller.currentPaper!)),
                                  const SizedBox(height: 12),
                                  const Expanded(child: ChatPanel()),
                                ]);
                              }
                              return Row(children: [
                                Expanded(
                                    flex: 47,
                                    child: PaperOverviewPanel(
                                        paper: controller.currentPaper!)),
                                const SizedBox(width: 16),
                                const Expanded(flex: 53, child: ChatPanel()),
                              ]);
                            })
                          : _Welcome(controller: controller),
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
}

class _Welcome extends StatelessWidget {
  const _Welcome({required this.controller});
  final PaperController controller;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 850;
      final intro = Container(
        padding: const EdgeInsets.all(34),
        decoration: BoxDecoration(
            color: AppTheme.primary, borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('01 / BẮT ĐẦU',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                    color: const Color(0xFFB6D0C7))),
            const SizedBox(height: 18),
            Text('Đọc bài báo\nkhoa học rõ hơn.',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: wide ? 36 : 29,
                    height: 1.14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.3,
                    color: Colors.white)),
            const SizedBox(height: 18),
            Text(
                'Chọn PDF từ máy tính. GROBID trích xuất tiêu đề, tác giả, tóm tắt và từng mục nội dung để bạn đọc, tra cứu và đặt câu hỏi.',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    height: 1.65,
                    color: const Color(0xFFD5E4DE))),
            const SizedBox(height: 28),
            const Divider(color: Color(0xFF49675D)),
            const SizedBox(height: 16),
            Text('PDF LOCAL  →  GROBID / TEI  →  PHÂN TÍCH',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: const Color(0xFFB6D0C7))),
          ],
        ),
      );
      final guide = Container(
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('QUY TRÌNH',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.8,
                    color: AppTheme.primary)),
            const SizedBox(height: 22),
            _step('01', 'Chọn tài liệu PDF',
                'Mở bài báo khoa học được lưu trên máy.'),
            const SizedBox(height: 24),
            _step('02', 'Trích xuất bằng GROBID',
                'Nhận dữ liệu TEI có cấu trúc từ Docker local.'),
            const SizedBox(height: 24),
            _step('03', 'Đọc và hỏi đáp',
                'Xem các mục nghiên cứu và trò chuyện với AI khi backend đã cấu hình key.'),
            if (controller.recentPapers.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Divider(color: AppTheme.border),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () => RecentPapersDialog.show(context),
                icon: const Icon(Icons.history_rounded),
                label: Text(
                    'Mở lại ${controller.recentPapers.length} tài liệu đã lưu'),
              ),
            ],
          ],
        ),
      );
      if (!wide) {
        return SingleChildScrollView(
            child:
                Column(children: [intro, const SizedBox(height: 14), guide]));
      }
      return Row(children: [
        Expanded(flex: 5, child: intro),
        const SizedBox(width: 16),
        Expanded(flex: 4, child: guide)
      ]);
    });
  }

  Widget _step(String number, String title, String detail) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(number,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primary)),
          const SizedBox(width: 16),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(title,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary)),
                const SizedBox(height: 4),
                Text(detail,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        height: 1.5,
                        color: AppTheme.textSecondary)),
              ])),
        ],
      );
}
