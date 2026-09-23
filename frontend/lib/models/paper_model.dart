import 'imgrad_model.dart';
import 'keyword_model.dart';
import 'paper_reference_model.dart';

class PaperSection {
  final String title;
  final String content;
  final String? sectionNumber;
  List<double>? embedding;

  PaperSection({
    required this.title,
    required this.content,
    this.sectionNumber,
    this.embedding,
  });

  String get displayName => sectionNumber != null && sectionNumber!.isNotEmpty
      ? '$sectionNumber $title'
      : title;

  factory PaperSection.fromJson(Map<String, dynamic> json) => PaperSection(
        title: json['title'] as String? ?? '',
        content: json['content'] as String? ?? '',
        sectionNumber: json['sectionNumber'] as String?,
        embedding: (json['embedding'] as List<dynamic>?)
            ?.map((e) => (e as num).toDouble())
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'content': content,
        'sectionNumber': sectionNumber,
        if (embedding != null) 'embedding': embedding,
      };
}

class PaperModel {
  final String id;
  String sourceUrl;
  final String sourceId;
  String title;
  List<String> authors;
  String abstractText;
  String? publicationDate;
  List<PaperSection> sections;
  List<KeywordModel> keywords;
  String executiveSummary;
  List<String> contributions;
  List<String> suggestedQuestions;
  String rawTeiXml;
  bool isFallback;
  ImgradModel? imgrad;

  // Metadata & Identification fields
  String? doi;
  String? issn;
  String? isbn;
  String? arxivId;
  String? journal;
  String? publisher;
  String? volume;
  String? issue;
  String? pages;
  List<PaperReferenceModel> references;
  int? citationCount;

  String get paperCodeDisplay {
    if (doi != null && doi!.trim().isNotEmpty) return 'DOI: $doi';
    if (issn != null && issn!.trim().isNotEmpty) return 'ISSN: $issn';
    if (arxivId != null && arxivId!.trim().isNotEmpty) return 'arXiv: $arxivId';
    if (isbn != null && isbn!.trim().isNotEmpty) return 'ISBN: $isbn';
    return sourceId.isNotEmpty ? 'Mã: $sourceId' : 'Mã: $id';
  }

  PaperModel({
    required this.id,
    required this.sourceUrl,
    required this.sourceId,
    required this.title,
    this.authors = const [],
    required this.abstractText,
    this.publicationDate,
    this.sections = const [],
    this.keywords = const [],
    this.executiveSummary = '',
    this.contributions = const [],
    this.suggestedQuestions = const [],
    this.rawTeiXml = '',
    this.isFallback = false,
    this.imgrad,
    this.doi,
    this.issn,
    this.isbn,
    this.arxivId,
    this.journal,
    this.publisher,
    this.volume,
    this.issue,
    this.pages,
    this.references = const [],
    this.citationCount,
  });

  factory PaperModel.fromJson(Map<String, dynamic> json) => PaperModel(
        id: json['id'] as String? ?? '',
        sourceUrl: json['sourceUrl'] as String? ?? '',
        sourceId: json['sourceId'] as String? ?? '',
        title: json['title'] as String? ?? '',
        authors: (json['authors'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        abstractText: json['abstractText'] as String? ?? '',
        publicationDate: json['publicationDate'] as String?,
        sections: (json['sections'] as List<dynamic>?)
                ?.map((e) => PaperSection.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        keywords: (json['keywords'] as List<dynamic>?)
                ?.map((e) => KeywordModel.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        executiveSummary: json['executiveSummary'] as String? ?? '',
        contributions: (json['contributions'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        suggestedQuestions: (json['suggestedQuestions'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        rawTeiXml: json['rawTeiXml'] as String? ?? '',
        isFallback: json['isFallback'] as bool? ?? false,
        imgrad: json['imgrad'] != null
            ? ImgradModel.fromJson(json['imgrad'] as Map<String, dynamic>)
            : null,
        doi: json['doi'] as String?,
        issn: json['issn'] as String?,
        isbn: json['isbn'] as String?,
        arxivId: json['arxivId'] as String?,
        journal: json['journal'] as String?,
        publisher: json['publisher'] as String?,
        volume: json['volume'] as String?,
        issue: json['issue'] as String?,
        pages: json['pages'] as String?,
        references: (json['references'] as List<dynamic>?)
                ?.map((e) => PaperReferenceModel.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        citationCount: json['citationCount'] as int?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'sourceUrl': sourceUrl,
        'sourceId': sourceId,
        'title': title,
        'authors': authors,
        'abstractText': abstractText,
        'publicationDate': publicationDate,
        'sections': sections.map((e) => e.toJson()).toList(),
        'keywords': keywords.map((e) => e.toJson()).toList(),
        'executiveSummary': executiveSummary,
        'contributions': contributions,
        'suggestedQuestions': suggestedQuestions,
        'rawTeiXml': rawTeiXml,
        'isFallback': isFallback,
        if (imgrad != null) 'imgrad': imgrad!.toJson(),
        if (doi != null) 'doi': doi,
        if (issn != null) 'issn': issn,
        if (isbn != null) 'isbn': isbn,
        if (arxivId != null) 'arxivId': arxivId,
        if (journal != null) 'journal': journal,
        if (publisher != null) 'publisher': publisher,
        if (volume != null) 'volume': volume,
        if (issue != null) 'issue': issue,
        if (pages != null) 'pages': pages,
        'references': references.map((e) => e.toJson()).toList(),
        if (citationCount != null) 'citationCount': citationCount,
      };

  /// Sends only the context required for chat. TEI XML and vectors are local data.
  Map<String, dynamic> toChatJson() => {
        'id': id,
        'title': title,
        'authors': authors,
        'abstractText': abstractText,
        'sections': sections
            .map((section) => {
                  'title': section.title,
                  'content': section.content,
                  'sectionNumber': section.sectionNumber,
                })
            .toList(),
        'executiveSummary': executiveSummary,
        'contributions': contributions,
        'keywords': keywords.map((keyword) => keyword.toJson()).toList(),
        if (imgrad != null) 'imgrad': imgrad!.toJson(),
        if (doi != null) 'doi': doi,
        if (journal != null) 'journal': journal,
      };

  ImgradModel get effectiveImgrad {
    if (imgrad != null) return imgrad!;

    final introSections = <PaperSection>[];
    final methodSections = <PaperSection>[];
    final resultSections = <PaperSection>[];
    final discussSections = <PaperSection>[];
    final otherSections = <PaperSection>[];

    final introReg = RegExp(
        r'(intro|background|problem|motivation|bối cảnh|đặt vấn đề)',
        caseSensitive: false);
    final methodReg = RegExp(
        r'(method|model|approach|framework|architecture|algorithm|dataset|setup|material|phương pháp|mô hình)',
        caseSensitive: false);
    final resultReg = RegExp(
        r'(result|experiment|evaluation|finding|benchmark|empirical|kết quả|thực nghiệm)',
        caseSensitive: false);
    final discussReg = RegExp(
        r'(discuss|limit|future|conclu|thảo luận|hạn chế|kết luận)',
        caseSensitive: false);

    for (final s in sections) {
      final t = s.title.toLowerCase();
      if (introReg.hasMatch(t)) {
        introSections.add(s);
      } else if (methodReg.hasMatch(t)) {
        methodSections.add(s);
      } else if (resultReg.hasMatch(t)) {
        resultSections.add(s);
      } else if (discussReg.hasMatch(t)) {
        discussSections.add(s);
      } else {
        otherSections.add(s);
      }
    }

    return ImgradModel(
      introduction: ImgradPillar(
        code: 'I',
        name: 'Introduction',
        vietnameseTitle: 'Đặt Vấn Đề & Mục Tiêu',
        summary: abstractText.isNotEmpty
            ? abstractText
            : (introSections.isNotEmpty
                ? introSections.first.content
                : executiveSummary),
        keyPoints:
            contributions.isNotEmpty ? contributions.take(2).toList() : [],
        sectionsMapped: introSections.map((e) => e.displayName).toList(),
        rawContent: introSections
            .map((e) => '${e.displayName}\n${e.content}')
            .join('\n\n'),
      ),
      methodology: ImgradPillar(
        code: 'M',
        name: 'Methodology',
        vietnameseTitle: 'Phương Pháp & Thiết Kế Nghiên Cứu',
        summary: methodSections.isNotEmpty
            ? methodSections.map((e) => e.content).take(2).join('\n\n')
            : 'Chưa xác định được mục phương pháp từ tài liệu.',
        keyPoints: keywords
            .where((k) =>
                k.category.toLowerCase().contains('method') ||
                k.category.toLowerCase().contains('model'))
            .map((e) => e.term)
            .toList(),
        sectionsMapped: methodSections.map((e) => e.displayName).toList(),
        rawContent: methodSections
            .map((e) => '${e.displayName}\n${e.content}')
            .join('\n\n'),
      ),
      results: ImgradPillar(
        code: 'R',
        name: 'Results',
        vietnameseTitle: 'Kết Quả & Số Liệu Thực Nghiệm',
        summary: resultSections.isNotEmpty
            ? resultSections.map((e) => e.content).take(2).join('\n\n')
            : 'Chưa xác định được mục kết quả từ tài liệu.',
        keyPoints: contributions.length > 2 ? [contributions[2]] : [],
        sectionsMapped: resultSections.map((e) => e.displayName).toList(),
        rawContent: resultSections
            .map((e) => '${e.displayName}\n${e.content}')
            .join('\n\n'),
      ),
      discussion: ImgradPillar(
        code: 'D',
        name: 'Discussion',
        vietnameseTitle: 'Thảo Luận, Hạn Chế & Kết Luận',
        summary: discussSections.isNotEmpty
            ? discussSections.map((e) => e.content).take(2).join('\n\n')
            : 'Chưa xác định được mục thảo luận từ tài liệu.',
        keyPoints: [],
        sectionsMapped: discussSections.map((e) => e.displayName).toList(),
        rawContent: discussSections
            .map((e) => '${e.displayName}\n${e.content}')
            .join('\n\n'),
      ),
    );
  }

  String get fullStructuredText {
    final buffer = StringBuffer();
    buffer.writeln('# $title\n');
    if (authors.isNotEmpty) {
      buffer.writeln('**Authors**: ${authors.join(', ')}\n');
    }
    if (abstractText.isNotEmpty) {
      buffer.writeln('## Abstract\n$abstractText\n');
    }
    for (final section in sections) {
      buffer.writeln('## ${section.displayName}\n');
      buffer.writeln('${section.content}\n');
    }
    return buffer.toString();
  }
}
