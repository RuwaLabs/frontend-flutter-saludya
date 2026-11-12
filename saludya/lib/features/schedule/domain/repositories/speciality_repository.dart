import '../model/speciality.dart';

abstract class SpecialityRepository {
  Future<List<Speciality>> getSpecialities();
  Future<Speciality?> getSpecialityById(int id);
}
