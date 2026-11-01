import 'package:flutter/foundation.dart';

import '../../application/speciality/get_specialities_use_case.dart';
import '../../domain/model/speciality.dart';

class ElegirEspecialidadViewModel extends ChangeNotifier {
  final GetSpecialitiesUseCase getSpecialitiesUseCase;

  ElegirEspecialidadViewModel({required this.getSpecialitiesUseCase}) {
    loadSpecialties();
  }

  List<Speciality> specialties = [];
  String query = '';
  List<Speciality> get filteredSpecialties => specialties
      .where((s) => s.name.toLowerCase().contains(query.toLowerCase()))
      .toList();
  bool isLoading = false;
  String? errorMessage;

  void search(String value) {
    query = value;
    notifyListeners();
  }

  Future<void> loadSpecialties() async {
    isLoading = true;
    notifyListeners();

    try {
      specialties = await getSpecialitiesUseCase.execute();
      errorMessage = null;
    } catch (e) {
      errorMessage = 'No se pudieron cargar las especialidades: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
