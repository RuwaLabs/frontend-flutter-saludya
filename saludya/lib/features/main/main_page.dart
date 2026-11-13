import 'package:flutter/material.dart';
import 'package:saludya/core/design/saludya_palette.dart';
import 'package:saludya/features/attendance/presentation/attendance_page.dart';
import 'package:saludya/features/calendar/presentation/calendar_page.dart';
import 'package:saludya/features/home/presentation/home_page.dart';
import 'package:saludya/features/operations/domain/operations_models.dart';
import 'package:saludya/features/settings/presentation/settings_page.dart';

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
      SettingsPage(canEdit: widget.role == 'SUPER_ADMIN'),
    ];
    const titles = [
      'Inicio',
      'Calendario',
      'Citas y atención',
      'Configuración',
    ];

    return Scaffold(
      backgroundColor: SaludYaPalette.background,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 12, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      titles[_selectedIndex],
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
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
      bottomNavigationBar: NavigationBar(
        height: 72,
        backgroundColor: Colors.white,
        indicatorColor: SaludYaPalette.selected,
        selectedIndex: _selectedIndex,
        onDestinationSelected: (value) => setState(() {
          _selectedIndex = value;
          _visitedIndexes.add(value);
        }),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month_rounded),
            label: 'Calendario',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_alt_outlined),
            selectedIcon: Icon(Icons.people_alt_rounded),
            label: 'Citas',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune_outlined),
            selectedIcon: Icon(Icons.tune_rounded),
            label: 'Configuración',
          ),
        ],
      ),
    );
  }
}
