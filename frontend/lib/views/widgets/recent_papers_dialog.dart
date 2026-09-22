import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../controllers/paper_controller.dart';
import '../../core/theme/app_theme.dart';

class RecentPapersDialog extends StatelessWidget {
  const RecentPapersDialog({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const RecentPapersDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PaperController>();
    final papers = controller.recentPapers;

    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: AppTheme.border),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 580),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: AppTheme.primarySubtle,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.bookmark_added_rounded,
                        color: AppTheme.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Thư Viện Bài Báo Đã Lưu',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                      Text(
                        '${papers.length} bài báo đã lưu để đọc ngoại tuyến',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 12, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        size: 20, color: AppTheme.textMuted),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: AppTheme.border),
              const SizedBox(height: 8),

              // Papers List
              Expanded(
                child: papers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.folder_open_rounded,
                              size: 48,
                              color: AppTheme.textMuted.withValues(alpha: 0.4),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Chưa có bài báo nào được lưu',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Chọn tệp PDF trên máy tính để trích xuất bằng GROBID và lưu vào thư viện.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12, color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: papers.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final paper = papers[index];
                          final isCurrent =
                              controller.currentPaper?.id == paper.id;

                          return InkWell(
                            onTap: () {
                              controller.selectRecentPaper(paper);
                              Navigator.of(context).pop();
                            },
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: isCurrent
                                    ? AppTheme.primarySubtle
                                    : AppTheme.backgroundSubtle,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isCurrent
                                      ? AppTheme.primary.withValues(alpha: 0.3)
                                      : AppTheme.border,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2.0),
                                    child: Icon(
                                      isCurrent
                                          ? Icons.bookmark_rounded
                                          : Icons.bookmark_border_rounded,
                                      size: 20,
                                      color: isCurrent
                                          ? AppTheme.primary
                                          : AppTheme.textMuted,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          paper.title,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w700,
                                            color: isCurrent
                                                ? AppTheme.primary
                                                : AppTheme.textPrimary,
                                            height: 1.3,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 7,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                                border: Border.all(
                                                    color: AppTheme.border),
                                              ),
                                              child: Text(
                                                paper.sourceId,
                                                style:
                                                    GoogleFonts.plusJakartaSans(
                                                  fontSize: 10,
                                                  color: AppTheme.primaryDark,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                            if (paper.isFallback) ...[
                                              const SizedBox(width: 6),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 7,
                                                        vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.warningSubtle,
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                  border: Border.all(
                                                      color: AppTheme.warning
                                                          .withValues(
                                                              alpha: 0.3)),
                                                ),
                                                child: Text(
                                                  'Gemini Dự Phòng',
                                                  style: GoogleFonts
                                                      .plusJakartaSans(
                                                    fontSize: 10,
                                                    color: AppTheme.warning,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                            ],
                                            if (paper.authors.isNotEmpty) ...[
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  paper.authors.join(', '),
                                                  style: GoogleFonts
                                                      .plusJakartaSans(
                                                    fontSize: 11,
                                                    color: AppTheme.textMuted,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Xóa khỏi thư viện',
                                    icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        size: 18,
                                        color: AppTheme.textMuted),
                                    onPressed: () {
                                      controller.deleteRecentPaper(paper.id);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
