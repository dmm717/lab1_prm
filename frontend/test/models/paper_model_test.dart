import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:paper_chat_ai/models/paper_model.dart';
import 'package:paper_chat_ai/services/paper_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const tei = '''
<TEI xmlns="http://www.tei-c.org/ns/1.0"><text><back><div><listBibl>
<biblStruct xml:id="b0"><analytic><title>Cited paper</title>
<author><persName><forename>Lan</forename><surname>Nguyen</surname></persName></author>
</analytic><monogr><title>Journal</title><imprint><date when="2025"/></imprint></monogr>
</biblStruct></listBibl></div></back></text></TEI>
''';
  test('restores references from saved TEI when old JSON has none', () {
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

  test('persists recovered references in the recent paper library', () async {
    SharedPreferences.setMockInitialValues({
      'recent_paper_ids': ['paper-1'],
      'paper_data_paper-1': jsonEncode({
        'id': 'paper-1',
        'title': 'Sample paper',
        'rawTeiXml': tei,
        'references': <Object>[],
      }),
    });

    final papers = await PaperStorageService().getRecentPapers();
    final preferences = await SharedPreferences.getInstance();
    final stored = jsonDecode(preferences.getString('paper_data_paper-1')!)
        as Map<String, dynamic>;

    expect(papers.single.references, hasLength(1));
    expect(stored['references'], hasLength(1));
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
