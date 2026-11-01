import 'package:flutter/foundation.dart';

import '../../application/doctor/get_doctors_by_specialty_use_case.dart';
import '../../application/time_slot/get_time_slots_by_doctor_and_date_use_case.dart';
import '../../application/time_slot/update_time_slot_use_case.dart';
import '../../domain/model/doctor.dart';
import '../../domain/model/speciality.dart';
import '../../domain/model/time_slot.dart';

class CalendarioViewModel extends ChangeNotifier {
  CalendarioViewModel({
    required this.getDoctors,
    required this.getTimeSlots,
    required this.speciality,
    this.updateTimeSlot,
  }) {
    load();
  }

  final GetDoctorsBySpecialtyUseCase getDoctors;
  final GetTimeSlotsByDoctorAndDateUseCase getTimeSlots;
  final Speciality speciality;
  final UpdateTimeSlotUseCase? updateTimeSlot;
  List<Doctor> doctors = [];
  List<TimeSlot> slots = [];
  bool isLoading = false;
  String? errorMessage;
  DateTime selectedDate = DateTime.now();
  DateTime month = DateTime(DateTime.now().year, DateTime.now().month);
  int _requestId = 0;

  @override
  void dispose() {
    _requestId++;
    super.dispose();
  }

  Future<void> load() async {
    final requestId = ++_requestId;
    isLoading = true;
    errorMessage = null;
    slots = [];
    notifyListeners();
    try {
      final fetchedDoctors = await getDoctors.execute(speciality.id);
      final results = await Future.wait([
        for (final doctor in fetchedDoctors)
          getTimeSlots.execute(doctor.id, selectedDate),
      ]);
      if (requestId != _requestId) return;
      doctors = fetchedDoctors;
      slots = results.expand((items) => items).toList();
    } catch (error) {
      if (requestId != _requestId) return;
      errorMessage = 'No se pudo cargar el calendario: $error';
    } finally {
      if (requestId == _requestId) {
        isLoading = false;
        notifyListeners();
      }
    }
  }

  List<Doctor> doctorsFor(Speciality speciality) =>
      doctors.where((doctor) => doctor.specialityId == speciality.id).toList();

  List<TimeSlot> slotsFor(
    Speciality speciality,
    DateTime date, {
    Doctor? doctor,
  }) {
    final ids = doctorsFor(speciality).map((d) => d.id).toSet();
    return slots
        .where(
          (slot) =>
              ids.contains(slot.doctorId) &&
              (doctor == null || slot.doctorId == doctor.id) &&
              slot.date.year == date.year &&
              slot.date.month == date.month &&
              slot.date.day == date.day,
        )
        .toList()
      ..sort((a, b) => a.startHour.compareTo(b.startHour));
  }

  void selectDay(int day) {
    selectedDate = DateTime(month.year, month.month, day);
    load();
  }

  void changeMonth(int delta) {
    month = DateTime(month.year, month.month + delta);
    selectedDate = month;
    load();
  }

  Future<void> saveSlot(TimeSlot slot) async {
    if (updateTimeSlot == null) return;
    await updateTimeSlot!.execute(slot);
    final index = slots.indexWhere((item) => item.id == slot.id);
    if (index != -1) slots[index] = slot;
    notifyListeners();
  }
}
