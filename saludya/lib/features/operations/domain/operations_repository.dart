import 'operations_models.dart';

abstract class OperationsRepository {
  Future<DashboardMetrics> getDashboard(DateTime date);
  Future<List<Specialty>> getSpecialties();
  Future<List<Doctor>> getDoctors(int specialtyId);
  Future<List<TimeBlock>> getCalendarBlocks(
    int specialtyId,
    DateTime from,
    DateTime to,
  );
  Future<TimeBlock> getTimeBlock(int id);
  Future<List<BookedPatient>> getAppointmentsForBlock(int timeSlotId);
  Future<List<BookedPatient>> getCancelledAppointments(DateTime date);
  Future<TimeBlock> createTimeBlock(BlockDraft draft);
  Future<TimeBlock> updateTimeBlock(int id, BlockChanges changes);
  Future<AttendanceQueue?> getAttendanceQueue(int timeSlotId, DateTime date);
  Future<List<QueueEntry>> getQueueEntries(int queueId);
  Future<ArrivalReceipt> registerArrival(String bookingCode);
  Future<void> callNext(int queueId);
  Future<void> startAttention(int queueEntryId);
  Future<void> finishAttention(int queueEntryId);
  Future<void> markAbsent(int queueEntryId);
}
