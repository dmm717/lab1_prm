import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../controllers/paper_controller.dart';
import '../../core/theme/app_theme.dart';

class LocalPdfBar extends StatelessWidget {
  const LocalPdfBar({super.key});

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
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
                color: AppTheme.primarySubtle,
                borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.picture_as_pdf_outlined,
                color: AppTheme.primary, size: 22),
          ),
          const SizedBox(width: 13),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(paper == null ? 'Tài liệu nghiên cứu' : paper.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary)),
                const SizedBox(height: 3),
                Text(
                    paper == null
                        ? 'Chỉ nhận tệp PDF trên máy tính · Trích xuất bằng GROBID'
                        : '${paper.sourceId}.pdf  ·  ${paper.sections.length} mục đã trích xuất',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5, color: AppTheme.textMuted)),
              ])),
          const SizedBox(width: 16),
          FilledButton.icon(
            onPressed: busy ? null : () => _pickPdf(context),
            icon: Icon(
                paper == null
                    ? Icons.add_rounded
                    : Icons.drive_file_move_outline,
                size: 18),
            label: Text(paper == null ? 'Chọn PDF' : 'Mở PDF khác'),
          ),
          if (paper != null) ...[
            const SizedBox(width: 6),
            IconButton(
                tooltip: 'Đóng tài liệu',
                onPressed: busy ? null : controller.closeCurrentPaper,
                icon: const Icon(Icons.close_rounded, size: 19)),
          ],
        ]),
        if (busy) ...[
          const SizedBox(height: 13),
          Row(children: [
            Expanded(
                child: Text(controller.statusMessage,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5, color: AppTheme.textSecondary))),
            Text('${controller.progressPercentage}%',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary)),
          ]),
          const SizedBox(height: 6),
          LinearProgressIndicator(value: controller.progress, minHeight: 4),
        ],
        if (controller.errorMessage != null && !busy) ...[
          const SizedBox(height: 12),
          Text(controller.errorMessage!,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 12, color: AppTheme.error)),
        ],
      ]),
    );
  }
}
