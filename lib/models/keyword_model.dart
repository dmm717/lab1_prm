class KeywordModel {
  final String term;
  final String category; // e.g. Methodology, Architecture, Benchmark, Theory
  final String context; // Explanation of how this keyword is used in the paper

  KeywordModel({
    required this.term,
    required this.category,
    required this.context,
  });

  factory KeywordModel.fromJson(Map<String, dynamic> json) {
    return KeywordModel(
      term: json['term']?.toString() ?? '',
      category: json['category']?.toString() ?? 'General',
      context: json['context']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'term': term,
        'category': category,
        'context': context,
      };
}
