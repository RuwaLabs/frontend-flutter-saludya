import '../model/time_slot.dart';

abstract class TimeSlotRepository {
  Future<List<TimeSlot>> getTimeSlots();
  Future<List<TimeSlot>> getAvailableTimeSlots();
  Future<List<TimeSlot>> getTimeSlotsByDoctorAndDate(int doctorId, DateTime date);
  Future<void> updateTimeSlot(TimeSlot timeSlot);
}
