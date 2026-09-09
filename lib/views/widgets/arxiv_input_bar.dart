import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/paper_controller.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';

class ArxivInputBar extends StatefulWidget {
  const ArxivInputBar({super.key});

  @override
  State<ArxivInputBar> createState() => _ArxivInputBarState();
}

class _ArxivInputBarState extends State<ArxivInputBar> {
  final TextEditingController _urlController = TextEditingController();

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    final text = _urlController.text.trim();
    if (text.isNotEmpty) {
      context.read<PaperController>().processArxivUrl(text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PaperController>();
    final isBusy = controller.stage != IngestionStage.idle &&
        controller.stage != IngestionStage.completed &&
        controller.stage != IngestionStage.error;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _urlController,
                enabled: !isBusy,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Enter ArXiv Link (e.g., https://arxiv.org/abs/2312.00752)',
                  prefixIcon: const Icon(Icons.link, color: AppTheme.textMuted),
                  suffixIcon: _urlController.text.isNotEmpty && !isBusy
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            setState(() {
                              _urlController.clear();
                            });
                          },
                        )
                      : null,
                ),
                onSubmitted: (_) => _handleSubmit(),
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: isBusy ? null : _handleSubmit,
              icon: isBusy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(isBusy ? 'Processing...' : 'Analyze Paper'),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Quick Sample Links Row
        Row(
          children: [
            const Text(
              'Try Sample: ',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
            ),
            const SizedBox(width: 6),
            _buildSampleChip('Attention (Transformer)', AppConstants.sampleArxivLinks[0]),
            const SizedBox(width: 6),
            _buildSampleChip('GPT-3', AppConstants.sampleArxivLinks[1]),
            const SizedBox(width: 6),
            _buildSampleChip('Mamba (SSM)', AppConstants.sampleArxivLinks[2]),
          ],
        ),

        // Processing status banner / progress bar
        if (isBusy) ...[
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: controller.progress > 0 ? controller.progress : null,
              backgroundColor: AppTheme.surfaceVariant,
              color: AppTheme.primary,
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 1.5, color: AppTheme.primary),
              ),
              const SizedBox(width: 8),
              Text(
                controller.statusMessage,
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ],

        // Error message banner
        if (controller.errorMessage != null && !isBusy) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.error.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.error.withOpacity(0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, size: 18, color: AppTheme.error),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    controller.errorMessage!,
                    style: const TextStyle(color: AppTheme.error, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSampleChip(String label, String url) {
    return InkWell(
      onTap: () {
        setState(() {
          _urlController.text = url;
        });
        context.read<PaperController>().processArxivUrl(url);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariant.withOpacity(0.6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppTheme.primaryLight,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
