import 'package:xml/xml.dart';
import '../models/keyword_model.dart';
import '../models/paper_model.dart';
import '../models/paper_reference_model.dart';

class TeiParserService {
  /// Parses raw TEI-XML produced by GROBID into structured PaperModel data
  static PaperModel parse({
    required String teiXmlString,
    required String sourceId,
    required String sourceUrl,
    String? paperId,
  }) {
    final document = XmlDocument.parse(teiXmlString);

    // 1. Extract Title
    String title = _extractTitle(document);
    if (title.isEmpty) {
      title = 'Paper ($sourceId)';
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

    // 7. Extract Paper Codes & Identifiers (DOI, ISSN, ISBN, arXiv)
    final ids = _extractIdentifiers(document);

    // 8. Extract Journal / Venue / Publisher & Publication Details
    final venueDetails = _extractVenueDetails(document);

    // 9. Extract Bibliography / References
    final references = _extractReferences(document);

    return PaperModel(
      id: paperId ?? sourceId,
      sourceId: sourceId,
      sourceUrl: sourceUrl,
      title: title,
      authors: authors,
      abstractText: abstractText,
      publicationDate: publicationDate,
      sections: sections,
      keywords: initialKeywords,
      rawTeiXml: teiXmlString,
      doi: ids['doi'],
      issn: ids['issn'],
      isbn: ids['isbn'],
      arxivId: ids['arxiv'],
      journal: venueDetails['journal'],
      publisher: venueDetails['publisher'],
      volume: venueDetails['volume'],
      issue: venueDetails['issue'],
      pages: venueDetails['pages'],
      references: references,
    );
  }

  static String _extractTitle(XmlDocument doc) {
    try {
      final titleStmt = doc.findAllElements('titleStmt').firstOrNull;
      if (titleStmt != null) {
        final mainTitle = titleStmt
            .findElements('title')
            .firstWhere(
              (el) =>
                  el.getAttribute('type') == 'main' ||
                  el.getAttribute('level') == 'a',
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
      final teiHeader = doc.findAllElements('teiHeader').firstOrNull;
      final fileDesc = teiHeader?.findAllElements('fileDesc').firstOrNull;
      final authorElements = fileDesc?.findAllElements('author') ?? doc.findAllElements('author');

      for (final author in authorElements) {
        final persName = author.findElements('persName').firstOrNull;
        if (persName != null) {
          final forenames = persName
              .findElements('forename')
              .map((e) => e.innerText.trim())
              .join(' ');
          final surname =
              persName.findElements('surname').firstOrNull?.innerText.trim() ?? '';
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
        final paragraphs = abstractEl
            .findElements('p')
            .map((p) => p.innerText.trim())
            .toList();
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
      final dateEl = doc
          .findAllElements('date')
          .firstWhere(
            (el) => el.getAttribute('type') == 'published',
            orElse: () => doc.findAllElements('date').first,
          );
      return dateEl.getAttribute('when') ?? dateEl.innerText.trim();
    } catch (_) {}
    return null;
  }

  static Map<String, String> _extractIdentifiers(XmlDocument doc) {
    final result = <String, String>{};
    try {
      final idnoElements = doc.findAllElements('idno');
      for (final el in idnoElements) {
        final type = (el.getAttribute('type') ?? '').toLowerCase().trim();
        final text = el.innerText.trim();
        if (text.isEmpty) continue;

        if (type == 'doi') {
          result['doi'] = text;
        } else if (type == 'issn') {
          result['issn'] = text;
        } else if (type == 'isbn') {
          result['isbn'] = text;
        } else if (type == 'arxiv' || type == 'arxiv_id' || type.contains('arxiv')) {
          result['arxiv'] = text.replaceAll(RegExp(r'^arxiv:\s*', caseSensitive: false), '');
        }
      }

      // Regex fallbacks across full TEI document text if identifiers are missing
      final fullText = doc.toXmlString();

      // 1. arXiv ID fallback
      if (!result.containsKey('arxiv')) {
        final arxivMatch = RegExp(
          r'arXiv:\s*([0-9]{4}\.[0-9]{4,5}(?:v[0-9]+)?|[a-z\-]+(?:\.[A-Z]{2})?/[0-9]{7})',
          caseSensitive: false,
        ).firstMatch(fullText);
        if (arxivMatch != null) {
          result['arxiv'] = arxivMatch.group(1)!;
        }
      }

      // 2. ISBN fallback
      if (!result.containsKey('isbn')) {
        final isbnMatch = RegExp(
          r'(?:ISBN(?:-13|-10)?:\s*|978[- ]?)([0-9\-X]{10,17})',
          caseSensitive: false,
        ).firstMatch(fullText);
        if (isbnMatch != null) {
          final matched = isbnMatch.group(0)!;
          result['isbn'] = matched.replaceAll(RegExp(r'^ISBN(?:-13|-10)?:\s*', caseSensitive: false), '').trim();
        }
      }

      // 3. DOI fallback
      if (!result.containsKey('doi')) {
        final doiMatch = RegExp(r'\b(10\.\d{4,9}/[-._;()/:A-Za-z0-9]+)\b').firstMatch(fullText);
        if (doiMatch != null) {
          result['doi'] = doiMatch.group(1)!;
        }
      }

      // 4. ISSN fallback
      if (!result.containsKey('issn')) {
        final issnMatch = RegExp(r'\b(\d{4}-\d{3}[\dX])\b').firstMatch(fullText);
        if (issnMatch != null) {
          result['issn'] = issnMatch.group(1)!;
        }
      }

      // Check if DOI is arXiv DOI (10.48550/arXiv.xxxx.xxxx)
      if (result.containsKey('doi') && !result.containsKey('arxiv')) {
        final doiStr = result['doi']!;
        final doiArxiv = RegExp(r'10\.48550/arXiv\.([0-9]{4}\.[0-9]{4,5}(?:v[0-9]+)?)', caseSensitive: false)
            .firstMatch(doiStr);
        if (doiArxiv != null) {
          result['arxiv'] = doiArxiv.group(1)!;
        }
      }
    } catch (_) {}
    return result;
  }

  static Map<String, String> _extractVenueDetails(XmlDocument doc) {
    final result = <String, String>{};
    try {
      final teiHeader = doc.findAllElements('teiHeader').firstOrNull;
      if (teiHeader != null) {
        final monogr = teiHeader.findAllElements('monogr').firstOrNull;
        if (monogr != null) {
          final journalTitle = monogr.findElements('title').firstOrNull?.innerText.trim();
          if (journalTitle != null && journalTitle.isNotEmpty) {
            result['journal'] = journalTitle;
          }

          final publisher = monogr.findAllElements('publisher').firstOrNull?.innerText.trim();
          if (publisher != null && publisher.isNotEmpty) {
            result['publisher'] = publisher;
          }

          final scopes = monogr.findAllElements('biblScope');
          for (final scope in scopes) {
            final unit = scope.getAttribute('unit')?.toLowerCase();
            final val = scope.innerText.trim();
            if (val.isEmpty) continue;
            if (unit == 'volume') result['volume'] = val;
            if (unit == 'issue') result['issue'] = val;
            if (unit == 'page' || unit == 'pages') result['pages'] = val;
          }
        }
      }
    } catch (_) {}
    return result;
  }

  static List<PaperSection> _extractSections(XmlDocument doc) {
    final List<PaperSection> sections = [];
    try {
      final body = doc.findAllElements('body').firstOrNull;
      if (body != null) {
        final divs = body.findElements('div');
        for (final div in divs) {
          final head = div.findElements('head').firstOrNull;
          final sectionTitle = head?.innerText.trim() ?? 'Untitled Section';
          final sectionNumber = head?.getAttribute('n');

          final paragraphs = div
              .findElements('p')
              .map((p) => p.innerText.trim().replaceAll(RegExp(r'\s+'), ' '))
              .where((text) => text.isNotEmpty)
              .toList();

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
        if (text.isNotEmpty &&
            !keywords.any((k) => k.term.toLowerCase() == text.toLowerCase())) {
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

  static List<PaperReferenceModel> _extractReferences(XmlDocument doc) {
    final List<PaperReferenceModel> refs = [];
    try {
      final listBibl = doc.findAllElements('listBibl').firstOrNull;
      final biblNodes = listBibl != null
          ? listBibl.children.whereType<XmlElement>().where((e) => e.name.local == 'biblStruct' || e.name.local == 'bibl')
          : doc.findAllElements('biblStruct');

      int count = 0;
      for (final bibl in biblNodes) {
        count++;
        final id = bibl.getAttribute('xml:id') ?? 'b$count';

        final analytic = bibl.findElements('analytic').firstOrNull;
        final monogr = bibl.findElements('monogr').firstOrNull;

        String title = analytic?.findElements('title').firstOrNull?.innerText.trim() ??
            monogr?.findElements('title').firstOrNull?.innerText.trim() ??
            bibl.findElements('title').firstOrNull?.innerText.trim() ??
            '';

        if (title.isEmpty) {
          final fullText = bibl.innerText.trim();
          title = fullText.isNotEmpty ? fullText : 'Reference #$count';
        }

        final authors = <String>[];
        final authorNodes = analytic?.findElements('author') ?? monogr?.findElements('author') ?? bibl.findElements('author');
        for (final a in authorNodes) {
          final persName = a.findElements('persName').firstOrNull;
          if (persName != null) {
            final fore = persName.findElements('forename').map((e) => e.innerText.trim()).join(' ');
            final sur = persName.findElements('surname').firstOrNull?.innerText.trim() ?? '';
            final full = '$fore $sur'.trim();
            if (full.isNotEmpty) authors.add(full);
          } else {
            final nameText = a.innerText.trim();
            if (nameText.isNotEmpty && !authors.contains(nameText)) authors.add(nameText);
          }
        }

        final dateNode = monogr?.findAllElements('date').firstOrNull ?? bibl.findAllElements('date').firstOrNull;
        final year = dateNode?.getAttribute('when') ?? dateNode?.innerText.trim();

        final journal = monogr?.findElements('title').firstOrNull?.innerText.trim();

        String? doi;
        for (final idNode in bibl.findAllElements('idno')) {
          if ((idNode.getAttribute('type') ?? '').toLowerCase() == 'doi') {
            doi = idNode.innerText.trim();
            break;
          }
        }

        refs.add(
          PaperReferenceModel(
            id: id,
            title: title.replaceAll(RegExp(r'\s+'), ' '),
            authors: authors,
            year: year,
            journal: journal?.replaceAll(RegExp(r'\s+'), ' '),
            doi: doi,
            rawText: bibl.innerText.trim().replaceAll(RegExp(r'\s+'), ' '),
          ),
        );
      }
    } catch (_) {}
    return refs;
  }
}
