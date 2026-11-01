import '../model/doctor.dart';

abstract class DoctorRepository {
  Future<List<Doctor>> getDoctors();
  Future<List<Doctor>> getDoctorsBySpecialty(int specialtyId);
  Future<Doctor?> getDoctorById(int id);
}
