import '../../domain/model/time_slot.dart';
import '../../domain/repositories/time_slot_repository.dart';

class GetAvailableTimeSlotsUseCase {
  final TimeSlotRepository repository;

  const GetAvailableTimeSlotsUseCase({required this.repository});

  Future<List<TimeSlot>> execute() async {
    return await repository.getAvailableTimeSlots();
  }
}
