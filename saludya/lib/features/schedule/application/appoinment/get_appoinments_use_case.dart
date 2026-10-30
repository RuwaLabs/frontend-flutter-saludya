import '../../domain/model/appoinment.dart';
import '../../domain/repositories/appoinment_repository.dart';

class GetAppoinmentsUseCase {
  final AppointmentRepository repository;

  const GetAppoinmentsUseCase({required this.repository});

  Future<List<Appointment>> execute() async {
    return await repository.getAppoinments();
  }
}
