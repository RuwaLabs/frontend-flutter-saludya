import '../model/doctor.dart';

abstract class DoctorRepository {
  Future<List<Doctor>> getDoctors();
  Future<Doctor?> getDoctorById(int id);
}
