import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../controllers/paper_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../models/imgrad_model.dart';
import '../../models/paper_model.dart';
import 'citations_panel.dart';
import 'keyword_chips_panel.dart';
import 'metadata_doi_panel.dart';
import 'pdf_viewer_dialog.dart';

class PaperOverviewPanel extends StatefulWidget {
  final PaperModel paper;

  const PaperOverviewPanel({super.key, required this.paper});

  @override
  State<PaperOverviewPanel> createState() => _PaperOverviewPanelState();
}

class _PaperOverviewPanelState extends State<PaperOverviewPanel> {
  int _selectedTabIndex =
      0; // 0: IMGRaD, 1: Metadata & DOI, 2: Citations, 3: Keywords, 4: Raw Sections
  final TextEditingController _sectionSearchController =
      TextEditingController();
  String _sectionSearchQuery = '';

  @override
  void dispose() {
    _sectionSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final paper = widget.paper;
    final imgrad = paper.effectiveImgrad;

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
            // Top Accent Line
            Container(
              height: 3,
              decoration: const BoxDecoration(
                gradient: AppTheme.cardAccentGradient,
              ),
            ),

            // Paper Header Brief Card
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              decoration: const BoxDecoration(
                color: AppTheme.surfaceVariant,
                border: Border(bottom: BorderSide(color: AppTheme.border)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.primarySubtle,
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(
                              color: AppTheme.primary.withValues(alpha: 0.25)),
                        ),
                        child: Text(
                          'CHUẨN IMGRaD',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppTheme.primaryDark,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(
                              color: AppTheme.primary.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.pin_rounded,
                                size: 10, color: AppTheme.primaryDark),
                            const SizedBox(width: 3),
                            Text(
                              paper.paperCodeDisplay,
                              style: GoogleFonts.plusJakartaSans(
                                color: AppTheme.primaryDark,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${paper.sections.length} MỤC',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppTheme.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: () {
                          final controller = context.read<PaperController>();
                          PdfViewerDialog.show(
                              context, paper, controller.currentPdfBytes);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          elevation: 0,
                        ),
                        icon:
                            const Icon(Icons.picture_as_pdf_rounded, size: 13),
                        label: Text(
                          'Xem PDF',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 11, fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (paper.publicationDate != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          paper.publicationDate!,
                          style: GoogleFonts.plusJakartaSans(
                            color: AppTheme.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    paper.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                      height: 1.3,
                      letterSpacing: -0.3,
                    ),
                  ),
                  if (paper.authors.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      paper.authors.join('  •  '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Segmented Tab Switcher (Linear / Claude Style)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: const BoxDecoration(
                color: AppTheme.backgroundSubtle,
                border: Border(bottom: BorderSide(color: AppTheme.border)),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildTabButton(0, '📊 Tóm tắt IMGRaD'),
                    const SizedBox(width: 4),
                    _buildTabButton(1, '📋 Metadata & Mã số'),
                    const SizedBox(width: 4),
                    _buildTabButton(2,
                        '📚 Trích dẫn${paper.references.isNotEmpty ? ' (${paper.references.length})' : ''}'),
                    const SizedBox(width: 4),
                    _buildTabButton(3, '🔑 Từ khóa (${paper.keywords.length})'),
                    const SizedBox(width: 4),
                    _buildTabButton(
                        4, '📄 Chương mục (${paper.sections.length})'),
                  ],
                ),
              ),
            ),

            // Tab Content Body
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _buildSelectedTabContent(paper, imgrad),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(int index, String label) {
    final isSelected = _selectedTabIndex == index;
    return InkWell(
      onTap: () => setState(() => _selectedTabIndex = index),
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.border : Colors.transparent,
          ),
          boxShadow: isSelected ? AppTheme.softShadow : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? AppTheme.primaryDark : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedTabContent(PaperModel paper, ImgradModel imgrad) {
    switch (_selectedTabIndex) {
      case 0:
        return _buildImgradTab(paper, imgrad);
      case 1:
        return MetadataDoiPanel(key: const ValueKey(1), paper: paper);
      case 2:
        return CitationsPanel(key: const ValueKey(2), paper: paper);
      case 3:
        return _buildKeywordsTab(paper);
      case 4:
        return _buildSectionsTab(paper);
      default:
        return _buildImgradTab(paper, imgrad);
    }
  }

  // TAB 1: IMGRaD Structure Tab
  Widget _buildImgradTab(PaperModel paper, ImgradModel imgrad) {
    return ListView(
      key: const ValueKey(0),
      padding: const EdgeInsets.all(16),
      children: [
        // Executive Summary Box (If Present)
        if (paper.executiveSummary.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome_rounded,
                        size: 14, color: AppTheme.primaryDark),
                    const SizedBox(width: 6),
                    Text(
                      'TỔNG QUAN ĐỒNG THỜI (EXECUTIVE SUMMARY)',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: AppTheme.primaryDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  paper.executiveSummary,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    color: AppTheme.textSecondary,
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        // [I] - Introduction Pillar (Slate Blue Pastel)
        _buildImgradPillarCard(
          pillar: imgrad.introduction,
          accentColor: const Color(0xFF2B5885),
          bgColor: const Color(0xFFEBF3FA),
          borderColor: const Color(0xFFD0DCE5),
          promptText:
              'Hãy phân tích chi tiết phần Đặt Vấn Đề & Mục Tiêu Nghiên Cứu (Introduction) của bài báo.',
        ),
        const SizedBox(height: 12),

        // [M] - Methodology Pillar (Sage Green Pastel)
        _buildImgradPillarCard(
          pillar: imgrad.methodology,
          accentColor: const Color(0xFF2F5D38),
          bgColor: const Color(0xFFEDF3EC),
          borderColor: const Color(0xFFCEE0CE),
          promptText:
              'Hãy phân tích chi tiết Phương Pháp Luận & Thiết Kế Kỹ Thuật (Methodology) của bài báo.',
        ),
        const SizedBox(height: 12),

        // [R] - Results Pillar (Terracotta Amber Pastel)
        _buildImgradPillarCard(
          pillar: imgrad.results,
          accentColor: const Color(0xFFB54F2B),
          bgColor: const Color(0xFFFDF2EE),
          borderColor: const Color(0xFFF7D6CC),
          promptText:
              'Hãy tổng hợp các Kết Quả Thực Nghiệm & Số Liệu Phát Hiện (Results) quan trọng nhất của bài báo.',
        ),
        const SizedBox(height: 12),

        // [D] - Discussion Pillar (Muted Purple Pastel)
        _buildImgradPillarCard(
          pillar: imgrad.discussion,
          accentColor: const Color(0xFF5E3D85),
          bgColor: const Color(0xFFF4F0F9),
          borderColor: const Color(0xFFE2D6EB),
          promptText:
              'Hãy phân tích các Thảo Luận, Hạn Chế Của Nghiên Cứu và Hướng Phát Triển (Discussion) của bài báo.',
        ),

        // Key Contributions List (If Present)
        if (paper.contributions.isNotEmpty) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.stars_rounded,
                        size: 14, color: AppTheme.primaryDark),
                    const SizedBox(width: 6),
                    Text(
                      'ĐÓNG GÓP CHÍNH CỦA NGHIÊN CỨU',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: AppTheme.primaryDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ...paper.contributions.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle_outline_rounded,
                            size: 14, color: AppTheme.primaryDark),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: AppTheme.textPrimary,
                              height: 1.45,
                            ),
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
      ],
    );
  }

  // TAB 2: Keywords & Concepts Tab
  Widget _buildKeywordsTab(PaperModel paper) {
    return ListView(
      key: const ValueKey(1),
      padding: const EdgeInsets.all(16),
      children: [
        KeywordChipsPanel(keywords: paper.keywords),
      ],
    );
  }

  // TAB 3: Raw Document Sections Tab (With Search Filter)
  Widget _buildSectionsTab(PaperModel paper) {
    final query = _sectionSearchQuery.toLowerCase().trim();
    final filteredSections = paper.sections.where((section) {
      if (query.isEmpty) return true;
      return section.title.toLowerCase().contains(query) ||
          section.content.toLowerCase().contains(query);
    }).toList();

    return Column(
      key: const ValueKey(2),
      children: [
        // Search Filter Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Container(
            height: 38,
            decoration: BoxDecoration(
              color: AppTheme.backgroundSubtle,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.border),
            ),
            child: TextField(
              controller: _sectionSearchController,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5, color: AppTheme.textPrimary),
              onChanged: (val) => setState(() => _sectionSearchQuery = val),
              decoration: InputDecoration(
                isDense: true,
                filled: false,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                hintText:
                    'Tìm kiếm trong ${paper.sections.length} đề mục TEI...',
                hintStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 12, color: AppTheme.textMuted),
                prefixIcon: const Icon(Icons.search_rounded,
                    size: 16, color: AppTheme.textMuted),
                suffixIcon: _sectionSearchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 14),
                        onPressed: () {
                          _sectionSearchController.clear();
                          setState(() => _sectionSearchQuery = '');
                        },
                      )
                    : null,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
        ),

        // Section Accordions List
        Expanded(
          child: filteredSections.isEmpty
              ? Center(
                  child: Text(
                    query.isNotEmpty
                        ? 'Không tìm thấy mục khớp từ khóa'
                        : 'Không có đề mục văn bản.',
                    style: GoogleFonts.plusJakartaSans(
                        color: AppTheme.textMuted, fontSize: 12),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  itemCount: filteredSections.length,
                  itemBuilder: (context, index) {
                    final section = filteredSections[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundSubtle,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Theme(
                        data: Theme.of(context)
                            .copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          tilePadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 0),
                          childrenPadding:
                              const EdgeInsets.fromLTRB(12, 0, 12, 12),
                          leading: const Icon(Icons.article_outlined,
                              size: 16, color: AppTheme.primaryDark),
                          title: Text(
                            section.displayName,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.surface,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppTheme.border),
                              ),
                              child: Text(
                                section.content.isNotEmpty
                                    ? section.content
                                    : '(Mục trống hoặc chỉ chứa công thức/hình ảnh)',
                                maxLines: 20,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildImgradPillarCard({
    required ImgradPillar pillar,
    required Color accentColor,
    required Color bgColor,
    required Color borderColor,
    required String promptText,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: borderColor),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '[${pillar.code}]',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${pillar.vietnameseTitle} (${pillar.name})',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () =>
                        context.read<PaperController>().sendMessage(promptText),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: accentColor.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.chat_bubble_outline_rounded,
                              size: 11, color: accentColor),
                          const SizedBox(width: 4),
                          Text(
                            'Hỏi AI',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: accentColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content Body
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pillar.summary,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  if (pillar.keyPoints.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ...pillar.keyPoints.map(
                      (point) => Padding(
                        padding: const EdgeInsets.only(bottom: 5.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 5),
                              width: 4.5,
                              height: 4.5,
                              decoration: BoxDecoration(
                                color: accentColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 7),
                            Expanded(
                              child: Text(
                                point,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.textPrimary,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
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
