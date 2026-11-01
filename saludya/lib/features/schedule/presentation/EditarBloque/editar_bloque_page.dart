import 'package:flutter/material.dart';

import '../../domain/model/time_slot.dart';
import '../Calendario/calendario_view_model.dart';
import '../shared/staff_widgets.dart';

class EditarBloquePage extends StatefulWidget {
  const EditarBloquePage({
    super.key,
    required this.slot,
    required this.viewModel,
  });
  final TimeSlot slot;
  final CalendarioViewModel viewModel;
  @override
  State<EditarBloquePage> createState() => _EditarBloquePageState();
}

class _EditarBloquePageState extends State<EditarBloquePage> {
  late String status = widget.slot.status;
  bool saving = false;
  String? error;

  Future<void> save() async {
    setState(() {
      saving = true;
      error = null;
    });
    try {
      final original = widget.slot;
      await widget.viewModel.saveSlot(
        TimeSlot(
          id: original.id,
          doctorId: original.doctorId,
          date: original.date,
          startHour: original.startHour,
          endHour: original.endHour,
          room: original.room,
          maxCapacity: original.maxCapacity,
          currentBookings: original.currentBookings,
          status: status,
        ),
      );
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(
          () => error = 'No se pudieron guardar los cambios. Intenta de nuevo.',
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => StaffScaffold(
    title: 'Editar bloque',
    children: [
      InfoCard(
        title:
            '${shortDate(widget.slot.date)} · ${shortTime(widget.slot.startHour)}',
        lines: [
          'Reservas: ${widget.slot.currentBookings} de ${widget.slot.maxCapacity}',
        ],
      ),
      InfoCard(title: 'Consultorio', lines: [widget.slot.room]),
      DropdownButtonFormField<String>(
        initialValue: status,
        decoration: const InputDecoration(
          labelText: 'Estado',
          border: OutlineInputBorder(),
          filled: true,
          fillColor: Colors.white,
        ),
        items:
            {
                  widget.slot.status,
                  'CANCELLED',
                  if (widget.slot.currentBookings < widget.slot.maxCapacity)
                    'AVAILABLE',
                }
                .map(
                  (value) => DropdownMenuItem(value: value, child: Text(value)),
                )
                .toList(),
        onChanged: (value) {
          if (value != null) setState(() => status = value);
        },
      ),
      if (error != null)
        Text(error!, style: const TextStyle(color: Colors.red)),
      PrimaryButton(
        label: saving ? 'Guardando…' : 'Confirmar cambios',
        onPressed: saving ? null : save,
      ),
      OutlinedButton(
        onPressed: saving ? null : () => Navigator.pop(context),
        child: const Text('Cancelar'),
      ),
    ],
  );
}
