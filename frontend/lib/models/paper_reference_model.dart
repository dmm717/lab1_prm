import 'package:xml/xml.dart';

class PaperReferenceModel {
  final String id;
  final String title;
  final List<String> authors;
  final String? year;
  final String? journal;
  final String? doi;
  final String? url;
  final String? rawText;

  PaperReferenceModel({
    required this.id,
    required this.title,
    this.authors = const [],
    this.year,
    this.journal,
    this.doi,
    this.url,
    this.rawText,
  });

  factory PaperReferenceModel.fromJson(Map<String, dynamic> json) {
    return PaperReferenceModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      authors: (json['authors'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      year: json['year'] as String?,
      journal: json['journal'] as String?,
      doi: json['doi'] as String?,
      url: json['url'] as String?,
      rawText: json['rawText'] as String?,
    );
  }

  /// Recovers references from TEI saved by older app versions.
  static List<PaperReferenceModel> fromTeiXml(String teiXml) {
    if (!teiXml.contains('<listBibl')) return [];
    try {
      final document = XmlDocument.parse(teiXml);
      final bibliography = document.findAllElements('listBibl').firstOrNull;
      if (bibliography == null) return [];
      final references = <PaperReferenceModel>[];
      for (final entry in bibliography.children.whereType<XmlElement>()) {
        if (entry.name.local != 'biblStruct' && entry.name.local != 'bibl') {
          continue;
        }
        final analytic = entry.findElements('analytic').firstOrNull;
        final monograph = entry.findElements('monogr').firstOrNull;
        final rawText = entry.innerText.trim().replaceAll(RegExp(r'\s+'), ' ');
        final title = analytic
                ?.findElements('title')
                .firstOrNull
                ?.innerText
                .trim() ??
            monograph?.findElements('title').firstOrNull?.innerText.trim() ??
            entry.findElements('title').firstOrNull?.innerText.trim() ??
            rawText;
        final authorElements = analytic?.findElements('author') ??
            monograph?.findElements('author') ??
            entry.findElements('author');
        final authors = authorElements
            .map((author) {
              final name = author.findElements('persName').firstOrNull;
              if (name == null) return author.innerText.trim();
              final firstNames = name
                  .findElements('forename')
                  .map((part) => part.innerText.trim());
              final surname =
                  name.findElements('surname').firstOrNull?.innerText.trim();
              return [...firstNames, if (surname != null) surname]
                  .join(' ')
                  .trim();
            })
            .where((author) => author.isNotEmpty)
            .toList();
        final date = monograph?.findAllElements('date').firstOrNull ??
            entry.findAllElements('date').firstOrNull;
        final doi = entry
            .findAllElements('idno')
            .where((id) => id.getAttribute('type')?.toLowerCase() == 'doi')
            .firstOrNull
            ?.innerText
            .trim();
        references.add(PaperReferenceModel(
          id: entry.getAttribute('xml:id') ?? 'b${references.length}',
          title: title.replaceAll(RegExp(r'\s+'), ' '),
          authors: authors,
          year: date?.getAttribute('when') ?? date?.innerText.trim(),
          journal:
              monograph?.findElements('title').firstOrNull?.innerText.trim(),
          doi: doi,
          rawText: rawText,
        ));
      }
      return references;
    } catch (_) {
      return [];
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'authors': authors,
        if (year != null) 'year': year,
        if (journal != null) 'journal': journal,
        if (doi != null) 'doi': doi,
        if (url != null) 'url': url,
        if (rawText != null) 'rawText': rawText,
      };
}
