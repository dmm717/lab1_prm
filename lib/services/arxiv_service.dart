import 'dart:typed_data';
import 'package:http/http.dart' as http;

class ArxivService {
  /// Extracts the clean ArXiv ID from diverse user inputs
  /// Examples:
  /// - https://arxiv.org/abs/2312.00752
  /// - https://arxiv.org/pdf/2312.00752.pdf
  /// - http://arxiv.org/abs/2312.00752v2
  /// - arxiv:2312.00752
  /// - 2312.00752
  static String? extractArxivId(String input) {
    final cleanInput = input.trim();
    if (cleanInput.isEmpty) return null;

    // Regex matching standard ArXiv identifiers (new format e.g. 2312.00752 or 2312.00752v1, or old format e.g. hep-th/9901001)
    final regExp = RegExp(
      r'(?:arxiv\.org\/(?:abs|pdf)\/|arxiv:)?([a-zA-Z\-]+(?:\.[a-zA-Z]+)?\/\d{7}|\d{4}\.\d{4,5}(?:v\d+)?)',
      caseSensitive: false,
    );

    final match = regExp.firstMatch(cleanInput);
    if (match != null && match.groupCount >= 1) {
      String id = match.group(1)!;
      if (id.endsWith('.pdf')) {
        id = id.substring(0, id.length - 4);
      }
      return id;
    }
    return null;
  }

  /// Constructs the direct PDF download URL from an ArXiv ID
  static String getPdfUrl(String arxivId) {
    return 'https://arxiv.org/pdf/$arxivId.pdf';
  }

  /// Downloads the PDF from ArXiv as raw binary bytes
  static Future<Uint8List> downloadPdf(
    String arxivId, {
    void Function(int received, int total)? onProgress,
  }) async {
    final pdfUrl = getPdfUrl(arxivId);
    final request = http.Request('GET', Uri.parse(pdfUrl));
    request.headers['User-Agent'] = 'PaperChatAI/1.0 (Desktop Academic Client)';

    final client = http.Client();
    try {
      final response = await client.send(request);

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to download PDF from ArXiv. HTTP status: ${response.statusCode}',
        );
      }

      final contentLength = response.contentLength ?? 0;
      final List<int> bytes = [];

      await for (final chunk in response.stream) {
        bytes.addAll(chunk);
        if (onProgress != null && contentLength > 0) {
          onProgress(bytes.length, contentLength);
        }
      }

      return Uint8List.fromList(bytes);
    } finally {
      client.close();
    }
  }
}
