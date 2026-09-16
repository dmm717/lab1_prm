import 'package:flutter/material.dart';
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
        return AppTheme.primaryLight;
      case 'benchmark':
      case 'dataset':
        return AppTheme.accent;
      case 'theory':
        return AppTheme.warning;
      default:
        return AppTheme.textSecondary;
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
        const Row(
          children: [
            Icon(Icons.key, size: 16, color: AppTheme.secondary),
            SizedBox(width: 6),
            Text(
              'Key Concepts & Keywords (Click to ask AI)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: keywords.map((keyword) {
            final categoryColor = _getCategoryColor(keyword.category);

            return Tooltip(
              message: keyword.context.isNotEmpty
                  ? '${keyword.category}: ${keyword.context}'
                  : 'Ask AI about "${keyword.term}"',
              child: ActionChip(
                backgroundColor: AppTheme.surfaceVariant.withValues(alpha: 0.6),
                side: BorderSide(color: categoryColor.withValues(alpha: 0.4)),
                avatar: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: categoryColor,
                    shape: BoxShape.circle,
                  ),
                ),
                label: Text(
                  keyword.term,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onPressed: () => controller.askAboutKeyword(keyword),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
