import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/paper_controller.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/arxiv_input_bar.dart';
import '../widgets/chat_panel.dart';
import '../widgets/grobid_status_badge.dart';
import '../widgets/paper_overview_panel.dart';
import '../widgets/settings_dialog.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PaperController>();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.psychology_outlined, color: AppTheme.primaryLight, size: 22),
            ),
            const SizedBox(width: 10),
            const Text(
              'PaperChat AI',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'GROBID + Gemini',
                style: TextStyle(fontSize: 10, color: AppTheme.secondary, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        actions: [
          const GrobidStatusBadge(),
          const SizedBox(width: 12),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined, color: AppTheme.textSecondary),
            onPressed: () => SettingsDialog.show(context),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Top ArXiv Input Section
            const ArxivInputBar(),
            const SizedBox(height: 16),

            // Main Content Area
            Expanded(
              child: controller.hasPaper
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Left Pane: Paper Outline & Key Insights (42% width)
                        Expanded(
                          flex: 42,
                          child: PaperOverviewPanel(paper: controller.currentPaper!),
                        ),
                        const SizedBox(width: 16),

                        // Right Pane: Conversational Chat (58% width)
                        const Expanded(
                          flex: 58,
                          child: ChatPanel(),
                        ),
                      ],
                    )
                  : _buildWelcomeHero(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeHero(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  size: 56,
                  color: AppTheme.primaryLight,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Intelligent Research Paper Dialogue',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Enter an ArXiv paper link above to extract structured sections via local GROBID\n'
                'and conduct deep, grounded academic question-and-answer dialogues with Gemini AI.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppTheme.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 36),

              // Feature Cards Grid
              Row(
                children: [
                  _buildFeatureCard(
                    icon: Icons.hub_outlined,
                    iconColor: AppTheme.secondary,
                    title: 'GROBID TEI-XML Extraction',
                    description:
                        'Parses scientific documents into precise hierarchical sections, authors, abstracts, and citations.',
                  ),
                  const SizedBox(width: 16),
                  _buildFeatureCard(
                    icon: Icons.vpn_key_outlined,
                    iconColor: AppTheme.accent,
                    title: 'Interactive Key Concepts',
                    description:
                        'Automatically identifies and categorizes the paper\'s core keywords. Click any concept to ask AI.',
                  ),
                  const SizedBox(width: 16),
                  _buildFeatureCard(
                    icon: Icons.all_inclusive,
                    iconColor: AppTheme.primaryLight,
                    title: 'Zero Context Loss',
                    description:
                        'Powered by Gemini 2.0 / 1.5 with 1M+ token context. Analyzes the full paper text without fragmented chunking.',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.surfaceVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 24, color: iconColor),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
