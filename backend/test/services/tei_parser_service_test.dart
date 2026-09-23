import 'package:backend/services/tei_parser_service.dart';
import 'package:test/test.dart';

void main() {
  test('TEI parser extracts namespaced GROBID bibliography entries', () {
    const xml = '''
<TEI xmlns="http://www.tei-c.org/ns/1.0"><teiHeader><fileDesc>
<titleStmt><title type="main">Sample paper</title></titleStmt>
</fileDesc></teiHeader><text><body><div><head>Introduction</head><p>Text.</p></div></body>
<back><div><listBibl><biblStruct xml:id="b0"><analytic>
<title level="a">Cited study</title><author><persName><forename>Lan</forename><surname>Nguyen</surname></persName></author>
</analytic><monogr><title level="j">Journal</title><imprint><date when="2025"/></imprint></monogr>
<idno type="DOI">10.1000/example</idno></biblStruct></listBibl></div></back></text></TEI>
''';
    final paper = TeiParserService.parse(
      teiXmlString: xml,
      sourceId: 'sample',
      sourceUrl: 'local://sample.pdf',
    );
    expect(paper.references, hasLength(1));
    expect(paper.references.single.title, 'Cited study');
  });

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
