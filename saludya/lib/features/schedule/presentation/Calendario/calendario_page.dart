import 'package:flutter/material.dart';

import '../../domain/model/speciality.dart';
import '../BloquesHoy/bloques_hoy_page.dart';
import '../ElegirDoctor/elegir_doctor_page.dart';
import '../shared/staff_widgets.dart';
import 'calendario_view_model.dart';
import 'month_calendar.dart';

export 'calendario_view_model.dart';

class CalendarioPage extends StatefulWidget {
  const CalendarioPage({
    super.key,
    required this.speciality,
    required this.viewModel,
  });
  final Speciality speciality;
  final CalendarioViewModel viewModel;
  @override
  State<CalendarioPage> createState() => _CalendarioPageState();
}

class _CalendarioPageState extends State<CalendarioPage> {
  @override
  void dispose() {
    widget.viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.viewModel,
    builder: (context, _) {
      final vm = widget.viewModel;
      final available = vm.slots
          .where(
            (s) =>
                vm
                    .doctorsFor(widget.speciality)
                    .any((d) => d.id == s.doctorId) &&
                s.date.year == vm.month.year &&
                s.date.month == vm.month.month &&
                s.status.toLowerCase() == 'available' &&
                s.currentBookings < s.maxCapacity,
          )
          .map((s) => s.date.day)
          .toSet();
      return StaffScaffold(
        title: 'Calendario',
        children: [
          Text(
            widget.speciality.name,
            style: const TextStyle(
              color: StaffColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (vm.isLoading) const Center(child: CircularProgressIndicator()),
          if (vm.errorMessage != null)
            ErrorState(message: vm.errorMessage!, onRetry: vm.load),
          if (!vm.isLoading && vm.errorMessage == null) ...[
            MonthCalendar(
              month: vm.month,
              selectedDay: vm.selectedDate.day,
              availableDays: available,
              onDaySelected: vm.selectDay,
              onPrevMonth: () => vm.changeMonth(-1),
              onNextMonth: () => vm.changeMonth(1),
            ),
            PrimaryButton(
              label: 'Ver bloques del día',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BloquesHoyPage(
                    speciality: widget.speciality,
                    date: vm.selectedDate,
                    viewModel: vm,
                  ),
                ),
              ),
            ),
            PrimaryButton(
              label: 'Elegir profesional',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ElegirDoctorPage(
                    speciality: widget.speciality,
                    viewModel: vm,
                  ),
                ),
              ),
            ),
          ],
        ],
      );
    },
  );
}
