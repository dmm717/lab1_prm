import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../controllers/paper_controller.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';

class ArxivInputBar extends StatefulWidget {
  const ArxivInputBar({super.key});

  @override
  State<ArxivInputBar> createState() => _ArxivInputBarState();
}

class _ArxivInputBarState extends State<ArxivInputBar> {
  final TextEditingController _urlController = TextEditingController();

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    final text = _urlController.text.trim();
    if (text.isNotEmpty) {
      context.read<PaperController>().processInputUrl(text);
    }
  }

  Future<void> _pickAndUploadPdf() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result.isNotEmpty) {
      final file = result.single;
      final bytes = await file.readAsBytes();
      if (mounted) {
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Decorative Gradient Strip
            Container(
              height: 2.5,
              decoration: const BoxDecoration(
                gradient: AppTheme.cardAccentGradient,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      // Double-bezel Search Input
                      Expanded(
                        child: Container(
                          height: 42,
                          decoration: BoxDecoration(
                            color: AppTheme.background,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.border, width: 1),
                          ),
                          child: TextField(
                            controller: _urlController,
                            enabled: !isBusy,
                            style: GoogleFonts.plusJakartaSans(
                              color: AppTheme.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              isDense: true,
                              fillColor: Colors.transparent,
                              filled: false,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              hintText: 'Dán liên kết báo (VnExpress, Dân Trí...) hoặc ArXiv...',
                              hintStyle: GoogleFonts.plusJakartaSans(
                                color: AppTheme.textMuted,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w400,
                              ),
                              prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primary, size: 19),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
                              suffixIcon: _urlController.text.isNotEmpty && !isBusy
                                  ? IconButton(
                                      icon: const Icon(Icons.cancel_rounded, size: 16, color: AppTheme.textMuted),
                                      onPressed: () {
                                        setState(() {
                                          _urlController.clear();
                                        });
                                      },
                                    )
                                  : null,
                            ),
                            onSubmitted: (_) => _handleSubmit(),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Nested CTA: Analyze Paper (Gradient Pill)
                      InkWell(
                        onTap: isBusy ? null : _handleSubmit,
                        borderRadius: BorderRadius.circular(99),
                        child: Container(
                          height: 42,
                          padding: const EdgeInsets.fromLTRB(16, 0, 6, 0),
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
                              Text(
                                isBusy ? 'Đang Xử Lý...' : 'Phân Tích Bài Báo',
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.1,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.22),
                                  shape: BoxShape.circle,
                                ),
                                child: isBusy
                                    ? const Padding(
                                        padding: EdgeInsets.all(7.0),
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 15),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Upload PDF Secondary Button
                      InkWell(
                        onTap: isBusy ? null : _pickAndUploadPdf,
                        borderRadius: BorderRadius.circular(99),
                        child: Container(
                          height: 42,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.35), width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.upload_file_rounded, size: 16, color: AppTheme.primary),
                              const SizedBox(width: 6),
                              Text(
                                'Tải File PDF',
                                style: GoogleFonts.plusJakartaSans(
                                  color: AppTheme.primaryDark,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Quick Sample Links Row
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        Text(
                          'Mẫu nhanh:',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppTheme.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildSampleChip('Báo VnExpress (Ngập Lụt)', 'https://vnexpress.net/bien-nuoc-bua-vay-vung-trung-ngoai-thanh-ha-noi-5122010.html'),
                        const SizedBox(width: 6),
                        _buildSampleChip('Attention (Transformer)', AppConstants.sampleArxivLinks[0]),
                        const SizedBox(width: 6),
                        _buildSampleChip('GPT-3 Language Models', AppConstants.sampleArxivLinks[1]),
                        const SizedBox(width: 6),
                        _buildSampleChip('Mamba (SSM)', AppConstants.sampleArxivLinks[2]),
                      ],
                    ),
                  ),

                  // Progress Bar with Emerald Styling
                  if (isBusy) ...[
                    const SizedBox(height: 10),
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
                              Row(
                                children: [
                                  const SizedBox(
                                    width: 13,
                                    height: 13,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppTheme.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    controller.statusMessage,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.primaryDark,
                                    ),
                                  ),
                                ],
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
                    const SizedBox(height: 8),
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

  Widget _buildSampleChip(String label, String url) {
    return InkWell(
      onTap: () {
        setState(() {
          _urlController.text = url;
        });
        context.read<PaperController>().processInputUrl(url);
      },
      borderRadius: BorderRadius.circular(99),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
        decoration: BoxDecoration(
          gradient: AppTheme.mintPillGradient,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.22)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bolt_rounded, size: 12, color: AppTheme.primary),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10.5,
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

