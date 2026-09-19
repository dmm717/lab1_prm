import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;

  final Map<String, Map<String, dynamic>> _memoryCache = {};
  late final Directory _cacheDir;
  bool _initialized = false;

  CacheService._internal() {
    _init();
  }

  void _init() {
    if (_initialized) return;
    try {
      _cacheDir = Directory('.cache/papers');
      if (!_cacheDir.existsSync()) {
        _cacheDir.createSync(recursive: true);
      }
      _initialized = true;
    } catch (_) {
      // If filesystem access fails, memory cache still functions
    }
  }

  /// Generates a deterministic unique key for a paper based on sourceId and byte signature
  String generateKey(String sourceId, Uint8List bytes) {
    final cleanSource = sourceId.trim().replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    
    // Fast 32-bit FNV-1a hash over bytes
    int hash = 0x811c9dc5;
    final step = bytes.length > 50000 ? (bytes.length ~/ 50000) : 1;
    for (int i = 0; i < bytes.length; i += step) {
      hash ^= bytes[i];
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    
    final hashStr = hash.toRadixString(16).padLeft(8, '0');
    if (cleanSource.isNotEmpty && cleanSource != 'paper.pdf') {
      return '${cleanSource}_$hashStr';
    }
    return 'doc_${bytes.length}_$hashStr';
  }

  /// Retrieves cached paper JSON if available
  Map<String, dynamic>? get(String key) {
    if (_memoryCache.containsKey(key)) {
      return _memoryCache[key];
    }

    if (_initialized) {
      try {
        final file = File('${_cacheDir.path}/$key.json');
        if (file.existsSync()) {
          final content = file.readAsStringSync();
          final data = jsonDecode(content) as Map<String, dynamic>;
          _memoryCache[key] = data; // Populate memory cache
          return data;
        }
      } catch (_) {}
    }

    return null;
  }

  /// Caches the paper JSON in memory and persists to disk
  void set(String key, Map<String, dynamic> paperJson) {
    _memoryCache[key] = paperJson;

    if (_initialized) {
      try {
        final file = File('${_cacheDir.path}/$key.json');
        file.writeAsStringSync(jsonEncode(paperJson));
      } catch (_) {}
    }
  }

  /// Checks if a key is cached
  bool has(String key) => _memoryCache.containsKey(key) || (_initialized && File('${_cacheDir.path}/$key.json').existsSync());

  /// Clears in-memory and disk cache
  void clear() {
    _memoryCache.clear();
    if (_initialized) {
      try {
        if (_cacheDir.existsSync()) {
          _cacheDir.deleteSync(recursive: true);
          _cacheDir.createSync(recursive: true);
        }
      } catch (_) {}
    }
  }
}
