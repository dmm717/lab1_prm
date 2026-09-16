import 'keyword_model.dart';

class PaperSection {
  final String title;
  final String content;
  final String? sectionNumber;

  PaperSection({
    required this.title,
    required this.content,
    this.sectionNumber,
  });

  String get displayName =>
      sectionNumber != null && sectionNumber!.isNotEmpty
          ? '$sectionNumber $title'
          : title;

  factory PaperSection.fromJson(Map<String, dynamic> json) => PaperSection(
        title: json['title'] as String? ?? '',
        content: json['content'] as String? ?? '',
        sectionNumber: json['sectionNumber'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'content': content,
        'sectionNumber': sectionNumber,
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
  });

  factory PaperModel.fromJson(Map<String, dynamic> json) => PaperModel(
        id: json['id'] as String? ?? '',
        sourceUrl: json['sourceUrl'] as String? ?? '',
        sourceId: json['sourceId'] as String? ?? '',
        title: json['title'] as String? ?? '',
        authors: (json['authors'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
        abstractText: json['abstractText'] as String? ?? '',
        publicationDate: json['publicationDate'] as String?,
        sections: (json['sections'] as List<dynamic>?)?.map((e) => PaperSection.fromJson(e as Map<String, dynamic>)).toList() ?? [],
        keywords: (json['keywords'] as List<dynamic>?)?.map((e) => KeywordModel.fromJson(e as Map<String, dynamic>)).toList() ?? [],
        executiveSummary: json['executiveSummary'] as String? ?? '',
        contributions: (json['contributions'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
        suggestedQuestions: (json['suggestedQuestions'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
        rawTeiXml: json['rawTeiXml'] as String? ?? '',
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
      };

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
