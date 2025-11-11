import 'package:flutter/material.dart';
import 'package:org_flutter/src/indent.dart';
import 'package:org_flutter/src/util/util.dart';
import 'package:org_flutter/src/widget/org_content.dart';
import 'package:org_flutter/src/widget/org_theme.dart';
import 'package:org_parser/org_parser.dart';

/// An Org Mode table
class OrgTableWidget extends StatelessWidget {
  const OrgTableWidget(this.table, {super.key});
  final OrgTable table;

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle.merge(
      style: TextStyle(color: OrgTheme.dataOf(context).tableColor),
      child: ConstrainedBox(
        // Ensure that table takes up entire width (can't have tables
        // side-by-side)
        constraints: const BoxConstraints.tightFor(width: double.infinity),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const AlwaysScrollableScrollPhysics(),
              child: IndentBuilder(
                table.indent,
                expanded: false,
                builder: (context, _) => _buildTable(context),
              ),
            ),
            if (table.trailing.isNotEmpty)
              Text(removeTrailingLineBreak(table.trailing)),
          ],
        ),
      ),
    );
  }

  Widget _buildTable(BuildContext context) {
    final tableColor = OrgTheme.dataOf(context).tableColor;
    final borderSide =
        tableColor == null ? const BorderSide() : BorderSide(color: tableColor);
    return Table(
      defaultColumnWidth: const IntrinsicColumnWidth(),
      defaultVerticalAlignment: TableCellVerticalAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      border: TableBorder(
        verticalInside: borderSide,
        left: borderSide,
        right: table.rectangular ? borderSide : BorderSide.none,
      ),
      children: _tableRows(borderSide).toList(growable: false),
    );
  }

  Iterable<TableRow> _tableRows(BorderSide borderSide) sync* {
    final columnCount = table.columnCount;
    final numerical = List<bool>.generate(columnCount, table.columnIsNumeric);
    for (var i = 0; i < table.rows.length; i++) {
      final prevRow = i > 0 ? table.rows[i - 1] : null;
      final row = table.rows[i];
      final nextRow = i + 1 < table.rows.length ? table.rows[i + 1] : null;
      if (row is OrgTableCellRow) {
        // Peek at surrounding rows, add borders for dividers
        final topBorder =
            i == 1 && prevRow is OrgTableDividerRow ? borderSide : null;
        final bottomBorder = nextRow is OrgTableDividerRow ? borderSide : null;
        final decoration = topBorder != null || bottomBorder != null
            ? BoxDecoration(
                border: Border(
                top: topBorder ?? BorderSide.none,
                bottom: bottomBorder ?? BorderSide.none,
              ))
            : null;
        yield TableRow(
          decoration: decoration,
          children: [
            for (var j = 0; j < columnCount; j++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: j < row.cellCount
                    ? OrgContentWidget(
                        row.cells[j].content,
                        textAlign: numerical[j] ? TextAlign.right : null,
                      )
                    : const SizedBox.shrink(),
              ),
          ],
        );
      } else if (prevRow is OrgTableDividerRow && row is OrgTableDividerRow) {
        yield TableRow(
          decoration: BoxDecoration(border: Border(bottom: borderSide)),
          children: List.filled(columnCount, const SizedBox(height: 8)),
        );
      }
      // TODO(aaron): Handle edge cases like
      // - solitary divider row
      // - trailing content after row
    }
  }
}
