import '../../domain/model/doctor.dart';
import '../../domain/model/speciality.dart';
import '../../domain/model/time_slot.dart';
import '../../domain/repositories/doctor_repository.dart';
import '../../domain/repositories/speciality_repository.dart';
import '../../domain/repositories/time_slot_repository.dart';
import 'api/saludya_api.dart';
import 'dtos/time_slot_dto.dart';

/// Adaptadores de la API HTTP al dominio.
class ApiSpecialityRepository implements SpecialityRepository {
  ApiSpecialityRepository(this.api);

  final SaludYaApi api;

  @override
  Future<List<Speciality>> getSpecialities() async => [
    for (final dto in await api.getSpecialities())
      Speciality(id: dto.id, name: dto.name, description: dto.description),
  ];

  @override
  Future<Speciality?> getSpecialityById(int id) async {
    final dto = await api.getSpecialityById(id);
    return dto == null
        ? null
        : Speciality(id: dto.id, name: dto.name, description: dto.description);
  }
}

class ApiDoctorRepository implements DoctorRepository {
  ApiDoctorRepository(this.api);

  final SaludYaApi api;

  @override
  Future<List<Doctor>> getDoctors() async => [
    for (final speciality in await api.getSpecialities())
      ...await getDoctorsBySpecialty(speciality.id),
  ];

  @override
  Future<List<Doctor>> getDoctorsBySpecialty(int specialtyId) async => [
    for (final dto in await api.getDoctorsBySpecialty(specialtyId))
      Doctor(
        id: dto.id,
        specialityId: dto.specialityId,
        name: dto.name,
        lastname: dto.lastname,
      ),
  ];

  @override
  Future<Doctor?> getDoctorById(int id) async {
    final dto = await api.getDoctorById(id);
    return dto == null
        ? null
        : Doctor(
            id: dto.id,
            specialityId: dto.specialityId,
            name: dto.name,
            lastname: dto.lastname,
          );
  }
}

class ApiTimeSlotRepository implements TimeSlotRepository {
  ApiTimeSlotRepository(this.api);

  final SaludYaApi api;

  TimeSlot _toDomain(TimeSlotDto dto) => TimeSlot(
    id: dto.id,
    doctorId: dto.doctorId,
    date: dto.date,
    startHour: dto.startHour,
    endHour: dto.endHour,
    room: dto.room,
    maxCapacity: dto.maxCapacity,
    currentBookings: dto.currentBookings,
    status: dto.status,
  );

  @override
  Future<List<TimeSlot>> getTimeSlots() => Future.error(
    UnsupportedError(
      'La API requiere doctorId y fecha para consultar horarios.',
    ),
  );

  @override
  Future<List<TimeSlot>> getAvailableTimeSlots() => Future.error(
    UnsupportedError(
      'La API requiere specialtyId y fecha para consultar disponibilidad.',
    ),
  );

  @override
  Future<List<TimeSlot>> getAvailableTimeSlotsBySpecialty(
    int specialtyId,
    DateTime date,
  ) async => [
    for (final dto in await api.getAvailableTimeSlots(specialtyId, date))
      _toDomain(dto),
  ];

  @override
  Future<List<TimeSlot>> getTimeSlotsByDoctorAndDate(
    int doctorId,
    DateTime date,
  ) async => [
    for (final dto in await api.getTimeSlotsByDoctorAndDate(doctorId, date))
      _toDomain(dto),
  ];

  @override
  Future<void> updateTimeSlot(TimeSlot slot) => api.updateTimeSlot(
    TimeSlotDto(
      id: slot.id,
      doctorId: slot.doctorId,
      date: slot.date,
      startHour: slot.startHour,
      endHour: slot.endHour,
      room: slot.room,
      maxCapacity: slot.maxCapacity,
      currentBookings: slot.currentBookings,
      status: slot.status,
    ),
  );
}
