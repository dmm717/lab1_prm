class AppConstants {
  // GROBID API Configuration
  static const String defaultGrobidUrl = 'http://localhost:8070';
  static const String grobidIsAliveEndpoint = '/api/isalive';
  static const String grobidFulltextEndpoint = '/api/processFulltextDocument';

  // Gemini AI Configuration
  static const String defaultGeminiModel = 'gemini-3.1-flash-lite';
  static const String advancedGeminiModel = 'gemini-3.1-pro-preview';

  // Local Storage Keys
  static const String keyGeminiApiKey = 'gemini_api_key';
  static const String keyGrobidBaseUrl = 'grobid_base_url';
  static const String keySelectedModel = 'selected_gemini_model';

  // Default Prompts
  static const String synthesisSystemPrompt = '''
You are an elite scientific researcher and AI peer reviewer.
You will receive structured academic paper content parsed from a local PDF.

Analyze the paper thoroughly and output ONLY valid JSON adhering strictly to this schema:
{
  "title": "Cleaned full paper title",
  "summary": "Concise synthesis covering research problem, methodology, and empirical results",
  "imgrad": {
    "introduction": {
      "code": "I",
      "name": "Introduction",
      "vietnameseTitle": "Đặt Vấn Đề & Mục Tiêu Nghiên Cứu",
      "summary": "Bối cảnh nghiên cứu, câu hỏi nghiên cứu đặt ra và mục tiêu cốt lõi",
      "keyPoints": ["Mục tiêu / Đóng góp 1", "Bối cảnh / Đặt vấn đề 2"],
      "sectionsMapped": ["Introduction", "Related Work"]
    },
    "methodology": {
      "code": "M",
      "name": "Methodology",
      "vietnameseTitle": "Phương Pháp & Thiết Kế Nghiên Cứu",
      "summary": "Chi tiết thiết kế nghiên cứu, kiến trúc mô hình, thuật toán, công thức toán học và tập dữ liệu",
      "keyPoints": ["Kiến trúc / Mô hình chính", "Tập dữ liệu / Quy trình huấn luyện"],
      "sectionsMapped": ["Methodology", "Model Architecture"]
    },
    "results": {
      "code": "R",
      "name": "Results",
      "vietnameseTitle": "Kết Quả & Phát Hiện Thực Nghiệm",
      "summary": "Các số liệu định lượng, kết quả benchmark, bảng biểu và so sánh với baseline",
      "keyPoints": ["Phát hiện chính 1", "Chỉ số định lượng 2"],
      "sectionsMapped": ["Experiments", "Results"]
    },
    "discussion": {
      "code": "D",
      "name": "Discussion",
      "vietnameseTitle": "Thảo Luận, Hạn Chế & Kết Luận",
      "summary": "Ý nghĩa lý thuyết & thực tiễn, các hạn chế của nghiên cứu và định hướng phát triển tương lai",
      "keyPoints": ["Ý nghĩa then chốt", "Hạn chế của nghiên cứu"],
      "sectionsMapped": ["Discussion", "Conclusion"]
    }
  },
  "contributions": [
    "Core contribution 1",
    "Core contribution 2",
    "Core contribution 3"
  ],
  "keywords": [
    {
      "term": "Exact keyword/concept",
      "category": "Architecture | Methodology | Benchmark | Theory | Application",
      "context": "Brief 1-sentence note on how it relates to this specific paper"
    }
  ],
  "suggested_questions": [
    "📘 [I] Mục tiêu và bối cảnh nghiên cứu của bài báo là gì?",
    "⚙️ [M] Phương pháp luận và kiến trúc kỹ thuật được đề xuất như thế nào?",
    "📊 [R] Những kết quả và số liệu thực nghiệm nổi bật nhất là gì?",
    "💡 [D] Các hạn chế của nghiên cứu và hướng đi tương lai được thảo luận ra sao?"
  ]
}
''';
}
