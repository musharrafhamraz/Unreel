import 'package:flutter_test/flutter_test.dart';
import 'package:scrollcount/data/services/csv_parser.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('bundled routine has seven tasks and all days are scheduled', () async {
    final tasks = await CsvParserService.parseCognitiveTasks();
    expect(tasks, hasLength(7));
    expect(tasks.map((task) => task.id).toSet(), hasLength(7));
    for (var day = 0; day < 7; day++) {
      expect(CsvParserService.getTasksForDate(tasks, DateTime(2026, 10, 26 + day)), hasLength(7));
    }
  });
}
