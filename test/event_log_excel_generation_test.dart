import 'package:excel/excel.dart' as xls;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('excel workbook keeps rows after rename and encode', () {
    final workbook = xls.Excel.createExcel();
    final sheetName = workbook.getDefaultSheet() ?? 'Sheet1';

    workbook.rename(sheetName, 'Event Log');
    workbook.appendRow(
      'Event Log',
      <xls.CellValue>[
        xls.TextCellValue('Date'),
        xls.TextCellValue('Name'),
      ],
    );
    workbook.appendRow(
      'Event Log',
      <xls.CellValue>[
        xls.TextCellValue('08/07/2026'),
        xls.TextCellValue('Alice'),
      ],
    );

    final bytes = workbook.encode();

    expect(bytes, isNotNull);

    final decoded = xls.Excel.decodeBytes(bytes!);
    final rows = decoded.tables['Event Log']?.rows;

    expect(rows, isNotNull);
    expect(rows!.length, 2);
    expect(rows[0][0]?.value.toString(), contains('Date'));
    expect(rows[1][1]?.value.toString(), contains('Alice'));
  });
}