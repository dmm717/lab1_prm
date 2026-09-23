import 'package:flutter_test/flutter_test.dart';
import 'package:paper_chat_ai/models/paper_model.dart';

void main() {
  test('restores references from saved TEI when old JSON has none', () {
    const tei = '''
<TEI xmlns="http://www.tei-c.org/ns/1.0"><text><back><div><listBibl>
<biblStruct xml:id="b0"><analytic><title>Cited paper</title>
<author><persName><forename>Lan</forename><surname>Nguyen</surname></persName></author>
</analytic><monogr><title>Journal</title><imprint><date when="2025"/></imprint></monogr>
</biblStruct></listBibl></div></back></text></TEI>
''';
    final paper = PaperModel.fromJson({
      'id': 'paper-1',
      'title': 'Sample paper',
      'rawTeiXml': tei,
      'references': <Object>[],
    });

    expect(paper.references, hasLength(1));
    expect(paper.references.single.title, 'Cited paper');
    expect(paper.references.single.authors, ['Lan Nguyen']);
  });

  test('persists the original local PDF path for reopening', () {
    final paper = PaperModel(
      id: 'paper-1',
      sourceUrl: 'local://sample.pdf',
      sourceId: 'sample',
      title: 'Sample paper',
      abstractText: '',
      localPdfPath: r'C:\papers\sample.pdf',
    );

    expect(PaperModel.fromJson(paper.toJson()).localPdfPath,
        r'C:\papers\sample.pdf');
  });
}
