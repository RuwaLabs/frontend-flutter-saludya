import 'package:flutter/foundation.dart';

import '../domain/arrival_result.dart';
import '../domain/qr_repository.dart';
import '../domain/qr_ticket.dart';

/// Estado y acciones de la cola. Sin dependencias extra (ChangeNotifier);
/// si usas Riverpod/Bloc, los métodos se trasladan 1:1.
class QrController extends ChangeNotifier {
  QrController(this._repo);
  final QrRepository _repo;

  QrSnapshot? snapshot;
  bool loading = false;
  bool busy = false; // acción en curso (deshabilita botones)
  String? error;

  List<QrTicket> get activeTickets =>
      snapshot?.tickets.where((t) => t.isActive).toList() ?? const [];

  QrTicket? get inAttention =>
      activeTickets.where((t) => t.status == TicketStatus.inAttention).firstOrNull;

  QrTicket? get called =>
      activeTickets.where((t) => t.status == TicketStatus.called).firstOrNull;

  bool get hasWaiting => activeTickets.any((t) => t.status == TicketStatus.waiting);

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      snapshot = await _repo.getQr();
    } on QrException catch (e) {
      error = e.message;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<QrTicket?> callNext() => _act(_repo.callNext);
  Future<QrTicket?> startAttention(String id) => _act(() => _repo.startAttention(id));
  Future<QrTicket?> markAbsent(String id) => _act(() => _repo.markAbsent(id));
  Future<QrTicket?> finishAttention(String id) => _act(() => _repo.finishAttention(id));

  Future<ArrivalResult?> registerArrival(String code) async {
    busy = true;
    error = null;
    notifyListeners();
    try {
      final r = await _repo.registerArrival(code.trim().toUpperCase());
      await load();
      return r;
    } on QrException catch (e) {
      error = e.message;
      return null;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<QrTicket?> _act(Future<QrTicket> Function() action) async {
    busy = true;
    error = null;
    notifyListeners();
    try {
      final t = await action();
      _upsert(t);
      return t;
    } on QrException catch (e) {
      error = e.message;
      return null;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  void _upsert(QrTicket t) {
    final s = snapshot;
    if (s == null) return;
    final list = [...s.tickets];
    final i = list.indexWhere((x) => x.id == t.id);
    i >= 0 ? list[i] = t : list.add(t);
    snapshot = QrSnapshot(date: s.date, block: s.block, tickets: list);
  }
}
