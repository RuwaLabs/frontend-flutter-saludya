import '../../domain/model/time_slot.dart';
import '../../domain/repositories/time_slot_repository.dart';

class GetTimeSlotsByDoctorAndDateUseCase {
  final TimeSlotRepository repository;

  const GetTimeSlotsByDoctorAndDateUseCase({required this.repository});

  Future<List<TimeSlot>> execute(int doctorId, DateTime date) async {
    return await repository.getTimeSlotsByDoctorAndDate(doctorId, date);
  }
}
