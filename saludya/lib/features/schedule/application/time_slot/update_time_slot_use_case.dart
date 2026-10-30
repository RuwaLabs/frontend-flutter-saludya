import '../../domain/model/time_slot.dart';
import '../../domain/repositories/time_slot_repository.dart';

class UpdateTimeSlotUseCase {
  final TimeSlotRepository repository;

  const UpdateTimeSlotUseCase({required this.repository});

  Future<void> execute(TimeSlot timeSlot) async {
    await repository.updateTimeSlot(timeSlot);
  }
}
