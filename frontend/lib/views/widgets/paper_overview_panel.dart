import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../controllers/paper_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../models/imgrad_model.dart';
import '../../models/paper_model.dart';
import 'keyword_chips_panel.dart';

class PaperOverviewPanel extends StatelessWidget {
  final PaperModel paper;

  const PaperOverviewPanel({super.key, required this.paper});

  @override
  Widget build(BuildContext context) {
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
            // Top Decorative Gradient Strip
            Container(
              height: 2.5,
              decoration: const BoxDecoration(
                gradient: AppTheme.cardAccentGradient,
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // 1. Metadata Badges
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                        decoration: BoxDecoration(
                          gradient: AppTheme.mintPillGradient,
                          borderRadius: BorderRadius.circular(99),
                          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.25)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.picture_as_pdf_rounded, size: 12, color: AppTheme.primary),
                            const SizedBox(width: 4),
                            Text(
                              'PDF Local: ${paper.sourceId}',
                              style: GoogleFonts.plusJakartaSans(
                                color: AppTheme.primaryDark,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: AppTheme.primarySubtle,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          'CHUẨN IMGRaD',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppTheme.primaryDark,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (paper.publicationDate != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: AppTheme.backgroundSubtle,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            paper.publicationDate!,
                            style: GoogleFonts.plusJakartaSans(
                              color: AppTheme.textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Paper Title
                  Text(
                    paper.title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                      height: 1.3,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Authors Row
                  if (paper.authors.isNotEmpty) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.people_outline_rounded, size: 15, color: AppTheme.textMuted),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            paper.authors.join('  •  '),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w500,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],

                  const Divider(color: AppTheme.border),
                  const SizedBox(height: 12),

                  // 2. IMGRaD Structure Section Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionEyebrow(
                        'CẤU TRÚC BÀI BÁO KHOA HỌC (IMGRaD)',
                        Icons.account_tree_rounded,
                        AppTheme.primary,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundSubtle,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Text(
                          'I • M • R • D',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primary,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // [I] - Introduction Pillar
                  _buildImgradPillarCard(
                    context: context,
                    pillar: imgrad.introduction,
                    pillarColor: AppTheme.secondary,
                    icon: Icons.lightbulb_outline_rounded,
                    promptText: 'Hãy phân tích chi tiết phần Đặt Vấn Đề & Mục Tiêu Nghiên Cứu (Introduction) của bài báo.',
                  ),
                  const SizedBox(height: 10),

                  // [M] - Methodology Pillar
                  _buildImgradPillarCard(
                    context: context,
                    pillar: imgrad.methodology,
                    pillarColor: AppTheme.primary,
                    icon: Icons.precision_manufacturing_outlined,
                    promptText: 'Hãy phân tích chi tiết Phương Pháp Luận & Thiết Kế Kỹ Thuật (Methodology) của bài báo.',
                  ),
                  const SizedBox(height: 10),

                  // [R] - Results Pillar
                  _buildImgradPillarCard(
                    context: context,
                    pillar: imgrad.results,
                    pillarColor: AppTheme.accent,
                    icon: Icons.insights_rounded,
                    promptText: 'Hãy tổng hợp các Kết Quả Thực Nghiệm & Số Liệu Phát Hiện (Results) quan trọng nhất của bài báo.',
                  ),
                  const SizedBox(height: 10),

                  // [D] - Discussion Pillar
                  _buildImgradPillarCard(
                    context: context,
                    pillar: imgrad.discussion,
                    pillarColor: AppTheme.primaryDark,
                    icon: Icons.forum_outlined,
                    promptText: 'Hãy phân tích các Thảo Luận, Hạn Chế Của Nghiên Cứu và Hướng Phát Triển (Discussion) của bài báo.',
                  ),
                  const SizedBox(height: 16),

                  // 3. Interactive Keywords
                  KeywordChipsPanel(keywords: paper.keywords),
                  const SizedBox(height: 16),

                  const Divider(color: AppTheme.border),
                  const SizedBox(height: 12),

                  // 4. Raw Document Sections (Collapsible Accordion)
                  _buildSectionEyebrow(
                    'TẤT CẢ CHƯƠNG MỤC GỐC (${paper.sections.length} MỤC)',
                    Icons.format_list_bulleted_rounded,
                    AppTheme.textSecondary,
                  ),
                  const SizedBox(height: 8),

                  if (paper.sections.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Text(
                        'Không có đề mục văn bản bổ sung.',
                        style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted, fontSize: 11.5),
                      ),
                    )
                  else
                    ...paper.sections.map(
                      (section) => Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundSubtle,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Theme(
                          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                            childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                            leading: const Icon(Icons.article_outlined, size: 15, color: AppTheme.secondary),
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
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppTheme.surface,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppTheme.border),
                                ),
                                child: Text(
                                  section.content.isNotEmpty ? section.content : '(Mục trống hoặc chỉ chứa công thức/hình ảnh)',
                                  maxLines: 15,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11.5,
                                    color: AppTheme.textSecondary,
                                    height: 1.45,
                                  ),
                                ),
                              ),
                            ],
                          ),
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

  Widget _buildImgradPillarCard({
    required BuildContext context,
    required ImgradPillar pillar,
    required Color pillarColor,
    required IconData icon,
    required String promptText,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Accent & Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: pillarColor.withValues(alpha: 0.06),
                border: Border(
                  bottom: BorderSide(color: AppTheme.border.withValues(alpha: 0.8)),
                  left: BorderSide(color: pillarColor, width: 3.5),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: pillarColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '[${pillar.code}]',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
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
                    onTap: () => context.read<PaperController>().sendMessage(promptText),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: pillarColor.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.chat_bubble_outline_rounded, size: 11, color: pillarColor),
                          const SizedBox(width: 4),
                          Text(
                            'Hỏi AI',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: pillarColor,
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
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 5),
                              width: 4.5,
                              height: 4.5,
                              decoration: BoxDecoration(
                                color: pillarColor,
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

  Widget _buildSectionEyebrow(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 5),
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: color,
          ),
        ),
      ],
    );
  }
}
