import 'package:flutter/material.dart';

import '../../domain/model/speciality.dart';
import '../Calendario/calendario_view_model.dart';
import '../ElegirHora/elegir_hora_page.dart';
import '../shared/staff_widgets.dart';
import 'doctor_card.dart';

class ElegirDoctorPage extends StatefulWidget {
  const ElegirDoctorPage({
    super.key,
    required this.speciality,
    required this.viewModel,
  });
  final Speciality speciality;
  final CalendarioViewModel viewModel;
  @override
  State<ElegirDoctorPage> createState() => _ElegirDoctorPageState();
}

class _ElegirDoctorPageState extends State<ElegirDoctorPage> {
  String query = '';
  @override
  Widget build(BuildContext context) {
    final doctors = widget.viewModel
        .doctorsFor(widget.speciality)
        .where(
          (d) => '${d.name} ${d.lastname}'.toLowerCase().contains(
            query.toLowerCase(),
          ),
        );
    return StaffScaffold(
      title: 'Elige al profesional',
      children: [
        SearchField(
          label: 'Buscar profesional',
          hint: 'Nombre del profesional…',
          onChanged: (text) => setState(() => query = text),
        ),
        if (doctors.isEmpty) const Text('No se encontraron profesionales.'),
        for (final doctor in doctors)
          DoctorCard(
            doctor: doctor,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ElegirHoraPage(
                  speciality: widget.speciality,
                  doctor: doctor,
                  date: widget.viewModel.selectedDate,
                  viewModel: widget.viewModel,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
