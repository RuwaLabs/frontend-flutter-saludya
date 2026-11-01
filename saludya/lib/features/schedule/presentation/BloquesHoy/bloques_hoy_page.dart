import 'package:flutter/material.dart';

import '../../domain/model/speciality.dart';
import '../Calendario/calendario_view_model.dart';
import '../DetalleBloque/detalle_bloque_page.dart';
import '../shared/staff_widgets.dart';

class BloquesHoyPage extends StatelessWidget {
  const BloquesHoyPage({
    super.key,
    required this.speciality,
    required this.date,
    required this.viewModel,
  });
  final Speciality speciality;
  final DateTime date;
  final CalendarioViewModel viewModel;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: viewModel,
    builder: (context, _) {
      final slots = viewModel.slotsFor(speciality, date);
      return StaffScaffold(
        title: 'Bloques del día',
        children: [
          Text(
            '${shortDate(date)} · ${speciality.name}',
            style: const TextStyle(
              color: StaffColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (slots.isEmpty) const Text('No hay bloques para esta fecha.'),
          for (final slot in slots)
            InfoCard(
              title: '${shortTime(slot.startHour)}–${shortTime(slot.endHour)}',
              lines: [
                for (final doctor in viewModel.doctors.where(
                  (d) => d.id == slot.doctorId,
                ))
                  '${doctor.name} ${doctor.lastname} · ${slot.room}',
                '${slot.currentBookings} reservas · Capacidad: ${slot.maxCapacity}',
              ],
              action: '${slot.status} →',
              onTap: () {
                final doctor = viewModel.doctors.firstWhere(
                  (d) => d.id == slot.doctorId,
                );
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DetalleBloquePage(
                      slot: slot,
                      doctor: doctor,
                      speciality: speciality,
                      viewModel: viewModel,
                    ),
                  ),
                );
              },
            ),
        ],
      );
    },
  );
}
