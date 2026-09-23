import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../controllers/paper_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../models/paper_model.dart';

class MetadataDoiPanel extends StatefulWidget {
  final PaperModel paper;

  const MetadataDoiPanel({super.key, required this.paper});

  @override
  State<MetadataDoiPanel> createState() => _MetadataDoiPanelState();
}

class _MetadataDoiPanelState extends State<MetadataDoiPanel> {
  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã sao chép $label: $text'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PaperController>();
    final paper = widget.paper;

    final doi = paper.doi?.trim();
    final issn = paper.issn?.trim();
    final isbn = paper.isbn?.trim();
    final arxiv = paper.arxivId?.trim();
    final journal = paper.journal?.trim();

    final sjrQuery = (issn != null && issn.isNotEmpty)
        ? issn
        : (journal != null && journal.isNotEmpty ? journal : paper.title);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 1. TOP CARD: DOI Fetch Tool & Identifier Badges
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.primarySubtle,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.extension_rounded,
                        size: 16, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CÔNG CỤ DOI FETCH & EXTENSION',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: AppTheme.primaryDark,
                          ),
                        ),
                        Text(
                          'Tra cứu tự động DOI & Metadata từ CrossRef',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: controller.isFetchingDoi
                        ? null
                        : () async {
                            final success = await controller.fetchDoiForCurrentPaper();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    success
                                        ? 'Đã cập nhật DOI & Metadata thành công!'
                                        : 'Không tìm thấy DOI trực tuyến cho bài báo này.',
                                  ),
                                ),
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: controller.isFetchingDoi
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.sync_rounded, size: 15),
                    label: Text(
                      controller.isFetchingDoi ? 'Đang fetch...' : 'DOI Fetch',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(color: AppTheme.border),
              const SizedBox(height: 10),

              // Identification Code Chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildCodeBadge(
                    context,
                    label: 'DOI',
                    value: (doi != null && doi.isNotEmpty) ? doi : 'Chưa có',
                    isAvailable: doi != null && doi.isNotEmpty,
                    copyText: doi != null && doi.isNotEmpty
                        ? 'https://doi.org/$doi'
                        : null,
                  ),
                  _buildCodeBadge(
                    context,
                    label: 'ISSN',
                    value: (issn != null && issn.isNotEmpty) ? issn : 'Chưa có',
                    isAvailable: issn != null && issn.isNotEmpty,
                    copyText: issn,
                  ),
                  _buildCodeBadge(
                    context,
                    label: 'ISBN',
                    value: (isbn != null && isbn.isNotEmpty) ? isbn : 'Chưa có',
                    isAvailable: isbn != null && isbn.isNotEmpty,
                    copyText: isbn,
                  ),
                  _buildCodeBadge(
                    context,
                    label: 'arXiv ID',
                    value:
                        (arxiv != null && arxiv.isNotEmpty) ? arxiv : 'Chưa có',
                    isAvailable: arxiv != null && arxiv.isNotEmpty,
                    copyText: arxiv,
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // 2. JOURNAL PRESTIGE RANKING CARD (SJR Q1-Q4 / Impact Factor)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.border),
            boxShadow: AppTheme.softShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.verified_rounded,
                      size: 18, color: AppTheme.primaryDark),
                  const SizedBox(width: 8),
                  Text(
                    'TRA CỨU CẤP ĐỘ UY TÍN TẠP CHÍ (JOURNAL PRESTIGE)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: AppTheme.primaryDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Sử dụng Mã số bài báo (ISSN / DOI / Tên Tạp Chí) bên dưới để tra cứu cấp độ uy tín (SJR Q1/Q2/Q3/Q4, Impact Factor, Scopus, H-Index) của bài báo:',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 14),

              // Action buttons for prestige search engine links
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildPrestigeLinkButton(
                    context,
                    title: '🏆 SCImago Journal Rank (SJR Q1-Q4)',
                    url:
                        'https://www.scimagojr.com/journalsearch.php?q=${Uri.encodeComponent(sjrQuery)}',
                    subtext: 'Tra cứu xếp hạng Q1-Q4 & H-Index',
                  ),
                  _buildPrestigeLinkButton(
                    context,
                    title: '🎓 Google Scholar',
                    url:
                        'https://scholar.google.com/scholar?q=${Uri.encodeComponent(doi ?? paper.title)}',
                    subtext: 'Xem số lượt trích dẫn & bài báo gốc',
                  ),
                  _buildPrestigeLinkButton(
                    context,
                    title: '🌐 CrossRef Open Registry',
                    url:
                        'https://search.crossref.org/?q=${Uri.encodeComponent(doi ?? paper.title)}',
                    subtext: 'Xác minh DOI & Nhà xuất bản',
                  ),
                  if (doi != null && doi.isNotEmpty)
                    _buildPrestigeLinkButton(
                      context,
                      title: '🔓 Unpaywall Open Access',
                      url: 'https://unpaywall.org/$doi',
                      subtext: 'Kiểm tra bản mở Open Access',
                    ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // 3. FULL METADATA TABLE CARD
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.border),
            boxShadow: AppTheme.softShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.list_alt_rounded,
                      size: 18, color: AppTheme.primaryDark),
                  const SizedBox(width: 8),
                  Text(
                    'TOÀN BỘ METADATA BÀI BÁO (FULL METADATA)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: AppTheme.primaryDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              _buildMetaRow('Tên bài báo (Title)', paper.title, context: context),
              _buildMetaRow('Tác giả (Authors)',
                  paper.authors.isNotEmpty ? paper.authors.join(', ') : 'Chưa có', context: context),
              _buildMetaRow('Tạp chí / Hội nghị (Journal/Venue)',
                  paper.journal ?? 'Chưa xác định', context: context),
              _buildMetaRow('Nhà xuất bản (Publisher)',
                  paper.publisher ?? 'Chưa xác định', context: context),
              _buildMetaRow('Ngày / Năm xuất bản',
                  paper.publicationDate ?? 'Chưa xác định', context: context),
              _buildMetaRow('Tập (Volume)', paper.volume ?? '—', context: context),
              _buildMetaRow('Số (Issue)', paper.issue ?? '—', context: context),
              _buildMetaRow('Trang (Pages)', paper.pages ?? '—', context: context),
              _buildMetaRow('Lượt trích dẫn (Citations)',
                  paper.citationCount != null ? '${paper.citationCount} lượt' : 'Chưa cập nhật', context: context),
              _buildMetaRow('Động cơ bóc tách',
                  paper.isFallback ? 'GROBID (TEI Fallback)' : 'GROBID Fulltext Engine', context: context),
              _buildMetaRow('Mục TEI bóc tách', '${paper.sections.length} đề mục', context: context),
              _buildMetaRow('Tài liệu tham khảo', '${paper.references.length} bài báo', context: context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCodeBadge(
    BuildContext context, {
    required String label,
    required String value,
    required bool isAvailable,
    String? copyText,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isAvailable ? AppTheme.surface : AppTheme.backgroundSubtle,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isAvailable ? AppTheme.primary.withValues(alpha: 0.4) : AppTheme.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: isAvailable ? AppTheme.primaryDark : AppTheme.textMuted,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: isAvailable ? AppTheme.textPrimary : AppTheme.textMuted,
            ),
          ),
          if (copyText != null) ...[
            const SizedBox(width: 6),
            InkWell(
              onTap: () => _copyToClipboard(context, copyText, label),
              borderRadius: BorderRadius.circular(4),
              child: const Icon(Icons.copy_rounded,
                  size: 13, color: AppTheme.primaryDark),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPrestigeLinkButton(
    BuildContext context, {
    required String title,
    required String url,
    required String subtext,
  }) {
    return InkWell(
      onTap: () {
        Clipboard.setData(ClipboardData(text: url));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã sao chép đường dẫn tra cứu: $url'),
            action: SnackBarAction(
              label: 'Mở URL',
              onPressed: () {},
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.backgroundSubtle,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtext,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.open_in_new_rounded, size: 14, color: AppTheme.primaryDark),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaRow(String label, String value, {required BuildContext context}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 170,
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textMuted,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
