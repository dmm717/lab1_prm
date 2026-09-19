import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../controllers/paper_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../models/keyword_model.dart';

class KeywordChipsPanel extends StatelessWidget {
  final List<KeywordModel> keywords;

  const KeywordChipsPanel({super.key, required this.keywords});

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'methodology':
      case 'method':
        return AppTheme.secondary;
      case 'architecture':
      case 'model':
        return AppTheme.primary;
      case 'benchmark':
      case 'dataset':
        return AppTheme.accent;
      case 'theory':
        return AppTheme.warning;
      default:
        return AppTheme.textSecondary;
    }
  }

  Color _getCategorySubtle(String category) {
    switch (category.toLowerCase()) {
      case 'methodology':
      case 'method':
        return AppTheme.secondarySubtle;
      case 'architecture':
      case 'model':
        return AppTheme.primarySubtle;
      case 'benchmark':
      case 'dataset':
        return AppTheme.accentSubtle;
      case 'theory':
        return AppTheme.warningSubtle;
      default:
        return AppTheme.backgroundSubtle;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (keywords.isEmpty) {
      return const SizedBox.shrink();
    }

    final controller = context.read<PaperController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.hub_rounded, size: 14, color: AppTheme.secondary),
            const SizedBox(width: 6),
            Text(
              'KHÁI NIỆM & TỪ KHÓA CHỦ ĐẠO (BẤM ĐỂ HỎI AI)',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.9,
                color: AppTheme.secondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: keywords.map((keyword) {
            final categoryColor = _getCategoryColor(keyword.category);
            final categorySubtle = _getCategorySubtle(keyword.category);

            return Tooltip(
              message: keyword.context.isNotEmpty
                  ? '${keyword.category.toUpperCase()}: ${keyword.context}'
                  : 'Hỏi AI về "${keyword.term}"',
              child: InkWell(
                onTap: () => controller.askAboutKeyword(keyword),
                borderRadius: BorderRadius.circular(99),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5.5),
                  decoration: BoxDecoration(
                    color: categorySubtle,
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: categoryColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: categoryColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        keyword.term,
                        style: GoogleFonts.plusJakartaSans(
                          color: AppTheme.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

