class AppConstants {
  // GROBID API Configuration
  static const String defaultGrobidUrl = 'http://localhost:8070';
  static const String grobidIsAliveEndpoint = '/api/isalive';
  static const String grobidFulltextEndpoint = '/api/processFulltextDocument';

  // Gemini AI Configuration
  static const String defaultGeminiModel = 'gemini-3.5-flash';
  static const String advancedGeminiModel = 'gemini-3.1-pro-preview';

  // Local Storage Keys
  static const String keyGeminiApiKey = 'gemini_api_key';
  static const String keyGrobidBaseUrl = 'grobid_base_url';
  static const String keySelectedModel = 'selected_gemini_model';

  // Sample ArXiv URLs for quick testing
  static const List<String> sampleArxivLinks = [
    'https://arxiv.org/abs/1706.03762', // Attention Is All You Need
    'https://arxiv.org/abs/2005.14165', // Language Models are Few-Shot Learners (GPT-3)
    'https://arxiv.org/abs/2312.00752', // Mamba: Linear-Time Sequence Modeling
  ];

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
  // Fallback Gemini Multimodal Prompt (When GROBID is offline)
  static const String fallbackDirectPdfPrompt = '''
You are an expert scientific document analyzer and peer reviewer.
Analyze the attached scientific research paper PDF and extract structured metadata, sections, and insights according to the IMGRaD scientific structure.

Output ONLY valid JSON adhering strictly to this schema:
{
  "title": "Cleaned full title of the paper",
  "authors": ["Author Name 1", "Author Name 2"],
  "abstract": "The full abstract text",
  "publicationDate": "Year or YYYY-MM-DD (e.g. 2024)",
  "sections": [
    {
      "sectionNumber": "1",
      "title": "Introduction",
      "content": "Detailed overview of the problem, motivation, and scope"
    },
    {
      "sectionNumber": "2",
      "title": "Related Work",
      "content": "Summary of prior art and baselines"
    },
    {
      "sectionNumber": "3",
      "title": "Methodology",
      "content": "Detailed explanation of the proposed model, architecture, equations, and algorithmic workflow"
    },
    {
      "sectionNumber": "4",
      "title": "Experiments & Results",
      "content": "Empirical setup, benchmark datasets, evaluation metrics, and comparative findings"
    },
    {
      "sectionNumber": "5",
      "title": "Conclusion",
      "content": "Summary of main findings, limitations, and future directions"
    }
  ],
  "summary": "Concise synthesis covering research problem, methodology, and empirical results",
  "imgrad": {
    "introduction": {
      "code": "I",
      "name": "Introduction",
      "vietnameseTitle": "Đặt Vấn Đề & Mục Tiêu Nghiên Cứu",
      "summary": "Bối cảnh nghiên cứu, câu hỏi nghiên cứu đặt ra và mục tiêu cốt lõi",
      "keyPoints": ["Mục tiêu / Đóng góp chính", "Đặt vấn đề"],
      "sectionsMapped": ["Introduction"]
    },
    "methodology": {
      "code": "M",
      "name": "Methodology",
      "vietnameseTitle": "Phương Pháp & Thiết Kế Nghiên Cứu",
      "summary": "Mô hình, thuật toán, công thức toán học và tập dữ liệu",
      "keyPoints": ["Kiến trúc chính", "Dữ liệu huấn luyện"],
      "sectionsMapped": ["Methodology"]
    },
    "results": {
      "code": "R",
      "name": "Results",
      "vietnameseTitle": "Kết Quả & Phát Hiện Thực Nghiệm",
      "summary": "Số liệu định lượng, kết quả benchmark và bảng so sánh",
      "keyPoints": ["Kết quả thực nghiệm nổi bật"],
      "sectionsMapped": ["Experiments & Results"]
    },
    "discussion": {
      "code": "D",
      "name": "Discussion",
      "vietnameseTitle": "Thảo Luận, Hạn Chế & Kết Luận",
      "summary": "Ý nghĩa lý thuyết & thực tiễn, các hạn chế của nghiên cứu",
      "keyPoints": ["Hạn chế và hướng phát triển tương lai"],
      "sectionsMapped": ["Conclusion"]
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

  static const String webArticleSystemPrompt = '''
You are an expert article analyst and journalist.
You will receive raw content from an online news story, web article, or press publication (e.g. VnExpress, Tuổi Trẻ, BBC, Medium).

Analyze the article thoroughly and output ONLY valid JSON adhering strictly to this schema:
{
  "title": "Clean, accurate headline/title of the article in its original language",
  "authors": ["Journalist/Author name or News Outlet name, e.g. VnExpress, Tuổi Trẻ"],
  "abstract": "The lead paragraph (sapo) or core premise of the article",
  "publicationDate": "Date or time of publication if present in article, e.g. 18/09/2026",
  "sections": [
    {
      "sectionNumber": "1",
      "title": "Descriptive subtitle or theme of section 1",
      "content": "Full textual content and details of this section"
    },
    {
      "sectionNumber": "2",
      "title": "Descriptive subtitle or theme of section 2",
      "content": "Full textual content and details of this section"
    }
  ],
  "summary": "Comprehensive 2-3 paragraph synthesis covering key events, context, causes, impacts, and developments",
  "contributions": [
    "Core fact, event, or key takeaway 1",
    "Core fact, event, or key takeaway 2",
    "Core fact, event, or key takeaway 3"
  ],
  "keywords": [
    {
      "term": "Key entity, person, location, or concept",
      "category": "Địa danh | Sự kiện | Nhân vật | Tổ chức | Khái niệm | Vấn đề",
      "context": "Brief context on how it appears in this article"
    }
  ],
  "suggested_questions": [
    "Nội dung bài báo là gì?",
    "Từ khóa chính của bài báo là gì?",
    "Specific question about the key event, cause, or consequence in the article?",
    "Specific question about actions taken or future developments?"
  ]
}
''';
}
