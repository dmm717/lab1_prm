import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/paper_controller.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';

class SettingsDialog extends StatefulWidget {
  const SettingsDialog({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const SettingsDialog(),
    );
  }

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  late TextEditingController _apiKeyController;
  late TextEditingController _grobidUrlController;
  late String _selectedModel;
  bool _obscureKey = true;
  bool _testingConnection = false;
  String? _testResult;

  @override
  void initState() {
    super.initState();
    final controller = context.read<PaperController>();
    _apiKeyController = TextEditingController(text: controller.geminiApiKey);
    _grobidUrlController = TextEditingController(text: controller.grobidUrl);
    _selectedModel = controller.selectedModel;
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _grobidUrlController.dispose();
    super.dispose();
  }

  Future<void> _testGrobid() async {
    setState(() {
      _testingConnection = true;
      _testResult = null;
    });

    final controller = context.read<PaperController>();
    // Temporarily test with the entered URL
    await controller.updateSettings(
      apiKey: _apiKeyController.text,
      grobidUrl: _grobidUrlController.text,
      model: _selectedModel,
    );
    final alive = await controller.checkGrobidHealth();

    setState(() {
      _testingConnection = false;
      _testResult = alive ? 'GROBID server is active!' : 'Connection failed. Is Docker running?';
    });
  }

  void _saveSettings() {
    context.read<PaperController>().updateSettings(
          apiKey: _apiKeyController.text,
          grobidUrl: _grobidUrlController.text,
          model: _selectedModel,
        );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.surfaceVariant),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  const Icon(Icons.settings, color: AppTheme.primaryLight),
                  const SizedBox(width: 8),
                  const Text(
                    'Application Settings',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20, color: AppTheme.textMuted),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 1. Google Gemini API Key
              const Text(
                'Google Gemini API Key',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _apiKeyController,
                obscureText: _obscureKey,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Enter AI Studio API Key (AIzaSy...)',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureKey ? Icons.visibility_off : Icons.visibility,
                      size: 18,
                      color: AppTheme.textMuted,
                    ),
                    onPressed: () => setState(() => _obscureKey = !_obscureKey),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Used for automated keyword extraction and paper chat (get free at aistudio.google.com)',
                style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 16),

              // 2. AI Model Selection
              const Text(
                'Gemini Model Tier',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _selectedModel,
                dropdownColor: AppTheme.surfaceVariant,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                items: const [
                  DropdownMenuItem(
                    value: AppConstants.defaultGeminiModel,
                    child: Text('Gemini 2.0 Flash (Fast & Cost-Efficient)'),
                  ),
                  DropdownMenuItem(
                    value: AppConstants.advancedGeminiModel,
                    child: Text('Gemini 1.5 Pro (Deepest Academic Reasoning)'),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedModel = val);
                },
              ),
              const SizedBox(height: 16),

              // 3. GROBID Service Endpoint
              const Text(
                'Local GROBID Server Endpoint',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _grobidUrlController,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: const InputDecoration(
                        hintText: 'http://localhost:8070',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: _testingConnection ? null : _testGrobid,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.primaryLight),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    ),
                    child: _testingConnection
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 1.5),
                          )
                        : const Text('Test', style: TextStyle(color: AppTheme.primaryLight)),
                  ),
                ],
              ),
              if (_testResult != null) ...[
                const SizedBox(height: 6),
                Text(
                  _testResult!,
                  style: TextStyle(
                    fontSize: 12,
                    color: _testResult!.contains('active') ? AppTheme.accent : AppTheme.error,
                  ),
                ),
              ],
              const SizedBox(height: 24),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _saveSettings,
                    child: const Text('Save Changes'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
