import '../../domain/model/appoinment.dart';
import '../../domain/repositories/appoinment_repository.dart';

class GetAppoinmentByIdUseCase {
  final AppointmentRepository repository;

  const GetAppoinmentByIdUseCase({required this.repository});

  Future<Appointment?> execute(int id) async {
    return await repository.getAppoinmentById(id);
  }
}
