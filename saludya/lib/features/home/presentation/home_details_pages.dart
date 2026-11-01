import 'package:flutter/material.dart';
import '../domain/home_models.dart';
import '../domain/home_repository.dart';
import 'home_ui.dart';

class CancelledAppointmentsPage extends StatelessWidget {
  const CancelledAppointmentsPage({super.key, required this.summary});
  final HomeSummary summary;
  @override
  Widget build(BuildContext context) => Scaffold(backgroundColor: homeBackground,
    appBar: AppBar(title: const Text('Citas canceladas')),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      Text(homeDate(summary.date), style: const TextStyle(color: homeMuted)),
      const SizedBox(height: 16),
      if (summary.cancelled.isEmpty) const HomeMessage(message: 'No hay citas canceladas para esta fecha.'),
      for (final booking in summary.cancelled) HomeCard(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(booking.specialty, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('${booking.patientName} · ${booking.startHour}–${booking.endHour}'),
          Text('Última actualización: ${homeDate(booking.updatedAt)} · ${booking.updatedAt.hour.toString().padLeft(2, '0')}:${booking.updatedAt.minute.toString().padLeft(2, '0')}', style: const TextStyle(color: homeMuted, fontSize: 12)),
          const SizedBox(height: 8), const Text('Cancelada', style: TextStyle(color: homeGreen, fontWeight: FontWeight.w600)),
        ])),
    ]));
}

class ReservedPatientsPage extends StatefulWidget {
  const ReservedPatientsPage({super.key, required this.repository, required this.slot});
  final HomeRepository repository;
  final HomeSlot slot;
  @override
  State<ReservedPatientsPage> createState() => _ReservedPatientsPageState();
}

class _ReservedPatientsPageState extends State<ReservedPatientsPage> {
  late Future<List<HomeBooking>> _patients;
  @override
  void initState() { super.initState(); _load(); }
  void _load() { _patients = widget.repository.getPatients(widget.slot.booking.date, widget.slot.id); }
  @override
  Widget build(BuildContext context) => Scaffold(backgroundColor: homeBackground,
    appBar: AppBar(title: const Text('Pacientes con reserva')),
    body: RefreshIndicator(onRefresh: () async {
      setState(_load);
      try { await _patients; } catch (_) { /* FutureBuilder displays the failure. */ }
    }, child: ListView(physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.all(20), children: [
      Text('${widget.slot.booking.specialty} · ${homeDate(widget.slot.booking.date)} · ${widget.slot.booking.startHour}', style: const TextStyle(color: homeMuted)),
      const SizedBox(height: 16),
      FutureBuilder<List<HomeBooking>>(future: _patients, builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) return const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()));
        if (snapshot.hasError) return HomeMessage(error: true,
          message: snapshot.error is HomeFailure ? (snapshot.error! as HomeFailure).message : 'No pudimos cargar los pacientes.',
          onRetry: () => setState(_load));
        final patients = snapshot.data ?? [];
        if (patients.isEmpty) return const HomeMessage(message: 'No hay pacientes con reserva en este horario.');
        return Column(children: patients.map((patient) {
          final (label, color) = switch (patient.arrival) {
            ArrivalStatus.pending => ('Pendiente de llegada', homeMuted),
            ArrivalStatus.registered => ('Llegada registrada', homeGreen),
            ArrivalStatus.inService => ('En atención', Color(0xFF1466A8)),
            ArrivalStatus.attended => ('Atendido', homeGreen),
            ArrivalStatus.absent => ('Ausente', Color(0xFFB73D38)),
            ArrivalStatus.expired => ('Turno vencido', Color(0xFFB73D38)),
          };
          return HomeCard(child: SizedBox(width: double.infinity, child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(patient.patientName, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8), Text('${patient.code} · ${patient.isMinor ? 'Menor' : 'Titular'}', style: const TextStyle(color: homeMuted)),
              const SizedBox(height: 8), Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
            ])));
        }).toList());
      }),
    ])));
}

class HomeReservationsPage extends StatelessWidget {
  const HomeReservationsPage({super.key, required this.summary, required this.repository});
  final HomeSummary summary;
  final HomeRepository repository;
  @override
  Widget build(BuildContext context) => Scaffold(backgroundColor: homeBackground,
    appBar: AppBar(title: const Text('Reservas de hoy')),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      Text(homeDate(summary.date), style: const TextStyle(color: homeMuted)), const SizedBox(height: 16),
      if (summary.slots.isEmpty) const HomeMessage(message: 'No hay reservas para esta fecha.'),
      for (final slot in summary.slots) HomeCard(
        onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => ReservedPatientsPage(repository: repository, slot: slot))),
        child: Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(slot.booking.specialty, style: const TextStyle(fontWeight: FontWeight.w600)), const SizedBox(height: 8),
          Text('${slot.booking.startHour}–${slot.booking.endHour} · ${slot.patientCount} ${slot.patientCount == 1 ? 'paciente' : 'pacientes'}'),
          const SizedBox(height: 8), const Text('Ver pacientes con reserva', style: TextStyle(color: homeGreen)),
        ])), const Icon(Icons.chevron_right, color: homeGreen)])),
    ]));
}
