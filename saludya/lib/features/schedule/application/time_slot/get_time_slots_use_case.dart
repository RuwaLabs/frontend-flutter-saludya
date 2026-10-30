import '../../domain/model/time_slot.dart';
import '../../domain/repositories/time_slot_repository.dart';

class GetTimeSlotsUseCase {
  final TimeSlotRepository repository;

  const GetTimeSlotsUseCase({required this.repository});

  Future<List<TimeSlot>> execute() async {
    return await repository.getTimeSlots();
  }
}
