import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../controllers/paper_controller.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/app_logo.dart';
import '../widgets/chat_panel.dart';
import '../widgets/grobid_status_badge.dart';
import '../widgets/paper_overview_panel.dart';
import '../widgets/recent_papers_dialog.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _pickPdf(BuildContext context) async {
    try {
      final files = await FilePicker.pickFiles(
          type: FileType.custom, allowedExtensions: ['pdf']);
      if (files.isEmpty || !context.mounted) return;
      final file = files.single;
      final bytes = await file.readAsBytes();
      if (context.mounted) {
        await context.read<PaperController>().processLocalPdf(bytes, file.name);
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Không mở được PDF: $error')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PaperController>();
    final busy = controller.stage != IngestionStage.idle &&
        controller.stage != IngestionStage.completed &&
        controller.stage != IngestionStage.error;
    final paper = controller.currentPaper;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // FLOATING DUAL-ISLAND HEADER BAR
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Row(
                children: [
                  // LEFT FLOATING ISLAND: Logo & Document Context
                  Expanded(
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(color: AppTheme.border),
                        boxShadow: AppTheme.floatingShadow,
                      ),
                      child: Row(
                        children: [
                          // Logo Shell
                          InkWell(
                            onTap: () => controller.hasPaper ? controller.closeCurrentPaper() : null,
                            borderRadius: BorderRadius.circular(99),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const AppLogo(size: 28),
                                const SizedBox(width: 8),
                                Text(
                                  'PaperChat',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.textPrimary,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primarySubtle,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'AI',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      color: AppTheme.primaryDark,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 12),
                          Container(width: 1, height: 16, color: AppTheme.border),
                          const SizedBox(width: 12),

                          // Document Context Tag & Title
                          Expanded(
                            child: paper != null
                                ? Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primarySubtle,
                                          borderRadius: BorderRadius.circular(99),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.picture_as_pdf_rounded,
                                                size: 10, color: AppTheme.primaryDark),
                                            const SizedBox(width: 3),
                                            Text(
                                              paper.sourceId.isEmpty ? 'PDF' : paper.sourceId,
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                color: AppTheme.primaryDark,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Tooltip(
                                          message: paper.title,
                                          child: Text(
                                            paper.title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w600,
                                              color: AppTheme.textPrimary,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : Text(
                                    'Không gian làm việc bài báo local',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.textMuted,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // RIGHT FLOATING ISLAND: Action Controls & Status
                  Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: AppTheme.border),
                      boxShadow: AppTheme.floatingShadow,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // PDF Control Pill Action
                        if (paper != null) ...[
                          Container(
                            height: 30,
                            decoration: BoxDecoration(
                              color: AppTheme.backgroundSubtle,
                              borderRadius: BorderRadius.circular(99),
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                InkWell(
                                  onTap: busy ? null : () => _pickPdf(context),
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(99),
                                    bottomLeft: Radius.circular(99),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 9),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.folder_open_rounded,
                                            size: 13, color: AppTheme.primaryDark),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Đổi PDF',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: AppTheme.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Container(width: 1, height: 14, color: AppTheme.border),
                                InkWell(
                                  onTap: busy ? null : controller.closeCurrentPaper,
                                  borderRadius: const BorderRadius.only(
                                    topRight: Radius.circular(99),
                                    bottomRight: Radius.circular(99),
                                  ),
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 6),
                                    child: Icon(Icons.close_rounded,
                                        size: 13, color: AppTheme.textMuted),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                        ] else ...[
                          InkWell(
                            onTap: busy ? null : () => _pickPdf(context),
                            borderRadius: BorderRadius.circular(99),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppTheme.primary,
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.add_rounded, size: 14, color: Colors.white),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Chọn PDF',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],

                        // GROBID LED Status Badge
                        const GrobidStatusBadge(),
                        const SizedBox(width: 8),

                        // Library Button Pill
                        InkWell(
                          onTap: () => RecentPapersDialog.show(context),
                          borderRadius: BorderRadius.circular(99),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppTheme.backgroundSubtle,
                              borderRadius: BorderRadius.circular(99),
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.library_books_outlined,
                                    size: 13, color: AppTheme.primaryDark),
                                const SizedBox(width: 4),
                                Text(
                                  'Thư viện${controller.recentPapers.isEmpty ? '' : ' (${controller.recentPapers.length})'}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Ingestion Progress Indicator (If Processing PDF)
            if (busy)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppTheme.primaryDark),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          controller.statusMessage,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                      Text(
                        '${controller.progressPercentage}%',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primaryDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Workspace Main View Panels
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
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
                              flex: 48,
                              child: PaperOverviewPanel(
                                  paper: controller.currentPaper!)),
                          const SizedBox(width: 14),
                          const Expanded(flex: 52, child: ChatPanel()),
                        ]);
                      })
                    : _Welcome(controller: controller, onPickPdf: () => _pickPdf(context)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Welcome extends StatelessWidget {
  const _Welcome({required this.controller, required this.onPickPdf});
  final PaperController controller;
  final VoidCallback onPickPdf;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 850;
      final intro = Container(
        padding: const EdgeInsets.all(36),
        decoration: BoxDecoration(
          color: AppTheme.primarySubtle,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
          boxShadow: AppTheme.softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
              ),
              child: Text(
                '01 / NỀN TẢNG PHÂN TÍCH BÀI BÁO AI',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  color: AppTheme.primaryDark,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Trích xuất & Đặt câu hỏi\nvới Bài Báo Khoa Học',
              style: GoogleFonts.plusJakartaSans(
                fontSize: wide ? 36 : 28,
                height: 1.15,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.2,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Tải bài báo PDF local của bạn lên. Động cơ GROBID trích xuất toàn bộ cấu trúc văn bản, thuật toán, kết quả thực nghiệm và bảng biểu để bạn sẵn sàng đối thoại với AI.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                height: 1.65,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: onPickPdf,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.upload_file_rounded, size: 18),
              label: Text(
                'Tải PDF bài báo lên ngay',
                style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 20),
            const Divider(color: AppTheme.border),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.verified_user_outlined, size: 15, color: AppTheme.primaryDark),
                const SizedBox(width: 8),
                Text(
                  'BẢO MẬT TUYỆT ĐỐI · PDF CHỈ XỬ LÝ LƯU TRỮ TRÊN MÁY TÍNH LOCAL',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
      );

      final guide = Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
          boxShadow: AppTheme.softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'QUY TRÌNH SỬ DỤNG DỄ DÀNG',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.8,
                color: AppTheme.primaryDark,
              ),
            ),
            const SizedBox(height: 22),
            _step('01', 'Chọn bài báo PDF local',
                'Mở bất kỳ bài báo khoa học dạng PDF trên máy tính của bạn.'),
            const SizedBox(height: 22),
            _step('02', 'Bóc tách cấu trúc với GROBID',
                'Docker GROBID tự động nhận diện tiêu đề, tác giả, tóm tắt và 4 trụ cột IMGRaD.'),
            const SizedBox(height: 22),
            _step('03', 'Hỏi đáp & Trích xuất cùng AI',
                'Trò chuyện với AI Gemini theo ngữ cảnh chính xác của bài báo.'),
            if (controller.recentPapers.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Divider(color: AppTheme.border),
              const SizedBox(height: 14),
              InkWell(
                onTap: () => RecentPapersDialog.show(context),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundSubtle,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.history_rounded, size: 16, color: AppTheme.primaryDark),
                      const SizedBox(width: 8),
                      Text(
                        'Xem lại ${controller.recentPapers.length} bài báo đã trích xuất',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      );

      if (!wide) {
        return SingleChildScrollView(
            child: Column(children: [intro, const SizedBox(height: 14), guide]));
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppTheme.primarySubtle,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
            ),
            child: Text(
              number,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: AppTheme.primaryDark,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  detail,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    height: 1.5,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
}
