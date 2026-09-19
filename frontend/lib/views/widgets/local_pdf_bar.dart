import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../controllers/paper_controller.dart';
import '../../core/theme/app_theme.dart';

class LocalPdfBar extends StatelessWidget {
  const LocalPdfBar({super.key});

  Future<void> _pickAndUploadPdf(BuildContext context) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result.isNotEmpty) {
      final file = result.single;
      final bytes = await file.readAsBytes();
      if (context.mounted) {
        context.read<PaperController>().processLocalPdf(bytes, file.name);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PaperController>();
    final isBusy = controller.stage != IngestionStage.idle &&
        controller.stage != IngestionStage.completed &&
        controller.stage != IngestionStage.error;

    if (controller.hasPaper) {
      return _buildActivePaperBar(context, controller, isBusy);
    }

    return _buildUploadHub(context, controller, isBusy);
  }

  Widget _buildActivePaperBar(BuildContext context, PaperController controller, bool isBusy) {
    final paper = controller.currentPaper!;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border, width: 1),
        boxShadow: AppTheme.softShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          children: [
            Container(
              height: 2.5,
              decoration: const BoxDecoration(
                gradient: AppTheme.cardAccentGradient,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      gradient: AppTheme.mintPillGradient,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.primary.withValues(alpha: 0.25)),
                    ),
                    child: const Icon(Icons.picture_as_pdf_rounded, size: 16, color: AppTheme.primary),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                gradient: AppTheme.emeraldGradient,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'FILE PDF LOCAL',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                paper.sourceId.endsWith('.pdf') ? paper.sourceId : '${paper.sourceId}.pdf',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Cấu trúc IMGRaD: Introduction • Methodology • Results • Discussion (${paper.sections.length} phân đoạn)',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: AppTheme.textMuted,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Open Another PDF Button
                  InkWell(
                    onTap: isBusy ? null : () => _pickAndUploadPdf(context),
                    borderRadius: BorderRadius.circular(99),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        gradient: AppTheme.emeraldGradient,
                        borderRadius: BorderRadius.circular(99),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.file_upload_outlined, size: 15, color: Colors.white),
                          const SizedBox(width: 6),
                          Text(
                            isBusy ? 'Đang Xử Lý...' : 'Mở File PDF Khác',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Close Paper Button
                  Tooltip(
                    message: 'Đóng bài báo này',
                    child: InkWell(
                      onTap: isBusy ? null : () => controller.closeCurrentPaper(),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundSubtle,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: const Icon(Icons.close_rounded, size: 16, color: AppTheme.textMuted),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadHub(BuildContext context, PaperController controller, bool isBusy) {
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
            Container(
              height: 3,
              decoration: const BoxDecoration(
                gradient: AppTheme.cardAccentGradient,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          gradient: AppTheme.mintPillGradient,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                        ),
                        child: const Icon(Icons.upload_file_rounded, size: 22, color: AppTheme.primary),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Nạp Bài Báo Khoa Học (Tệp PDF Local)',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.textPrimary,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primarySubtle,
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                  child: Text(
                                    'CHUẨN IMGRaD',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.primaryDark,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Chọn tệp .PDF từ máy tính để phân tích theo 4 trụ cột: Introduction • Methodology • Results • Discussion',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Primary Pick PDF Button
                      InkWell(
                        onTap: isBusy ? null : () => _pickAndUploadPdf(context),
                        borderRadius: BorderRadius.circular(99),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                          decoration: BoxDecoration(
                            gradient: isBusy
                                ? const LinearGradient(colors: [AppTheme.textMuted, AppTheme.textMuted])
                                : AppTheme.emeraldGradient,
                            borderRadius: BorderRadius.circular(99),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primary.withValues(alpha: isBusy ? 0.0 : 0.28),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isBusy)
                                const Padding(
                                  padding: EdgeInsets.only(right: 8.0),
                                  child: SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  ),
                                )
                              else
                                const Icon(Icons.add_circle_outline_rounded, size: 17, color: Colors.white),
                              const SizedBox(width: 6),
                              Text(
                                isBusy ? 'Đang Xử Lý...' : 'Chọn File PDF Từ Máy',
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Progress Bar
                  if (isBusy) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: AppTheme.mintPillGradient,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                controller.statusMessage,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryDark,
                                ),
                              ),
                              Text(
                                '${controller.progressPercentage}%',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(99),
                            child: LinearProgressIndicator(
                              value: controller.progress > 0 ? controller.progress : null,
                              backgroundColor: Colors.white,
                              color: AppTheme.primary,
                              minHeight: 5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Error Message Banner
                  if (controller.errorMessage != null && !isBusy) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.errorSubtle,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.error.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, size: 16, color: AppTheme.error),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              controller.errorMessage!,
                              style: GoogleFonts.plusJakartaSans(
                                color: AppTheme.error,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
