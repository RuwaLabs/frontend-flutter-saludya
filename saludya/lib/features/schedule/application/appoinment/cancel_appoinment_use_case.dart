import '../../domain/repositories/appoinment_repository.dart';

class CancelAppoinmentUseCase {
  final AppointmentRepository repository;

  const CancelAppoinmentUseCase({required this.repository});

  Future<void> execute(int id) async {
    await repository.cancelAppoinment(id);
  }
}
