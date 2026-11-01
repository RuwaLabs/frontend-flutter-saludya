import 'home_models.dart';

abstract interface class HomeRepository {
  Future<HomeSummary> getSummary(DateTime date);
  Future<List<HomeBooking>> getPatients(DateTime date, int timeSlotId);
}
