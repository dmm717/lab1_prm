
class KeywordModel {
  final String term;
  final String category;
  final String context;

  KeywordModel({
    required this.term,
    required this.category,
    required this.context,
  });

  factory KeywordModel.fromJson(Map<String, dynamic> json) {
    return KeywordModel(
      term: json['term']?.toString() ?? 'Unknown',
      category: json['category']?.toString() ?? 'Uncategorized',
      context: json['context']?.toString() ?? '',
    );
  }
  
  Map<String, dynamic> toJson() => {
      'term': term,
      'category': category,
      'context': context,
  };
}
