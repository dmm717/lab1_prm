import '../models/paper_model.dart';

/// Selects short, relevant excerpts without adding an API request before chat.
class ChatContextService {
  static const int _maxSections = 4;
  static const int _maxSectionChars = 5000;

  static String build({required PaperModel paper, required String query}) {
    final terms = _terms(query);
    final sections = _selectSections(paper.sections, terms, query);
    final buffer = StringBuffer()..writeln('# ${paper.title}');
    if (paper.authors.isNotEmpty) {
      buffer.writeln('Authors: ${paper.authors.join(', ')}');
    }
    if (paper.abstractText.isNotEmpty) {
      buffer.writeln('\n## Abstract\n${_limit(paper.abstractText, 2200)}');
    }
    if (paper.executiveSummary.isNotEmpty) {
      buffer.writeln(
        '\n## Executive Summary\n${_limit(paper.executiveSummary, 1600)}',
      );
    }
    for (final section in sections) {
      buffer.writeln('\n## ${section.displayName}');
      buffer.writeln(_excerpt(section.content, terms));
    }
    return buffer.toString();
  }

  static List<PaperSection> _selectSections(
    List<PaperSection> sections,
    Set<String> terms,
    String query,
  ) {
    if (sections.length <= _maxSections) return sections;

    final overview = RegExp(
      r'tóm tắt|toàn diện|tổng quan|overview|summari|whole paper|entire paper',
      caseSensitive: false,
    ).hasMatch(query);
    if (overview) return _spreadSections(sections);

    final scored =
        sections.asMap().entries.map((entry) {
          final title = entry.value.displayName.toLowerCase();
          final body = entry.value.content.toLowerCase();
          var score = 0;
          for (final term in terms) {
            if (title.contains(term)) score += 5;
            if (body.contains(term)) score += 1;
          }
          return (index: entry.key, section: entry.value, score: score);
        }).toList()..sort((a, b) {
          final byScore = b.score.compareTo(a.score);
          return byScore != 0 ? byScore : a.index.compareTo(b.index);
        });

    if (scored.first.score == 0) return _spreadSections(sections);
    return scored.take(_maxSections).map((item) => item.section).toList();
  }

  static List<PaperSection> _spreadSections(List<PaperSection> sections) {
    final last = sections.length - 1;
    return List.generate(
      _maxSections,
      (index) => sections[(index * last / (_maxSections - 1)).round()],
    );
  }

  static Set<String> _terms(String query) {
    const stopWords = {
      'của',
      'cho',
      'với',
      'trong',
      'những',
      'này',
      'như',
      'nào',
      'what',
      'which',
      'where',
      'from',
      'about',
      'that',
      'this',
      'the',
      'and',
      'paper',
      'article',
      'báo',
      'hãy',
      'theo',
      'thế',
    };
    return query
        .toLowerCase()
        .split(RegExp(r'''[\s,.;:!?()\[\]{}"“”‘’/\\|+\-]+'''))
        .where((word) => word.length >= 3 && !stopWords.contains(word))
        .toSet();
  }

  static String _excerpt(String content, Set<String> terms) {
    if (content.length <= _maxSectionChars) return content;
    final lower = content.toLowerCase();
    var matchIndex = -1;
    for (final term in terms) {
      final index = lower.indexOf(term);
      if (index >= 0 && (matchIndex < 0 || index < matchIndex)) {
        matchIndex = index;
      }
    }
    final start = matchIndex <= 1200 ? 0 : matchIndex - 1200;
    final end = start + _maxSectionChars < content.length
        ? start + _maxSectionChars
        : content.length;
    return '${start > 0 ? '[Lược phần đầu] ' : ''}'
        '${content.substring(start, end)}'
        '${end < content.length ? ' [Lược phần sau]' : ''}';
  }

  static String _limit(String value, int maxChars) =>
      value.length <= maxChars ? value : '${value.substring(0, maxChars)}…';
}
