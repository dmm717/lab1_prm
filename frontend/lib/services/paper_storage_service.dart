import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_message.dart';
import '../models/paper_model.dart';

class PaperStorageService {
  static const String _keyRecentIds = 'recent_paper_ids';
  static const String _prefixPaper = 'paper_data_';
  static const String _prefixChat = 'chat_history_';
  static const int _maxSavedPapers = 20;

  /// Saves or updates a paper in local storage
  Future<void> savePaper(PaperModel paper) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 1. Save the paper's full JSON
      final paperJson = jsonEncode(paper.toJson());
      await prefs.setString('$_prefixPaper${paper.id}', paperJson);

      // 2. Update recent paper IDs list
      List<String> recentIds = prefs.getStringList(_keyRecentIds) ?? [];
      recentIds.remove(paper.id); // Remove if existing to move to top
      recentIds.insert(0, paper.id);

      if (recentIds.length > _maxSavedPapers) {
        // Evict oldest paper and its chat
        final removedId = recentIds.removeLast();
        await prefs.remove('$_prefixPaper$removedId');
        await prefs.remove('$_prefixChat$removedId');
      }

      await prefs.setStringList(_keyRecentIds, recentIds);
    } catch (_) {}
  }

  /// Retrieves all saved papers in order of most recent first
  Future<List<PaperModel>> getRecentPapers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recentIds = prefs.getStringList(_keyRecentIds) ?? [];
      final List<PaperModel> papers = [];

      for (final id in recentIds) {
        final jsonStr = prefs.getString('$_prefixPaper$id');
        if (jsonStr != null && jsonStr.isNotEmpty) {
          try {
            final map = jsonDecode(jsonStr) as Map<String, dynamic>;
            final paper = PaperModel.fromJson(map);
            papers.add(paper);
            final storedReferences = map['references'];
            if ((storedReferences is! List || storedReferences.isEmpty) &&
                paper.references.isNotEmpty) {
              await prefs.setString(
                  '$_prefixPaper$id', jsonEncode(paper.toJson()));
            }
          } catch (_) {}
        }
      }

      return papers;
    } catch (_) {
      return [];
    }
  }

  /// Deletes a specific paper and its conversation history from storage
  Future<void> deletePaper(String paperId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recentIds = prefs.getStringList(_keyRecentIds) ?? [];
      recentIds.remove(paperId);
      await prefs.setStringList(_keyRecentIds, recentIds);
      await prefs.remove('$_prefixPaper$paperId');
      await prefs.remove('$_prefixChat$paperId');
    } catch (_) {}
  }

  /// Saves chat messages for a specific paper
  Future<void> saveChatHistory(
      String paperId, List<ChatMessage> messages) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Filter out messages that are currently streaming with empty content
      final validMessages = messages
          .where((m) => !(m.isStreaming && m.content.isEmpty))
          .map((m) => m.toJson())
          .toList();

      final jsonStr = jsonEncode(validMessages);
      await prefs.setString('$_prefixChat$paperId', jsonStr);
    } catch (_) {}
  }

  /// Loads chat messages for a specific paper
  Future<List<ChatMessage>> getChatHistory(String paperId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString('$_prefixChat$paperId');
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final list = jsonDecode(jsonStr) as List<dynamic>;
        return list
            .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  /// Clears all stored papers and chats
  Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recentIds = prefs.getStringList(_keyRecentIds) ?? [];
      for (final id in recentIds) {
        await prefs.remove('$_prefixPaper$id');
        await prefs.remove('$_prefixChat$id');
      }
      await prefs.remove(_keyRecentIds);
    } catch (_) {}
  }
}
