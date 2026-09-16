import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/paper_model.dart';
import 'keyword_chips_panel.dart';

class PaperOverviewPanel extends StatelessWidget {
  final PaperModel paper;

  const PaperOverviewPanel({super.key, required this.paper});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.surfaceVariant),
      ),
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          // 1. Paper Title & ArXiv Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Source: ${paper.sourceId}',
                  style: const TextStyle(
                    color: AppTheme.primaryLight,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              if (paper.publicationDate != null)
                Text(
                  paper.publicationDate!,
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Title
          Text(
            paper.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),

          // Authors
          if (paper.authors.isNotEmpty) ...[
            Text(
              paper.authors.join(' • '),
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 16),
          ],

          const Divider(),
          const SizedBox(height: 12),

          // 2. Executive Summary
          if (paper.executiveSummary.isNotEmpty) ...[
            const Row(
              children: [
                Icon(Icons.summarize, size: 16, color: AppTheme.primaryLight),
                SizedBox(width: 6),
                Text(
                  'Executive Summary',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                paper.executiveSummary,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textPrimary,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // 3. Core Contributions
          if (paper.contributions.isNotEmpty) ...[
            const Row(
              children: [
                Icon(Icons.stars, size: 16, color: AppTheme.accent),
                SizedBox(width: 6),
                Text(
                  'Key Contributions',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...paper.contributions.map(
              (c) => Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('✓ ', style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold)),
                    Expanded(
                      child: Text(
                        c,
                        style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // 4. Interactive Keywords
          KeywordChipsPanel(keywords: paper.keywords),
          const SizedBox(height: 16),

          const Divider(),
          const SizedBox(height: 12),

          // 5. Document Sections (GROBID Extracted Structure)
          Row(
            children: [
              const Icon(Icons.account_tree_outlined, size: 16, color: AppTheme.secondary),
              const SizedBox(width: 6),
              Text(
                'Document Outline (${paper.sections.length} Sections)',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Sections Accordion List
          if (paper.sections.isEmpty)
            const Text(
              'No sections parsed from TEI-XML.',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
            )
          else
            ...paper.sections.map(
              (section) => Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                  childrenPadding: const EdgeInsets.all(12),
                  leading: const Icon(Icons.article_outlined, size: 16, color: AppTheme.textMuted),
                  title: Text(
                    section.displayName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.background,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        section.content.isNotEmpty ? section.content : '(Empty or figures/tables only)',
                        maxLines: 15,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
