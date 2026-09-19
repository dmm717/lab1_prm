import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../controllers/paper_controller.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/chat_panel.dart';
import '../widgets/grobid_status_badge.dart';
import '../widgets/local_pdf_bar.dart';
import '../widgets/paper_overview_panel.dart';
import '../widgets/recent_papers_dialog.dart';
import '../widgets/settings_dialog.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PaperController>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.heroBackgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 1. Desktop Island Header Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.border, width: 1),
                    boxShadow: AppTheme.softShadow,
                  ),
                  child: Row(
                    children: [
                      // Brand Logo Mark with Emerald Gradient
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          gradient: AppTheme.emeraldGradient,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withValues(alpha: 0.28),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.auto_stories_rounded, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Text(
                                'PaperChat',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  color: AppTheme.textPrimary,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(width: 4),
                              ShaderMask(
                                shaderCallback: (bounds) => AppTheme.emeraldGradient.createShader(bounds),
                                child: Text(
                                  'AI Desktop',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                    color: Colors.white,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  gradient: AppTheme.mintPillGradient,
                                  borderRadius: BorderRadius.circular(99),
                                  border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
                                ),
                                child: Text(
                                  'CHUẨN IMGRaD',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 9,
                                    color: AppTheme.primaryDark,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'Phân Tích & Đối Thoại Bài Báo Khoa Học (Tệp PDF Local)',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10.5,
                              color: AppTheme.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),

                      // Live GROBID Status Badge
                      const GrobidStatusBadge(),
                      const SizedBox(width: 10),

                      // Saved Papers Library Button
                      Tooltip(
                        message: 'Thư viện bài báo đã lưu trên máy',
                        child: InkWell(
                          onTap: () => RecentPapersDialog.show(context),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6.5),
                            decoration: BoxDecoration(
                              color: AppTheme.backgroundSubtle,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.bookmark_border_rounded, size: 16, color: AppTheme.textSecondary),
                                const SizedBox(width: 5),
                                Text(
                                  'Thư viện',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                if (controller.recentPapers.isNotEmpty) ...[
                                  const SizedBox(width: 5),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5.5, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      gradient: AppTheme.emeraldGradient,
                                      borderRadius: BorderRadius.circular(99),
                                    ),
                                    child: Text(
                                      '${controller.recentPapers.length}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Settings Button
                      Tooltip(
                        message: 'Cài đặt Gemini API Key & Cổng dịch vụ',
                        child: InkWell(
                          onTap: () => SettingsDialog.show(context),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.all(7.5),
                            decoration: BoxDecoration(
                              color: AppTheme.backgroundSubtle,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: const Icon(Icons.tune_rounded, size: 16, color: AppTheme.textSecondary),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Main Content Viewport
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                  child: Column(
                    children: [
                      // Dedicated Local PDF Ingestion & Active Bar
                      const LocalPdfBar(),
                      const SizedBox(height: 10),

                      // Dynamic Split-Pane Area
                      Expanded(
                        child: controller.hasPaper
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Left Pane: IMGRaD Scientific Navigator (44% width)
                                  Expanded(
                                    flex: 44,
                                    child: PaperOverviewPanel(paper: controller.currentPaper!),
                                  ),
                                  const SizedBox(width: 12),

                                  // Right Pane: Conversational Chat (56% width)
                                  const Expanded(
                                    flex: 56,
                                    child: ChatPanel(),
                                  ),
                                ],
                              )
                            : _buildWelcomeHero(context),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeHero(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Eyebrow Pill with Pulse Dot
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
                decoration: BoxDecoration(
                  gradient: AppTheme.mintPillGradient,
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: AppTheme.primary.withValues(alpha: 0.25)),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        gradient: AppTheme.emeraldGradient,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Text(
                      'DESKTOP APP • NẠP TỆP PDF LOCAL • CHUẨN CẤU TRÚC KHOA HỌC IMGRaD',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.9,
                        color: AppTheme.primaryDark,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Grand Headline
              Text(
                'Phân Tích Bài Báo Khoa Học Chuẩn IMGRaD',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                  height: 1.25,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 8),

              // Subtext
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Text(
                  'Bóc tách toàn diện tệp PDF thành 4 trụ cột học thuật kinh điển: Đặt Vấn Đề (Introduction), '
                  'Phương Pháp Luận (Methodology), Kết Quả Thực Nghiệm (Results) và Thảo Luận / Hạn Chế (Discussion). '
                  'Hỏi đáp và đối chiếu chính xác theo từng cấu trúc cùng Gemini AI.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                    height: 1.5,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 4 IMGRaD Pillars Bento Grid
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBentoCard(
                    icon: Icons.lightbulb_outline_rounded,
                    iconColor: AppTheme.secondary,
                    pillarCode: 'I',
                    title: 'Introduction',
                    vietnameseTitle: 'Đặt Vấn Đề & Mục Tiêu',
                    description:
                        'Xác định bối cảnh nghiên cứu, bài toán khoa học, câu hỏi nghiên cứu và mục tiêu đóng góp cốt lõi.',
                  ),
                  const SizedBox(width: 10),
                  _buildBentoCard(
                    icon: Icons.precision_manufacturing_outlined,
                    iconColor: AppTheme.primary,
                    pillarCode: 'M',
                    title: 'Methodology',
                    vietnameseTitle: 'Phương Pháp Luận',
                    description:
                        'Kiến trúc mô hình, giải thuật, công thức toán học, tập dữ liệu thực nghiệm và quy trình thử nghiệm.',
                  ),
                  const SizedBox(width: 10),
                  _buildBentoCard(
                    icon: Icons.insights_rounded,
                    iconColor: AppTheme.accent,
                    pillarCode: 'R',
                    title: 'Results',
                    vietnameseTitle: 'Kết Quả & Số Liệu',
                    description:
                        'Số liệu định lượng, bảng biểu so sánh, kết quả benchmark đánh giá so với các công trình trước.',
                  ),
                  const SizedBox(width: 10),
                  _buildBentoCard(
                    icon: Icons.forum_outlined,
                    iconColor: AppTheme.primaryDark,
                    pillarCode: 'D',
                    title: 'Discussion',
                    vietnameseTitle: 'Thảo Luận & Hạn Chế',
                    description:
                        'Phân tích ý nghĩa thực tiễn, làm rõ các hạn chế nghiên cứu và định hướng phát triển tương lai.',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBentoCard({
    required IconData icon,
    required Color iconColor,
    required String pillarCode,
    required String title,
    required String vietnameseTitle,
    required String description,
  }) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border, width: 1),
          boxShadow: AppTheme.softShadow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Decorative Gradient Strip
              Container(
                height: 3,
                decoration: const BoxDecoration(
                  gradient: AppTheme.cardAccentGradient,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            gradient: AppTheme.mintPillGradient,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: iconColor.withValues(alpha: 0.2)),
                          ),
                          child: Icon(icon, size: 16, color: iconColor),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: iconColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '[$pillarCode]',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    Text(
                      vietnameseTitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      description,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        color: AppTheme.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
