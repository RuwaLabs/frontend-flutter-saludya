import '../../domain/model/appoinment.dart';
import '../../domain/repositories/appoinment_repository.dart';

class GetAppoinmentByPatientUseCase {
  final AppointmentRepository repository;

  const GetAppoinmentByPatientUseCase({required this.repository});

  Future<List<Appointment>> execute(int patientId) async {
    return await repository.getAppoinmentByPatient(patientId);
  }
}
