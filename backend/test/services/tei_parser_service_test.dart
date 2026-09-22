import 'package:backend/services/tei_parser_service.dart';
import 'package:test/test.dart';

void main() {
  test('TEI parser preserves metadata, sections and a content-based ID', () {
    const xml = '''
<TEI><teiHeader><fileDesc><titleStmt><title type="main">A Study of Scientific PDFs</title></titleStmt>
<sourceDesc><biblStruct><analytic><author><persName><forename>Lan</forename><surname>Nguyen</surname></persName></author></analytic></biblStruct></sourceDesc>
</fileDesc><profileDesc><abstract><p>We examine document extraction.</p></abstract><textClass><keywords><term>GROBID</term></keywords></textClass></profileDesc></teiHeader>
<text><body><div><head n="1">Introduction</head><p>Research question and context.</p></div>
<div><head n="2">Methods</head><p>We analyze local PDF files.</p></div></body></text></TEI>
''';
    final paper = TeiParserService.parse(
      teiXmlString: xml,
      sourceId: 'study',
      sourceUrl: 'local://study.pdf',
      paperId: 'study_content_hash',
    );
    expect(paper.id, 'study_content_hash');
    expect(paper.sourceId, 'study');
    expect(paper.title, 'A Study of Scientific PDFs');
    expect(paper.authors, ['Lan Nguyen']);
    expect(paper.abstractText, 'We examine document extraction.');
    expect(paper.sections.map((e) => e.content).toList(), [
      'Research question and context.',
      'We analyze local PDF files.',
    ]);
    expect(paper.keywords.first.term, 'GROBID');
  });
}
