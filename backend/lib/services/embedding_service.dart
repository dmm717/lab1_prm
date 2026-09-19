import 'dart:math';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/paper_model.dart';

class EmbeddingService {
  static const String embeddingModelName = 'text-embedding-004';

  /// Computes the 768-dimensional vector embedding for a given text snippet using Gemini text-embedding-004
  static Future<List<double>> getEmbedding({
    required String text,
    required String apiKey,
  }) async {
    if (apiKey.isEmpty || text.trim().isEmpty) return [];

    try {
      final model = GenerativeModel(
        model: embeddingModelName,
        apiKey: apiKey,
      );

      // Truncate text if excessively long for embedding (max 2000 chars per chunk)
      final cleanText = text.length > 2000 ? text.substring(0, 2000) : text;
      final response = await model.embedContent(Content.text(cleanText));
      return response.embedding.values;
    } catch (_) {
      return [];
    }
  }

  /// Calculates cosine similarity between two vector embeddings
  static double cosineSimilarity(List<double> a, List<double> b) {
    if (a.isEmpty || b.isEmpty || a.length != b.length) return 0.0;

    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;

    for (int i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }

    if (normA == 0.0 || normB == 0.0) return 0.0;
    return dotProduct / (sqrt(normA) * sqrt(normB));
  }

  /// Automatically generates and caches embeddings for all sections of a paper
  static Future<void> embedPaperSections({
    required PaperModel paper,
    required String apiKey,
  }) async {
    if (apiKey.isEmpty || paper.sections.isEmpty) return;

    for (final section in paper.sections) {
      if (section.embedding == null || section.embedding!.isEmpty) {
        final text = '${section.displayName}\n${section.content}';
        if (text.trim().isNotEmpty) {
          section.embedding = await getEmbedding(text: text, apiKey: apiKey);
        }
      }
    }
  }

  /// Finds top-K most semantically relevant sections for a user's question via vector cosine similarity
  static Future<List<PaperSection>> findRelevantSections({
    required PaperModel paper,
    required String query,
    required String apiKey,
    int topK = 4,
  }) async {
    if (paper.sections.isEmpty) return [];

    // If only a few sections, return all
    if (paper.sections.length <= topK) {
      return paper.sections;
    }

    // 1. Get query embedding
    final queryEmbedding = await getEmbedding(text: query, apiKey: apiKey);
    if (queryEmbedding.isEmpty) {
      // Fallback if embedding service unavailable: return first topK sections
      return paper.sections.take(topK).toList();
    }

    // 2. Ensure section embeddings exist
    await embedPaperSections(paper: paper, apiKey: apiKey);

    // 3. Score each section
    final scoredSections = <MapEntry<PaperSection, double>>[];
    for (final section in paper.sections) {
      if (section.embedding != null && section.embedding!.isNotEmpty) {
        final score = cosineSimilarity(queryEmbedding, section.embedding!);
        scoredSections.add(MapEntry(section, score));
      } else {
        scoredSections.add(MapEntry(section, 0.0));
      }
    }

    // 4. Sort by highest similarity
    scoredSections.sort((a, b) => b.value.compareTo(a.value));

    // 5. Return top K
    return scoredSections.take(topK).map((e) => e.key).toList();
  }
}
