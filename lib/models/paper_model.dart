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
}

class PaperModel {
  final String id;
  final String arxivUrl;
  final String arxivId;
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
    required this.arxivUrl,
    required this.arxivId,
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

  /// Constructs a comprehensive full-text markdown representation
  /// suitable for injecting directly into Gemini's large context window.
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
