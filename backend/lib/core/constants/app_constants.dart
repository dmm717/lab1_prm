class AppConstants {
  // GROBID API Configuration
  static const String defaultGrobidUrl = 'http://localhost:8070';
  static const String grobidIsAliveEndpoint = '/api/isalive';
  static const String grobidFulltextEndpoint = '/api/processFulltextDocument';

  // Gemini AI Configuration
  static const String defaultGeminiModel = 'gemini-2.0-flash';
  static const String advancedGeminiModel = 'gemini-1.5-pro';

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
You are an elite scientific researcher and AI assistant.
You will receive structured academic paper content (parsed from PDF via GROBID).

Analyze the paper thoroughly and output ONLY valid JSON adhering strictly to this schema:
{
  "title": "Cleaned full paper title",
  "summary": "Concise 2-3 paragraph synthesis covering research problem, methodology, and empirical results",
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
    "Suggested question 1 addressing methodology details",
    "Suggested question 2 addressing benchmarks/results",
    "Suggested question 3 addressing limitations or future scope"
  ]
}
''';
}
