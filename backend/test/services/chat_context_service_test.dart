import 'package:backend/models/paper_model.dart';
import 'package:backend/services/chat_context_service.dart';
import 'package:test/test.dart';

void main() {
  test('selects a relevant late section without an embedding request', () {
    final sections = List.generate(
      7,
      (index) => PaperSection(
        title: index == 6 ? 'Limitations' : 'Section $index',
        content: index == 6
            ? 'The sample size limits generalization.'
            : 'Background material $index.',
      ),
    );
    final paper = PaperModel(
      id: 'paper',
      sourceUrl: '',
      sourceId: 'paper',
      title: 'Study',
      abstractText: 'A scientific study.',
      sections: sections,
    );

    final context = ChatContextService.build(
      paper: paper,
      query: 'What are the limitations?',
    );

    expect(context, contains('The sample size limits generalization.'));
    expect(context, contains('## Limitations'));
  });

  test('limits long section text sent to Gemini', () {
    final paper = PaperModel(
      id: 'paper',
      sourceUrl: '',
      sourceId: 'paper',
      title: 'Study',
      abstractText: '',
      sections: [
        PaperSection(title: 'Methods', content: 'a' * 30000),
      ],
    );

    final context = ChatContextService.build(
      paper: paper,
      query: 'methods',
    );

    expect(context.length, lessThan(5500));
    expect(context, contains('[Lược phần sau]'));
  });
}
