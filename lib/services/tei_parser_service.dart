import 'package:xml/xml.dart';
import '../models/keyword_model.dart';
import '../models/paper_model.dart';

class TeiParserService {
  /// Parses raw TEI-XML produced by GROBID into structured PaperModel data
  static PaperModel parse({
    required String teiXmlString,
    required String arxivId,
    required String arxivUrl,
  }) {
    final document = XmlDocument.parse(teiXmlString);

    // 1. Extract Title
    String title = _extractTitle(document);
    if (title.isEmpty) {
      title = 'ArXiv Paper ($arxivId)';
    }

    // 2. Extract Authors
    final authors = _extractAuthors(document);

    // 3. Extract Abstract
    final abstractText = _extractAbstract(document);

    // 4. Extract Publication Date
    final publicationDate = _extractPublicationDate(document);

    // 5. Extract Structured Sections
    final sections = _extractSections(document);

    // 6. Extract TEI-tagged Keywords (if any)
    final initialKeywords = _extractTeiKeywords(document);

    return PaperModel(
      id: arxivId,
      arxivId: arxivId,
      arxivUrl: arxivUrl,
      title: title,
      authors: authors,
      abstractText: abstractText,
      publicationDate: publicationDate,
      sections: sections,
      keywords: initialKeywords,
      rawTeiXml: teiXmlString,
    );
  }

  static String _extractTitle(XmlDocument doc) {
    try {
      final titleStmt = doc.findAllElements('titleStmt').firstOrNull;
      if (titleStmt != null) {
        final mainTitle = titleStmt.findElements('title').firstWhere(
              (el) => el.getAttribute('type') == 'main' || el.getAttribute('level') == 'a',
              orElse: () => titleStmt.findElements('title').first,
            );
        return mainTitle.innerText.trim().replaceAll(RegExp(r'\s+'), ' ');
      }
    } catch (_) {}

    // Fallback: any title element
    final fallback = doc.findAllElements('title').firstOrNull;
    return fallback?.innerText.trim().replaceAll(RegExp(r'\s+'), ' ') ?? '';
  }

  static List<String> _extractAuthors(XmlDocument doc) {
    final List<String> authors = [];
    try {
      final authorElements = doc.findAllElements('author');
      for (final author in authorElements) {
        final persName = author.findElements('persName').firstOrNull;
        if (persName != null) {
          final forenames = persName
              .findElements('forename')
              .map((e) => e.innerText.trim())
              .join(' ');
          final surname = persName.findElements('surname').firstOrNull?.innerText.trim() ?? '';
          final fullName = '$forenames $surname'.trim();
          if (fullName.isNotEmpty && !authors.contains(fullName)) {
            authors.add(fullName);
          }
        }
      }
    } catch (_) {}
    return authors;
  }

  static String _extractAbstract(XmlDocument doc) {
    try {
      final abstractEl = doc.findAllElements('abstract').firstOrNull;
      if (abstractEl != null) {
        final paragraphs = abstractEl.findElements('p').map((p) => p.innerText.trim()).toList();
        if (paragraphs.isNotEmpty) {
          return paragraphs.join('\n\n');
        }
        return abstractEl.innerText.trim();
      }
    } catch (_) {}
    return '';
  }

  static String? _extractPublicationDate(XmlDocument doc) {
    try {
      final dateEl = doc.findAllElements('date').firstWhere(
            (el) => el.getAttribute('type') == 'published',
            orElse: () => doc.findAllElements('date').first,
          );
      return dateEl.getAttribute('when') ?? dateEl.innerText.trim();
    } catch (_) {}
    return null;
  }

  static List<PaperSection> _extractSections(XmlDocument doc) {
    final List<PaperSection> sections = [];
    try {
      // GROBID body sections are typically under <text><body><div>
      final body = doc.findAllElements('body').firstOrNull;
      if (body != null) {
        final divs = body.findElements('div');
        for (final div in divs) {
          final head = div.findElements('head').firstOrNull;
          final sectionTitle = head?.innerText.trim() ?? 'Untitled Section';
          final sectionNumber = head?.getAttribute('n');

          // Collect all paragraphs <p> inside this div
          final paragraphs = div.findElements('p').map((p) {
            return p.innerText.trim().replaceAll(RegExp(r'\s+'), ' ');
          }).where((text) => text.isNotEmpty).toList();

          if (paragraphs.isNotEmpty || sectionTitle.isNotEmpty) {
            sections.add(
              PaperSection(
                title: sectionTitle,
                content: paragraphs.join('\n\n'),
                sectionNumber: sectionNumber,
              ),
            );
          }
        }
      }
    } catch (_) {}

    return sections;
  }

  static List<KeywordModel> _extractTeiKeywords(XmlDocument doc) {
    final List<KeywordModel> keywords = [];
    try {
      final terms = doc.findAllElements('term');
      for (final term in terms) {
        final text = term.innerText.trim();
        if (text.isNotEmpty && !keywords.any((k) => k.term.toLowerCase() == text.toLowerCase())) {
          keywords.add(
            KeywordModel(
              term: text,
              category: 'Extracted',
              context: 'Identified in paper metadata',
            ),
          );
        }
      }
    } catch (_) {}
    return keywords;
  }
}
