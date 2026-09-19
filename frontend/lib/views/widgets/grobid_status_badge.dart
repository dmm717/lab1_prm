import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../controllers/paper_controller.dart';
import '../../core/theme/app_theme.dart';

class GrobidStatusBadge extends StatelessWidget {
  const GrobidStatusBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PaperController>();
    final isOnline = controller.isGrobidAlive;
    final isFallback = controller.isFallbackMode;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isFallback) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
            decoration: BoxDecoration(
              color: AppTheme.warningSubtle,
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: AppTheme.warning.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.bolt_rounded, size: 12, color: AppTheme.warning),
                const SizedBox(width: 3),
                Text(
                  'Dự Phòng Gemini',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.warning,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
        ],
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
          decoration: BoxDecoration(
            color: isOnline ? AppTheme.accentSubtle : AppTheme.errorSubtle,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(
              color: isOnline
                  ? AppTheme.accent.withValues(alpha: 0.25)
                  : AppTheme.error.withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isOnline ? AppTheme.accent : AppTheme.error,
                  boxShadow: [
                    BoxShadow(
                      color: (isOnline ? AppTheme.accent : AppTheme.error).withValues(alpha: 0.4),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 5),
              Text(
                isOnline ? 'GROBID Online' : 'GROBID Offline',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isOnline ? AppTheme.accent : AppTheme.error,
                ),
              ),
              const SizedBox(width: 3),
              InkWell(
                onTap: () => controller.checkGrobidHealth(),
                borderRadius: BorderRadius.circular(99),
                child: Padding(
                  padding: const EdgeInsets.all(1.0),
                  child: Icon(
                    Icons.refresh_rounded,
                    size: 12,
                    color: isOnline ? AppTheme.accent : AppTheme.error,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

