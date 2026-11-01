import 'package:flutter/material.dart';

import '../../domain/model/doctor.dart';
import '../../domain/model/speciality.dart';
import '../../domain/model/time_slot.dart';
import '../Calendario/calendario_view_model.dart';
import '../DetalleBloque/detalle_bloque_page.dart';
import '../shared/staff_widgets.dart';

class ElegirHoraPage extends StatefulWidget {
  const ElegirHoraPage({
    super.key,
    required this.speciality,
    required this.doctor,
    required this.date,
    required this.viewModel,
  });
  final Speciality speciality;
  final Doctor doctor;
  final DateTime date;
  final CalendarioViewModel viewModel;
  @override
  State<ElegirHoraPage> createState() => _ElegirHoraPageState();
}

class _ElegirHoraPageState extends State<ElegirHoraPage> {
  TimeSlot? selected;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.viewModel,
    builder: (context, _) {
      final slots = widget.viewModel.slotsFor(
        widget.speciality,
        widget.date,
        doctor: widget.doctor,
      );
      return StaffScaffold(
        title: 'Elige la hora',
        children: [
          Text(
            '${widget.doctor.name} ${widget.doctor.lastname} · ${shortDate(widget.date)}',
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
                '${slot.room} · ${slot.currentBookings}/${slot.maxCapacity} reservas',
              ],
              action:
                  slot.status.toLowerCase() != 'available' ||
                      slot.currentBookings >= slot.maxCapacity
                  ? 'Sin cupos'
                  : selected?.id == slot.id
                  ? 'Seleccionado ✓'
                  : 'Seleccionar →',
              onTap:
                  slot.status.toLowerCase() != 'available' ||
                      slot.currentBookings >= slot.maxCapacity
                  ? null
                  : () => setState(() => selected = slot),
            ),
          PrimaryButton(
            label: 'Seleccionar bloque',
            onPressed: selected == null
                ? null
                : () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DetalleBloquePage(
                        slot: selected!,
                        doctor: widget.doctor,
                        speciality: widget.speciality,
                        viewModel: widget.viewModel,
                      ),
                    ),
                  ),
          ),
        ],
      );
    },
  );
}
