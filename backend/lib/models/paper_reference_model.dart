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
