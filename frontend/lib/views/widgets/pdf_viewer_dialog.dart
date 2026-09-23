import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdfrx/pdfrx.dart';
import '../../core/theme/app_theme.dart';
import '../../models/paper_model.dart';

class PdfViewerDialog extends StatefulWidget {
  final PaperModel paper;
  final Uint8List? pdfBytes;

  const PdfViewerDialog({
    super.key,
    required this.paper,
    this.pdfBytes,
  });

  static Future<void> show(BuildContext context, PaperModel paper, Uint8List? pdfBytes) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: PdfViewerDialog(paper: paper, pdfBytes: pdfBytes),
      ),
    );
  }

  @override
  State<PdfViewerDialog> createState() => _PdfViewerDialogState();
}

class _PdfViewerDialogState extends State<PdfViewerDialog> {
  PdfViewerController? _pdfController;
  int _currentPage = 1;
  int _totalPages = 0;

  @override
  void initState() {
    super.initState();
    _pdfController = PdfViewerController();
  }

  @override
  Widget build(BuildContext context) {
    final paper = widget.paper;
    final pdfBytes = widget.pdfBytes;

    return Container(
      width: 1100,
      height: 800,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.floatingShadow,
      ),
      child: Column(
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: const BoxDecoration(
              color: AppTheme.surfaceVariant,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(bottom: BorderSide(color: AppTheme.border)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.primarySubtle,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.picture_as_pdf_rounded,
                          size: 14, color: AppTheme.primaryDark),
                      const SizedBox(width: 4),
                      Text(
                        'XEM FILE PDF GỐC',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primaryDark,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    paper.paperCodeDisplay,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryDark,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    paper.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                if (_totalPages > 0) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundSubtle,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Text(
                      'Trang $_currentPage / $_totalPages',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Đóng',
                ),
              ],
            ),
          ),

          // Main PDF Visual Viewer Body
          Expanded(
            child: pdfBytes != null && pdfBytes.isNotEmpty
                ? ClipRRect(
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                    child: PdfViewer.data(
                      pdfBytes,
                      sourceName: paper.title,
                      controller: _pdfController,
                      params: PdfViewerParams(
                        backgroundColor: const Color(0xFF525659),
                        onPageChanged: (pageNumber) {
                          if (pageNumber != null) {
                            setState(() => _currentPage = pageNumber);
                          }
                        },
                        onViewerReady: (document, controller) {
                          setState(() {
                            _totalPages = document.pages.length;
                          });
                        },
                      ),
                    ),
                  )
                : Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.picture_as_pdf_outlined,
                              size: 48, color: AppTheme.primaryDark),
                          const SizedBox(height: 16),
                          Text(
                            'Bản PDF gốc được bảo mật và lưu local trên máy.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Vui lòng bấm nút "Đổi PDF" hoặc chọn lại tệp PDF trên máy để xem ảnh trực quan của toàn bộ các trang PDF gốc.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
