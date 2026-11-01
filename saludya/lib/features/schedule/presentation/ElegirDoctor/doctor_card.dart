import 'package:flutter/material.dart';

import '../../domain/model/doctor.dart';
import '../shared/staff_widgets.dart';

class DoctorCard extends StatelessWidget {
  const DoctorCard({super.key, required this.doctor, required this.onTap});
  final Doctor doctor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InfoCard(
    title: '${doctor.name} ${doctor.lastname}',
    action: 'Ver horario →',
    onTap: onTap,
  );
}
