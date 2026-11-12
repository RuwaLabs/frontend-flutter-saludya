import '../../domain/model/speciality.dart';
import '../../domain/repositories/speciality_repository.dart';

class GetSpecialitiesUseCase {
  final SpecialityRepository repository;

  const GetSpecialitiesUseCase({required this.repository});

  Future<List<Speciality>> execute() async {
    return await repository.getSpecialities();
  }
}
