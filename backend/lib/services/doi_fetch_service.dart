import 'dart:convert';
import 'package:dio/dio.dart';

class DoiFetchResult {
  final String? doi;
  final String? title;
  final List<String> authors;
  final String? journal;
  final String? publisher;
  final String? issn;
  final String? isbn;
  final String? arxivId;
  final String? publicationDate;
  final String? volume;
  final String? issue;
  final String? pages;
  final int? citationCount;
  final String? url;

  DoiFetchResult({
    this.doi,
    this.title,
    this.authors = const [],
    this.journal,
    this.publisher,
    this.issn,
    this.isbn,
    this.arxivId,
    this.publicationDate,
    this.volume,
    this.issue,
    this.pages,
    this.citationCount,
    this.url,
  });

  Map<String, dynamic> toJson() => {
        if (doi != null) 'doi': doi,
        if (title != null) 'title': title,
        'authors': authors,
        if (journal != null) 'journal': journal,
        if (publisher != null) 'publisher': publisher,
        if (issn != null) 'issn': issn,
        if (isbn != null) 'isbn': isbn,
        if (arxivId != null) 'arxivId': arxivId,
        if (publicationDate != null) 'publicationDate': publicationDate,
        if (volume != null) 'volume': volume,
        if (issue != null) 'issue': issue,
        if (pages != null) 'pages': pages,
        if (citationCount != null) 'citationCount': citationCount,
        if (url != null) 'url': url,
      };
}

class DoiFetchService {
  final Dio _dio;

  DoiFetchService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 8),
                receiveTimeout: const Duration(seconds: 8),
                headers: {
                  'User-Agent':
                      'PaperChatAI/1.0 (mailto:admin@paperchatai.local)',
                },
              ),
            );

  /// Resolves paper DOI and CrossRef metadata via paper title or direct DOI string.
  Future<DoiFetchResult?> fetchMetadata({
    required String title,
    String? doi,
  }) async {
    try {
      if (doi != null && doi.trim().isNotEmpty) {
        final cleanDoi = doi.trim().replaceAll(RegExp(r'^https?://(dx\.)?doi\.org/'), '');
        final response = await _dio.get('https://api.crossref.org/works/$cleanDoi');
        if (response.statusCode == 200 && response.data != null) {
          final message = response.data['message'] as Map<String, dynamic>?;
          if (message != null) {
            return _parseCrossRefMessage(message);
          }
        }
      }

      final queryTitle = title.trim();
      if (queryTitle.isEmpty) return null;

      final response = await _dio.get(
        'https://api.crossref.org/works',
        queryParameters: {
          'query.bibliographic': queryTitle,
          'rows': 1,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final items = response.data['message']?['items'] as List<dynamic>?;
        if (items != null && items.isNotEmpty) {
          return _parseCrossRefMessage(items.first as Map<String, dynamic>);
        }
      }
    } catch (_) {}
    return null;
  }

  DoiFetchResult _parseCrossRefMessage(Map<String, dynamic> msg) {
    final doiStr = msg['DOI']?.toString();
    final titles = msg['title'] as List<dynamic>?;
    final titleStr = (titles != null && titles.isNotEmpty) ? titles.first.toString() : null;

    final authorsList = <String>[];
    final authors = msg['author'] as List<dynamic>?;
    if (authors != null) {
      for (final a in authors) {
        if (a is Map<String, dynamic>) {
          final given = a['given']?.toString() ?? '';
          final family = a['family']?.toString() ?? '';
          final full = '$given $family'.trim();
          if (full.isNotEmpty) authorsList.add(full);
        }
      }
    }

    final containerTitles = msg['container-title'] as List<dynamic>?;
    final journalStr = (containerTitles != null && containerTitles.isNotEmpty)
        ? containerTitles.first.toString()
        : null;

    final publisherStr = msg['publisher']?.toString();

    final issns = msg['ISSN'] as List<dynamic>?;
    final issnStr = (issns != null && issns.isNotEmpty) ? issns.first.toString() : null;

    final isbns = msg['ISBN'] as List<dynamic>?;
    final isbnStr = (isbns != null && isbns.isNotEmpty) ? isbns.first.toString() : null;

    String? arxivStr;
    if (doiStr != null) {
      final arxivMatch = RegExp(r'10\.48550/arXiv\.([0-9]{4}\.[0-9]{4,5}(?:v[0-9]+)?)', caseSensitive: false)
          .firstMatch(doiStr);
      if (arxivMatch != null) {
        arxivStr = arxivMatch.group(1);
      }
    }
    if (arxivStr == null) {
      final altIds = msg['alternative-id'] as List<dynamic>?;
      if (altIds != null) {
        for (final id in altIds) {
          final idS = id.toString();
          if (idS.toLowerCase().contains('arxiv')) {
            arxivStr = idS.replaceAll(RegExp(r'^arxiv:\s*', caseSensitive: false), '');
            break;
          }
        }
      }
    }

    String? pubDate;
    final published = msg['published-print'] ?? msg['published-online'] ?? msg['created'];
    if (published is Map<String, dynamic> && published['date-parts'] is List) {
      final parts = (published['date-parts'] as List).firstOrNull as List<dynamic>?;
      if (parts != null && parts.isNotEmpty) {
        pubDate = parts.join('-');
      }
    }

    final volumeStr = msg['volume']?.toString();
    final issueStr = msg['issue']?.toString();
    final pagesStr = msg['page']?.toString();
    final citationCount = msg['is-referenced-by-count'] as int?;
    final urlStr = msg['URL']?.toString() ?? (doiStr != null ? 'https://doi.org/$doiStr' : null);

    return DoiFetchResult(
      doi: doiStr,
      title: titleStr,
      authors: authorsList,
      journal: journalStr,
      publisher: publisherStr,
      issn: issnStr,
      isbn: isbnStr,
      arxivId: arxivStr,
      publicationDate: pubDate,
      volume: volumeStr,
      issue: issueStr,
      pages: pagesStr,
      citationCount: citationCount,
      url: urlStr,
    );
  }
}
