import '../../domain/model/time_slot.dart';
import '../../domain/repositories/time_slot_repository.dart';

class GetAvailableSlotsBySpecialtyUseCase {
  const GetAvailableSlotsBySpecialtyUseCase({required this.repository});
  final TimeSlotRepository repository;
  Future<List<TimeSlot>> execute(int specialtyId, DateTime date) =>
      repository.getAvailableTimeSlotsBySpecialty(specialtyId, date);
}
