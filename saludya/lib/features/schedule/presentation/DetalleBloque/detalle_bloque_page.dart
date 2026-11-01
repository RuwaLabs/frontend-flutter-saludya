import 'package:flutter/material.dart';

import '../../domain/model/doctor.dart';
import '../../domain/model/speciality.dart';
import '../../domain/model/time_slot.dart';
import '../Calendario/calendario_view_model.dart';
import '../EditarBloque/editar_bloque_page.dart';
import '../shared/staff_widgets.dart';

class DetalleBloquePage extends StatelessWidget {
  const DetalleBloquePage({
    super.key,
    required this.slot,
    required this.doctor,
    required this.speciality,
    required this.viewModel,
  });
  final TimeSlot slot;
  final Doctor doctor;
  final Speciality speciality;
  final CalendarioViewModel viewModel;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: viewModel,
    builder: (context, _) {
      final current = viewModel.slots.firstWhere(
        (s) => s.id == slot.id,
        orElse: () => slot,
      );
      return StaffScaffold(
        title: 'Detalle del bloque',
        children: [
          InfoCard(
            title:
                '${shortTime(current.startHour)}–${shortTime(current.endHour)}',
            lines: [
              shortDate(current.date),
              speciality.name,
              '${doctor.name} ${doctor.lastname} · ${current.room}',
              'Capacidad: ${current.maxCapacity} · Reservas: ${current.currentBookings}',
            ],
            action: current.status,
          ),
          if (viewModel.updateTimeSlot != null)
            PrimaryButton(
              label: 'Editar bloque',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      EditarBloquePage(slot: current, viewModel: viewModel),
                ),
              ),
            ),
        ],
      );
    },
  );
}
