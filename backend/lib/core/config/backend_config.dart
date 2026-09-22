import 'dart:io';

/// Configuration owned by the backend process. Environment variables override
/// values in backend/.env so deployment can provide secrets without a file.
class BackendConfig {
  static final Map<String, String> _fileValues = _loadEnvFile();

  static String get geminiApiKey => _value('GEMINI_API_KEY');
  static String get geminiModel {
    final configured = _value('DEFAULT_GEMINI_MODEL');
    return configured.isEmpty ? 'gemini-3.6-flash' : configured;
  }

  static String get grobidUrl {
    final configured = _value('GROBID_URL');
    return configured.isEmpty ? 'http://localhost:8070' : configured;
  }

  static String _value(String name) {
    final value = Platform.environment[name]?.trim();
    if (value != null && value.isNotEmpty) return value;
    return _fileValues[name] ?? '';
  }

  static Map<String, String> _loadEnvFile() {
    for (final path in ['.env', 'backend/.env', '../backend/.env']) {
      final file = File(path);
      if (!file.existsSync()) continue;
      final values = <String, String>{};
      for (final line in file.readAsLinesSync()) {
        final trimmed = line.trim();
        if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
        final separator = trimmed.indexOf('=');
        if (separator <= 0) continue;
        final name = trimmed.substring(0, separator).trim();
        var value = trimmed.substring(separator + 1).trim();
        if (value.length >= 2 &&
            ((value.startsWith('"') && value.endsWith('"')) ||
                (value.startsWith("'") && value.endsWith("'")))) {
          value = value.substring(1, value.length - 1);
        }
        values[name] = value;
      }
      return values;
    }
    return {};
  }
}
