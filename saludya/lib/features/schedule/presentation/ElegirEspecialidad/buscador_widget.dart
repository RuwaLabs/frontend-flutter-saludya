import 'package:flutter/material.dart';

import '../shared/staff_widgets.dart';

class BuscadorWidget extends StatelessWidget {
  const BuscadorWidget({super.key, required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => SearchField(
    label: 'Buscar especialidad',
    hint: 'Buscar por nombre…',
    onChanged: onChanged,
  );
}
