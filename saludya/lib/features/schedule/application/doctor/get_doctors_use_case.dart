import '../../domain/model/doctor.dart';
import '../../domain/repositories/doctor_repository.dart';

class GetDoctorsUseCase {
  final DoctorRepository repository;

  const GetDoctorsUseCase({required this.repository});

  Future<List<Doctor>> execute() async {
    return await repository.getDoctors();
  }
}
