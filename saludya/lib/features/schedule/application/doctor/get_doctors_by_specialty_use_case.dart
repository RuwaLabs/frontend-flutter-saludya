import '../../domain/model/doctor.dart';
import '../../domain/repositories/doctor_repository.dart';

class GetDoctorsBySpecialtyUseCase {
  const GetDoctorsBySpecialtyUseCase({required this.repository});
  final DoctorRepository repository;
  Future<List<Doctor>> execute(int specialtyId) =>
      repository.getDoctorsBySpecialty(specialtyId);
}
