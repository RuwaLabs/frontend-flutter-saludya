import 'package:flutter/material.dart';

import '../shared/staff_widgets.dart';

const _months = [
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

class MonthCalendar extends StatelessWidget {
  const MonthCalendar({
    super.key,
    required this.month,
    required this.selectedDay,
    required this.availableDays,
    required this.onDaySelected,
    required this.onPrevMonth,
    required this.onNextMonth,
  });

  final DateTime month;
  final int selectedDay;
  final Set<int> availableDays;
  final ValueChanged<int> onDaySelected;
  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;

  @override
  Widget build(BuildContext context) {
    final offset = DateTime(month.year, month.month).weekday - 1;
    final length = DateTime(month.year, month.month + 1, 0).day;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                tooltip: 'Mes anterior',
                onPressed: onPrevMonth,
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Text(
                  '${_months[month.month - 1]} ${month.year}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: StaffColors.text,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Mes siguiente',
                onPressed: onNextMonth,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          Row(
            children: [
              for (final label in ['L', 'M', 'M', 'J', 'V', 'S', 'D'])
                Expanded(child: Center(child: Text(label))),
            ],
          ),
          const SizedBox(height: 10),
          for (int week = 0; week < (offset + length + 6) ~/ 7; week++)
            Row(
              children: [
                for (int col = 0; col < 7; col++)
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        final day = week * 7 + col - offset + 1;
                        if (day < 1 || day > length) {
                          return const SizedBox(height: 44);
                        }
                        final selected = day == selectedDay;
                        return Semantics(
                          selected: selected,
                          label: '$day de ${_months[month.month - 1]}',
                          child: InkWell(
                            onTap: () => onDaySelected(day),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              height: 44,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: selected ? StaffColors.primary : null,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$day',
                                style: TextStyle(
                                  color: selected
                                      ? Colors.white
                                      : availableDays.contains(day)
                                      ? StaffColors.primary
                                      : StaffColors.muted,
                                  fontWeight:
                                      availableDays.contains(day) || selected
                                      ? FontWeight.w600
                                      : null,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          const SizedBox(height: 8),
          const Text(
            '● Disponible',
            style: TextStyle(color: StaffColors.primary),
          ),
        ],
      ),
    );
  }
}
