import '../model/appoinment.dart';

abstract class AppointmentRepository {
  Future<List<Appointment>> getAppoinments();
  Future<Appointment?> getAppoinmentById(int id);
  Future<List<Appointment>> getAppoinmentByPatient(int patientId);
  Future<void> cancelAppoinment(int id);
}
