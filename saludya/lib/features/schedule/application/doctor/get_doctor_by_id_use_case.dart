import '../../domain/model/doctor.dart';
import '../../domain/repositories/doctor_repository.dart';

class GetDoctorByIdUseCase {
  final DoctorRepository repository;

  const GetDoctorByIdUseCase({required this.repository});

  Future<Doctor?> execute(int id) async {
    return await repository.getDoctorById(id);
  }
}
