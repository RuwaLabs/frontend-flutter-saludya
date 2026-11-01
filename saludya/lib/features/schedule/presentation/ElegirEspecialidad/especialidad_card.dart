import 'package:flutter/material.dart';

import '../../domain/model/speciality.dart';
import '../shared/staff_widgets.dart';

class EspecialidadCard extends StatelessWidget {
  const EspecialidadCard({
    super.key,
    required this.speciality,
    required this.onTap,
  });

  final Speciality speciality;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InfoCard(
    title: speciality.name,
    leading: Icons.add_box_outlined,
    lines: [if (speciality.description.isNotEmpty) speciality.description],
    action: 'Ver disponibilidad →',
    onTap: onTap,
  );
}
