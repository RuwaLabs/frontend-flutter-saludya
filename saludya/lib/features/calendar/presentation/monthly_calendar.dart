import 'package:flutter/material.dart';
import 'package:saludya/core/design/saludya_palette.dart';
import 'package:saludya/features/operations/domain/operations_models.dart';

class MonthlyCalendar extends StatelessWidget {
  final DateTime month;
  final DateTime selectedDate;
  final List<TimeBlock> blocks;
  final ValueChanged<DateTime> onSelectDate;
  final ValueChanged<int> onChangeMonth;

  const MonthlyCalendar({
    super.key,
    required this.month,
    required this.selectedDate,
    required this.blocks,
    required this.onSelectDate,
    required this.onChangeMonth,
  });

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leadingEmpty = firstDay.weekday - 1;
    final cells = <Widget>[];
    for (var i = 0; i < leadingEmpty; i++) {
      cells.add(const SizedBox.shrink());
    }
    for (var day = 1; day <= daysInMonth; day++) {
      final date = DateTime(month.year, month.month, day);
      final dayBlocks = blocks
          .where((block) => _sameDay(block.date, date))
          .toList();
      final selected = _sameDay(selectedDate, date);
      final hasOpenBlocks = dayBlocks.any(
        (block) => block.status != 'CANCELLED',
      );
      cells.add(
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => onSelectDate(date),
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: selected ? SaludYaPalette.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$day',
                  style: TextStyle(
                    color: selected ? Colors.white : SaludYaPalette.text,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: dayBlocks.isEmpty
                        ? Colors.transparent
                        : selected
                        ? Colors.white
                        : hasOpenBlocks
                        ? SaludYaPalette.primary
                        : SaludYaPalette.absent,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SaludYaCard(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Mes anterior',
                onPressed: () => onChangeMonth(-1),
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Text(
                  _monthLabel(month),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: SaludYaPalette.text,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Mes siguiente',
                onPressed: () => onChangeMonth(1),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          const Row(
            children: [
              _Weekday('L'),
              _Weekday('M'),
              _Weekday('M'),
              _Weekday('J'),
              _Weekday('V'),
              _Weekday('S'),
              _Weekday('D'),
            ],
          ),
          const SizedBox(height: 4),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 1,
            crossAxisSpacing: 1,
            childAspectRatio: 1,
            children: cells,
          ),
        ],
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _monthLabel(DateTime date) {
    const months = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}

class _Weekday extends StatelessWidget {
  final String label;
  const _Weekday(this.label);

  @override
  Widget build(BuildContext context) => Expanded(
    child: Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(
          label,
          style: const TextStyle(
            color: SaludYaPalette.secondaryText,
            fontSize: 12,
          ),
        ),
      ),
    ),
  );
}
