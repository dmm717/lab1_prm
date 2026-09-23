import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../models/paper_model.dart';
import '../../models/paper_reference_model.dart';

class CitationsPanel extends StatefulWidget {
  final PaperModel paper;

  const CitationsPanel({super.key, required this.paper});

  @override
  State<CitationsPanel> createState() => _CitationsPanelState();
}

class _CitationsPanelState extends State<CitationsPanel> {
  String _selectedStyle = 'BibTeX';
  final TextEditingController _refSearchController = TextEditingController();
  String _refQuery = '';

  @override
  void dispose() {
    _refSearchController.dispose();
    super.dispose();
  }

  void _copyToClipboard(BuildContext context, String text, String styleName) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã sao chép trích dẫn chuẩn $styleName!'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _generateCitation(PaperModel paper, String style) {
    final authors = paper.authors.isNotEmpty ? paper.authors.join(', ') : 'Unknown Author';
    final title = paper.title;
    final year = paper.publicationDate ?? DateTime.now().year.toString();
    final journal = paper.journal ?? 'Academic Research Publication';
    final volume = paper.volume ?? '1';
    final issue = paper.issue ?? '1';
    final pages = paper.pages ?? '1-10';
    final doi = paper.doi ?? '';

    switch (style) {
      case 'BibTeX':
        final citeKey = (paper.authors.isNotEmpty ? paper.authors.first.split(' ').last.toLowerCase() : 'paper') + year;
        return '''@article{$citeKey,
  author = {$authors},
  title = {$title},
  journal = {$journal},
  year = {$year},
  volume = {$volume},
  number = {$issue},
  pages = {$pages},
  doi = {$doi}
}''';

      case 'APA 7th':
        return '$authors ($year). $title. $journal, $volume($issue), $pages.${doi.isNotEmpty ? ' https://doi.org/$doi' : ''}';

      case 'MLA 9th':
        return '$authors. "$title." $journal, vol. $volume, no. $issue, $year, pp. $pages.${doi.isNotEmpty ? ' DOI: $doi' : ''}';

      case 'IEEE':
        return '$authors, "$title," $journal, vol. $volume, no. $issue, pp. $pages, $year.${doi.isNotEmpty ? ' doi: $doi.' : ''}';

      case 'Chicago':
        return '$authors. "$title." $journal $volume, no. $issue ($year): $pages.${doi.isNotEmpty ? ' https://doi.org/$doi.' : ''}';

      case 'Harvard':
        return '$authors ($year) \'$title\', $journal, $volume($issue), pp. $pages.${doi.isNotEmpty ? ' Available at: https://doi.org/$doi.' : ''}';

      default:
        return '$authors ($year). $title. $journal.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final paper = widget.paper;
    final references = paper.references;
    final citationText = _generateCitation(paper, _selectedStyle);

    final filteredRefs = references.where((r) {
      if (_refQuery.isEmpty) return true;
      final q = _refQuery.toLowerCase();
      return r.title.toLowerCase().contains(q) ||
          r.authors.any((a) => a.toLowerCase().contains(q)) ||
          (r.journal != null && r.journal!.toLowerCase().contains(q));
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 1. CITATION GENERATOR CARD
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
                  const Icon(Icons.format_quote_rounded,
                      size: 20, color: AppTheme.primaryDark),
                  const SizedBox(width: 8),
                  Text(
                    'BỘ TẠO TRÍCH DẪN 1-CLICK (CITATION GENERATOR)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: AppTheme.primaryDark,
                    ),
                  ),
                  const Spacer(),
                  if (paper.citationCount != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.primarySubtle,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        '${paper.citationCount} lượt trích dẫn',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryDark,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Citation Style Switcher Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    'BibTeX',
                    'APA 7th',
                    'MLA 9th',
                    'IEEE',
                    'Chicago',
                    'Harvard',
                  ].map((style) {
                    final selected = _selectedStyle == style;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(style),
                        selected: selected,
                        onSelected: (val) {
                          if (val) setState(() => _selectedStyle = style);
                        },
                        selectedColor: AppTheme.primary,
                        backgroundColor: AppTheme.backgroundSubtle,
                        labelStyle: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight:
                              selected ? FontWeight.w800 : FontWeight.w600,
                          color: selected ? Colors.white : AppTheme.textPrimary,
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 12),

              // Generated Citation Text Box with Copy Button
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundSubtle,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Định dạng chuẩn $_selectedStyle:',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textMuted,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _copyToClipboard(
                              context, citationText, _selectedStyle),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                          ),
                          icon: const Icon(Icons.copy_rounded, size: 13),
                          label: Text(
                            'Sao chép',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 11, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      citationText,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11.5,
                        color: AppTheme.textPrimary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // 2. EXTRACTED REFERENCES LIST CARD
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
                  const Icon(Icons.menu_book_rounded,
                      size: 18, color: AppTheme.primaryDark),
                  const SizedBox(width: 8),
                  Text(
                    'DANH SÁCH TÀI LIỆU THAM KHẢO (${references.length})',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: AppTheme.primaryDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Filter Search Input
              Container(
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.backgroundSubtle,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.border),
                ),
                child: TextField(
                  controller: _refSearchController,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 12, color: AppTheme.textPrimary),
                  onChanged: (val) => setState(() => _refQuery = val),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    hintText:
                        'Lọc trong ${references.length} tài liệu tham khảo...',
                    hintStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5, color: AppTheme.textMuted),
                    prefixIcon: const Icon(Icons.search_rounded,
                        size: 15, color: AppTheme.textMuted),
                    border: InputBorder.none,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              filteredRefs.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(20),
                      child: Center(
                        child: Text(
                          references.isEmpty
                              ? 'Không có tài liệu tham khảo nào được trích xuất.'
                              : 'Không tìm thấy tài liệu tham khảo khớp từ khóa.',
                          style: GoogleFonts.plusJakartaSans(
                              color: AppTheme.textMuted, fontSize: 12),
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredRefs.length,
                      separatorBuilder: (_, __) =>
                          const Divider(color: AppTheme.border, height: 16),
                      itemBuilder: (context, index) {
                        final ref = filteredRefs[index];
                        return _buildReferenceItem(context, ref, index + 1);
                      },
                    ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReferenceItem(
      BuildContext context, PaperReferenceModel ref, int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primarySubtle,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '[$index]',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primaryDark,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                ref.title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                  height: 1.35,
                ),
              ),
            ),
            if (ref.doi != null && ref.doi!.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.copy_rounded,
                    size: 14, color: AppTheme.primaryDark),
                onPressed: () {
                  Clipboard.setData(
                      ClipboardData(text: 'https://doi.org/${ref.doi}'));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Đã sao chép DOI: ${ref.doi}')),
                  );
                },
                tooltip: 'Sao chép DOI',
              ),
          ],
        ),
        if (ref.authors.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            ref.authors.join('  •  '),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
        if (ref.journal != null || ref.year != null) ...[
          const SizedBox(height: 2),
          Text(
            '${ref.journal ?? ''} ${ref.year != null ? '(${ref.year})' : ''}'
                .trim(),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontStyle: FontStyle.italic,
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ],
    );
  }
}
