import 'package:flutter/material.dart';

import 'features/schedule/application/doctor/get_doctors_by_specialty_use_case.dart';
import 'features/schedule/application/speciality/get_specialities_use_case.dart';
import 'features/schedule/application/time_slot/get_time_slots_by_doctor_and_date_use_case.dart';
import 'features/schedule/application/time_slot/update_time_slot_use_case.dart';
import 'features/schedule/infrastructure/remote/api/saludya_api.dart';
import 'features/schedule/infrastructure/remote/schedule_repositories.dart';
import 'features/schedule/presentation/ElegirEspecialidad/elegir_especialidad_page.dart';
import 'features/schedule/presentation/ElegirEspecialidad/elegir_especialidad_view_model.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key, this.api});
  final SaludYaApi? api;

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  late final SaludYaApi api = widget.api ?? SaludYaApi();
  late final specialityRepository = ApiSpecialityRepository(api);
  late final doctorRepository = ApiDoctorRepository(api);
  late final timeSlotRepository = ApiTimeSlotRepository(api);
  late final viewModel = ElegirEspecialidadViewModel(
    getSpecialitiesUseCase: GetSpecialitiesUseCase(
      repository: specialityRepository,
    ),
  );

  @override
  void dispose() {
    viewModel.dispose();
    if (widget.api == null) api.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SaludYa · Calendario',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0B8F6B)),
      ),
      home: ElegirEspecialidadPage(
        viewModel: viewModel,
        getDoctors: GetDoctorsBySpecialtyUseCase(repository: doctorRepository),
        getTimeSlots: GetTimeSlotsByDoctorAndDateUseCase(
          repository: timeSlotRepository,
        ),
        updateTimeSlot: UpdateTimeSlotUseCase(repository: timeSlotRepository),
      ),
    );
  }
}
