import 'package:flutter/material.dart';

import '../../application/doctor/get_doctors_by_specialty_use_case.dart';
import '../../application/time_slot/get_time_slots_by_doctor_and_date_use_case.dart';
import '../../application/time_slot/update_time_slot_use_case.dart';
import '../Calendario/calendario_page.dart';
import '../shared/staff_widgets.dart';
import 'buscador_widget.dart';
import 'elegir_especialidad_view_model.dart';
import 'especialidad_card.dart';

class ElegirEspecialidadPage extends StatelessWidget {
  const ElegirEspecialidadPage({
    super.key,
    required this.viewModel,
    required this.getDoctors,
    required this.getTimeSlots,
    this.updateTimeSlot,
  });

  final ElegirEspecialidadViewModel viewModel;
  final GetDoctorsBySpecialtyUseCase getDoctors;
  final GetTimeSlotsByDoctorAndDateUseCase getTimeSlots;
  final UpdateTimeSlotUseCase? updateTimeSlot;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: viewModel,
    builder: (context, _) => StaffScaffold(
      title: 'Elige especialidad',
      children: [
        BuscadorWidget(onChanged: viewModel.search),
        if (viewModel.isLoading)
          const Center(child: CircularProgressIndicator()),
        if (viewModel.errorMessage != null)
          ErrorState(
            message: viewModel.errorMessage!,
            onRetry: viewModel.loadSpecialties,
          ),
        if (!viewModel.isLoading && viewModel.errorMessage == null) ...[
          if (viewModel.filteredSpecialties.isEmpty)
            const Text('No se encontraron especialidades.'),
          for (final speciality in viewModel.filteredSpecialties)
            EspecialidadCard(
              speciality: speciality,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CalendarioPage(
                    speciality: speciality,
                    viewModel: CalendarioViewModel(
                      speciality: speciality,
                      getDoctors: getDoctors,
                      getTimeSlots: getTimeSlots,
                      updateTimeSlot: updateTimeSlot,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ],
    ),
  );
}
