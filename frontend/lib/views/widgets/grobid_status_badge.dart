import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/paper_controller.dart';
import '../../core/theme/app_theme.dart';

class GrobidStatusBadge extends StatelessWidget {
  const GrobidStatusBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PaperController>();
    final isOnline = controller.isGrobidAlive;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isOnline
            ? AppTheme.accent.withValues(alpha: 0.15)
            : AppTheme.error.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isOnline
              ? AppTheme.accent.withValues(alpha: 0.4)
              : AppTheme.error.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isOnline ? AppTheme.accent : AppTheme.error,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isOnline ? 'GROBID Online' : 'GROBID Offline',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isOnline ? AppTheme.accent : AppTheme.error,
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: () => controller.checkGrobidHealth(),
            borderRadius: BorderRadius.circular(10),
            child: const Padding(
              padding: EdgeInsets.all(2.0),
              child: Icon(Icons.refresh, size: 14, color: AppTheme.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
