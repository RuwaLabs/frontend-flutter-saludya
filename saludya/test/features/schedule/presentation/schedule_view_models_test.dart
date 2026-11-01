import 'package:flutter_test/flutter_test.dart';
import 'package:saludya/features/schedule/application/doctor/get_doctors_by_specialty_use_case.dart';
import 'package:saludya/features/schedule/application/speciality/get_specialities_use_case.dart';
import 'package:saludya/features/schedule/application/time_slot/get_time_slots_by_doctor_and_date_use_case.dart';
import 'package:saludya/features/schedule/domain/model/doctor.dart';
import 'package:saludya/features/schedule/domain/model/speciality.dart';
import 'package:saludya/features/schedule/domain/model/time_slot.dart';
import 'package:saludya/features/schedule/domain/repositories/doctor_repository.dart';
import 'package:saludya/features/schedule/domain/repositories/speciality_repository.dart';
import 'package:saludya/features/schedule/domain/repositories/time_slot_repository.dart';
import 'package:saludya/features/schedule/presentation/Calendario/calendario_view_model.dart';
import 'package:saludya/features/schedule/presentation/ElegirEspecialidad/elegir_especialidad_view_model.dart';

const general = Speciality(id: 1, name: 'Medicina general', description: '');
const doctor = Doctor(id: 3, specialityId: 1, name: 'Ana', lastname: 'Ríos');

class SpecialitiesFake implements SpecialityRepository {
  @override
  Future<List<Speciality>> getSpecialities() async => [
    general,
    const Speciality(id: 2, name: 'Pediatría', description: ''),
  ];
  @override
  Future<Speciality?> getSpecialityById(int id) async => general;
}

class DoctorsFake implements DoctorRepository {
  @override
  Future<List<Doctor>> getDoctorsBySpecialty(int id) async => [doctor];
  @override
  Future<List<Doctor>> getDoctors() async => [doctor];
  @override
  Future<Doctor?> getDoctorById(int id) async => doctor;
}

class SlotsFake implements TimeSlotRepository {
  @override
  Future<List<TimeSlot>> getAvailableTimeSlotsBySpecialty(
    int id,
    DateTime date,
  ) => getTimeSlotsByDoctorAndDate(doctor.id, date);
  @override
  Future<List<TimeSlot>> getTimeSlots() async => [
    TimeSlot(
      id: 1,
      doctorId: 3,
      date: DateTime(2026, 11, 3),
      startHour: DateTime(2026, 11, 3, 8),
      endHour: DateTime(2026, 11, 3, 9),
      room: '02',
      maxCapacity: 8,
      currentBookings: 2,
      status: 'available',
    ),
  ];
  @override
  Future<List<TimeSlot>> getAvailableTimeSlots() => getTimeSlots();
  @override
  Future<List<TimeSlot>> getTimeSlotsByDoctorAndDate(int id, DateTime date) =>
      getTimeSlots().then(
        (slots) => slots
            .where(
              (slot) =>
                  slot.doctorId == id &&
                  slot.date.year == date.year &&
                  slot.date.month == date.month &&
                  slot.date.day == date.day,
            )
            .toList(),
      );
  @override
  Future<void> updateTimeSlot(TimeSlot slot) async {}
}

void main() {
  test('filtra especialidades obtenidas por el caso de uso', () async {
    final vm = ElegirEspecialidadViewModel(
      getSpecialitiesUseCase: GetSpecialitiesUseCase(
        repository: SpecialitiesFake(),
      ),
    );
    await vm.loadSpecialties();
    vm.search('PEDIA');
    expect(vm.filteredSpecialties.map((s) => s.name), ['Pediatría']);
    vm.dispose();
  });

  test('filtra bloques por especialidad y fecha seleccionada', () async {
    final vm = CalendarioViewModel(
      speciality: general,
      getDoctors: GetDoctorsBySpecialtyUseCase(repository: DoctorsFake()),
      getTimeSlots: GetTimeSlotsByDoctorAndDateUseCase(repository: SlotsFake()),
    );
    vm.month = DateTime(2026, 11);
    vm.selectDay(3);
    await vm.load();
    expect(vm.slotsFor(general, DateTime(2026, 11, 3)).length, 1);
    expect(vm.slotsFor(general, DateTime(2026, 11, 4)), isEmpty);
    vm.changeMonth(1);
    expect(vm.selectedDate.day, 1);
    await vm.load();
    vm.dispose();
  });
}
