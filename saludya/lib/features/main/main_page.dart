import 'package:flutter/material.dart';
import 'package:saludya/core/design/saludya_palette.dart';
import 'package:saludya/features/attendance/presentation/attendance_page.dart';
import 'package:saludya/features/calendar/presentation/calendar_page.dart';
import 'package:saludya/features/home/presentation/home_page.dart';
import 'package:saludya/features/operations/domain/operations_models.dart';
import 'package:saludya/features/settings/presentation/settings_page.dart';

bool canEditGlobalSettings(String role) =>
    const {'ADMISSION_STAFF', 'SUPER_ADMIN'}.contains(role);

class MainPage extends StatefulWidget {
  final Future<void> Function() onLogout;
  final String role;

  const MainPage({super.key, required this.onLogout, required this.role});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;
  TimeBlock? _queueBlock;
  bool _openCancelled = false;
  final Set<int> _visitedIndexes = {0};

  void _openCalendar() => setState(() {
    _selectedIndex = 1;
    _visitedIndexes.add(1);
  });
  void _openAttendance() => setState(() {
    _openCancelled = false;
    _selectedIndex = 2;
    _visitedIndexes.add(2);
  });

  void _openCancelledAppointments() => setState(() {
    _queueBlock = null;
    _openCancelled = true;
    _selectedIndex = 2;
    _visitedIndexes.add(2);
  });

  void _openQueue(TimeBlock block) {
    setState(() {
      _queueBlock = block;
      _openCancelled = false;
      _selectedIndex = 2;
      _visitedIndexes.add(2);
    });
  }

  Widget _navigationItem(int index, IconData icon, String label) => Expanded(
    child: InkWell(
      onTap: () => setState(() {
        _selectedIndex = index;
        _visitedIndexes.add(index);
      }),
      child: Container(
        height: 61,
        color: _selectedIndex == index ? SaludYaPalette.selected : Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 22,
              color: _selectedIndex == index
                  ? SaludYaPalette.primary
                  : SaludYaPalette.secondaryText,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                color: _selectedIndex == index
                    ? SaludYaPalette.primary
                    : SaludYaPalette.secondaryText,
                fontWeight: _selectedIndex == index
                    ? FontWeight.w600
                    : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      HomePage(
        onOpenCalendar: _openCalendar,
        onOpenAttendance: _openAttendance,
        onOpenCancelled: _openCancelledAppointments,
      ),
      CalendarPage(onOpenQueue: _openQueue),
      AttendancePage(
        key: ValueKey('${_queueBlock?.id}-$_openCancelled'),
        initialBlock: _queueBlock,
        active: _selectedIndex == 2,
        initialCancelled: _openCancelled,
      ),
      SettingsPage(canEdit: canEditGlobalSettings(widget.role)),
    ];
    const titles = [
      'Hola, equipo de admisión',
      'Calendario',
      'Cola de atención',
      'Configuración general',
    ];

    return Scaffold(
      backgroundColor: SaludYaPalette.background,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 10, 12, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      titles[_selectedIndex],
                      style: const TextStyle(
                        fontSize: 21,
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                        color: SaludYaPalette.text,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Cerrar sesión',
                    onPressed: widget.onLogout,
                    icon: const Icon(
                      Icons.logout_outlined,
                      color: SaludYaPalette.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: [
                for (var i = 0; i < pages.length; i++)
                  _visitedIndexes.contains(i)
                      ? pages[i]
                      : const SizedBox.shrink(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: SizedBox(
          height: 72,
          child: ColoredBox(
            color: Colors.white,
            child: Row(
              children: [
                _navigationItem(0, Icons.home_outlined, 'Inicio'),
                _navigationItem(1, Icons.calendar_month_outlined, 'Calendario'),
                _navigationItem(2, Icons.qr_code_scanner_outlined, 'Cita'),
                _navigationItem(3, Icons.tune_outlined, 'Configuración'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
