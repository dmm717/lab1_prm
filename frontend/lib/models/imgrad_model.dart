class ImgradPillar {
  final String code; // 'I', 'M', 'R', 'D'
  final String name; // 'Introduction', 'Methodology', 'Results', 'Discussion'
  final String vietnameseTitle; // 'Đặt Vấn Đề & Mục Tiêu'
  final String summary; // 1-2 paragraph synthesis
  final List<String> keyPoints; // Bulleted findings
  final List<String> sectionsMapped; // Names of paper sections belonging to this pillar
  final String rawContent; // Full aggregated text for this pillar

  const ImgradPillar({
    required this.code,
    required this.name,
    required this.vietnameseTitle,
    required this.summary,
    this.keyPoints = const [],
    this.sectionsMapped = const [],
    this.rawContent = '',
  });

  factory ImgradPillar.fromJson(Map<String, dynamic> json) => ImgradPillar(
        code: json['code'] as String? ?? '',
        name: json['name'] as String? ?? '',
        vietnameseTitle: json['vietnameseTitle'] as String? ?? '',
        summary: json['summary'] as String? ?? '',
        keyPoints: (json['keyPoints'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        sectionsMapped: (json['sectionsMapped'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [],
        rawContent: json['rawContent'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'code': code,
        'name': name,
        'vietnameseTitle': vietnameseTitle,
        'summary': summary,
        'keyPoints': keyPoints,
        'sectionsMapped': sectionsMapped,
        'rawContent': rawContent,
      };
}

class ImgradModel {
  final ImgradPillar introduction;
  final ImgradPillar methodology;
  final ImgradPillar results;
  final ImgradPillar discussion;

  const ImgradModel({
    required this.introduction,
    required this.methodology,
    required this.results,
    required this.discussion,
  });

  factory ImgradModel.fromJson(Map<String, dynamic> json) => ImgradModel(
        introduction: ImgradPillar.fromJson(
            json['introduction'] as Map<String, dynamic>? ?? {'code': 'I', 'name': 'Introduction', 'vietnameseTitle': 'Đặt Vấn Đề & Mục Tiêu'}),
        methodology: ImgradPillar.fromJson(
            json['methodology'] as Map<String, dynamic>? ?? {'code': 'M', 'name': 'Methodology', 'vietnameseTitle': 'Phương Pháp Luận'}),
        results: ImgradPillar.fromJson(
            json['results'] as Map<String, dynamic>? ?? {'code': 'R', 'name': 'Results', 'vietnameseTitle': 'Kết Quả & Số Liệu'}),
        discussion: ImgradPillar.fromJson(
            json['discussion'] as Map<String, dynamic>? ?? {'code': 'D', 'name': 'Discussion', 'vietnameseTitle': 'Thảo Luận & Hạn Chế'}),
      );

  Map<String, dynamic> toJson() => {
        'introduction': introduction.toJson(),
        'methodology': methodology.toJson(),
        'results': results.toJson(),
        'discussion': discussion.toJson(),
      };

  List<ImgradPillar> get pillars => [introduction, methodology, results, discussion];
}
