import '../../domain/model/speciality.dart';
import '../../domain/repositories/speciality_repository.dart';

class GetSpecialityByIdUseCase {
  final SpecialityRepository repository;

  const GetSpecialityByIdUseCase({required this.repository});

  Future<Speciality?> execute(int id) async {
    return await repository.getSpecialityById(id);
  }
}
