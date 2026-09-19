import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
    await controller.updateSettings(
      apiKey: _apiKeyController.text,
      grobidUrl: _grobidUrlController.text,
      model: _selectedModel,
    );
    final alive = await controller.checkGrobidHealth();

    setState(() {
      _testingConnection = false;
      _testResult = alive ? 'Máy chủ GROBID đang hoạt động bình thường!' : 'Kết nối thất bại. Hãy kiểm tra GROBID hoặc Docker đã bật chưa.';
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
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: AppTheme.border),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: Padding(
          padding: const EdgeInsets.all(26.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: AppTheme.primarySubtle,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.tune_rounded, color: AppTheme.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cài Đặt Hệ Thống',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                      Text(
                        'Quản lý mô hình AI, khóa API và cổng dịch vụ tài liệu',
                        style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20, color: AppTheme.textMuted),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 1. Google Gemini API Key
              Text(
                'Khóa Google Gemini API Key',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _apiKeyController,
                obscureText: _obscureKey,
                style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary, fontSize: 13.5),
                decoration: InputDecoration(
                  hintText: 'Nhập AI Studio API Key (AIzaSy...)',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureKey ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                      size: 18,
                      color: AppTheme.textMuted,
                    ),
                    onPressed: () => setState(() => _obscureKey = !_obscureKey),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Dùng cho vector embedding (text-embedding-004) và suy luận Gemini 2.0.',
                style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 18),

              // 2. AI Model Selection
              Text(
                'Chọn Phiên Bản Mô Hình Gemini',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _selectedModel,
                dropdownColor: AppTheme.surface,
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.textPrimary,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                ),
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                items: [
                  DropdownMenuItem(
                    value: AppConstants.defaultGeminiModel,
                    child: Text(
                      'Gemini 3.5 Flash (Siêu nhanh, tối ưu RAG)',
                      style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary),
                    ),
                  ),
                  DropdownMenuItem(
                    value: AppConstants.advancedGeminiModel,
                    child: Text(
                      'Gemini 3.1 Pro (Ngữ cảnh học thuật chuyên sâu)',
                      style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary),
                    ),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedModel = val);
                },
              ),
              const SizedBox(height: 18),

              // 3. GROBID Service Endpoint
              Text(
                'Địa Chỉ Cổng Dịch Vụ GROBID',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _grobidUrlController,
                      style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary, fontSize: 13.5),
                      decoration: const InputDecoration(
                        hintText: 'http://localhost:8070',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: _testingConnection ? null : _testGrobid,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundSubtle,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: _testingConnection
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
                            )
                          : Text(
                              'Kiểm Tra',
                              style: GoogleFonts.plusJakartaSans(
                                color: AppTheme.primary,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
              if (_testResult != null) ...[
                const SizedBox(height: 6),
                Text(
                  _testResult!,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _testResult!.contains('hoạt động') ? AppTheme.accent : AppTheme.error,
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
                    child: Text(
                      'Hủy',
                      style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _saveSettings,
                    child: const Text('Lưu Thay Đổi'),
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

