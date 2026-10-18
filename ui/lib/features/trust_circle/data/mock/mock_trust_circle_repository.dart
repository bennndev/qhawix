import '../../domain/action_result.dart';
import '../../domain/alert_preferences.dart';
import '../../domain/check_in.dart';
import '../../domain/clock.dart';
import '../../domain/refuge_request.dart';
import '../../domain/sos.dart';
import '../../domain/trust_circle_repository.dart';
import '../../domain/trust_circle_snapshot.dart';
import '../../domain/trust_contact.dart';

/// In-memory example data. Nothing is sent, stored or delivered: every command
/// changes local example state and answers with a sentence that says so.
/// Developer builds and tests only; never a user-facing feature.
class MockTrustCircleRepository implements TrustCircleRepository {
  @override
  bool get usesExampleData => true;

  MockTrustCircleRepository({required Clock clock}) : _clock = clock {
    final now = _clock.now();
    _contacts = [
      TrustContact(
        id: 'c1',
        name: 'Ana Ejemplo',
        phone: '+51 000 000 001',
        kind: ContactKind.appUser,
        permissions: const ContactPermissions(
          mayRequestRemoteRefuge: true,
          maySeeTemporaryLocation: true,
        ),
      ),
      TrustContact(
        id: 'c2',
        name: 'Mamá (ejemplo)',
        phone: '+51 000 000 002',
        permissions: const ContactPermissions(maySeeTemporaryLocation: true),
        channel: AlertChannel.whatsapp,
      ),
      TrustContact(
        id: 'c3',
        name: 'Carla Ejemplo',
        phone: '+51 000 000 003',
        installInvitePending: true,
      ),
      TrustContact(
        id: 'c4',
        name: 'Dani Ejemplo',
        phone: '+51 000 000 004',
        kind: ContactKind.appUser,
        status: ContactStatus.paused,
      ),
    ];
    _requests = [
      RefugeRequest(
        id: 'r1',
        contactId: 'c1',
        requestedAt: now.subtract(Duration(minutes: _exampleRequestAgeMinutes)),
      ),
    ];
    _prefs = const AlertPreferences(
      recipients: {
        AlertEventKind.voiceCloneDetected: {'c1', 'c2'},
        AlertEventKind.paymentHold: {'c1'},
        AlertEventKind.refugeActivated: {'c1', 'c2'},
      },
    );
  }

  final Clock _clock;
  late List<TrustContact> _contacts;
  late List<RefugeRequest> _requests;
  late AlertPreferences _prefs;
  CheckIn? _checkIn;
  String? _keyword;
  int _nextId = 100;

  static const _exampleRequestAgeMinutes = 10;

  static const _savedNote =
      'Ejemplo: el cambio se guardó solo en esta demostración.';
  static const _noNotice = 'Ejemplo: no se envió ningún aviso.';

  ActionResult get _saved =>
      const ActionResult(ActionOutcome.exampleOnly, _savedNote);

  @override
  Future<TrustCircleSnapshot> load() async => TrustCircleSnapshot(
    contacts: List.unmodifiable(_contacts),
    refugeRequests: List.unmodifiable(_requests),
    alertPreferences: _prefs,
    checkIn: _checkIn,
    hasKeyword: _keyword != null,
    setupComplete: true,
  );

  @override
  Future<ActionResult> completeSetup() async => _saved;

  @override
  Future<ActionResult> addContact({
    required String name,
    required String phone,
  }) async {
    final cleanName = name.trim();
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (cleanName.isEmpty || digits.length < 6) {
      return const ActionResult(
        ActionOutcome.rejected,
        'Revisa el nombre y el número: faltan datos.',
      );
    }
    _contacts = [
      ..._contacts,
      TrustContact(id: 'c${_nextId++}', name: cleanName, phone: phone.trim()),
    ];
    return const ActionResult(
      ActionOutcome.exampleOnly,
      'Ejemplo: contacto agregado solo en esta demostración. '
      'No se envió ningún mensaje.',
    );
  }

  @override
  Future<ActionResult> inviteToInstall(String contactId) async {
    final contact = _find(contactId);
    if (contact == null || contact.hasApp) {
      return const ActionResult(
        ActionOutcome.rejected,
        'Este contacto ya tiene la app.',
      );
    }
    _replace(contactId, (c) => c.copyWith(installInvitePending: true));
    return const ActionResult(
      ActionOutcome.exampleOnly,
      'Ejemplo: no se envió ninguna invitación.',
    );
  }

  TrustContact? _find(String id) {
    for (final c in _contacts) {
      if (c.id == id) return c;
    }
    return null;
  }

  void _replace(String id, TrustContact Function(TrustContact) change) {
    _contacts = [for (final c in _contacts) c.id == id ? change(c) : c];
  }

  @override
  Future<ActionResult> updatePermissions(
    String contactId,
    ContactPermissions permissions,
  ) async {
    final contact = _find(contactId);
    final violation = contact?.permissionViolation(permissions);
    if (violation != null) {
      return ActionResult(ActionOutcome.rejected, violation);
    }
    _replace(contactId, (c) => c.copyWith(permissions: permissions));
    return _saved;
  }

  @override
  Future<ActionResult> setContactChannel(
    String contactId,
    AlertChannel channel,
  ) async {
    final violation = _find(contactId)?.channelViolation(channel);
    if (violation != null || channel == AlertChannel.push) {
      return ActionResult(
        ActionOutcome.rejected,
        violation ?? 'Las notificaciones push siempre van primero.',
      );
    }
    _replace(contactId, (c) => c.copyWith(channel: channel));
    return _saved;
  }

  @override
  Future<ActionResult> setContactPaused(
    String contactId, {
    required bool paused,
  }) async {
    _replace(
      contactId,
      (c) => c.copyWith(
        status: paused ? ContactStatus.paused : ContactStatus.active,
      ),
    );
    return _saved;
  }

  @override
  Future<ActionResult> removeContact(String contactId) async {
    _contacts = [
      for (final c in _contacts)
        if (c.id != contactId) c,
    ];
    _requests = [
      for (final r in _requests)
        if (r.contactId != contactId) r,
    ];
    _prefs = _prefs.without(contactId);
    return const ActionResult(
      ActionOutcome.exampleOnly,
      'Ejemplo: se quitó el contacto de la demostración. '
      'No se avisó a nadie.',
    );
  }

  @override
  Future<ActionResult> setAlertRecipients(
    AlertEventKind kind,
    Set<String> contactIds,
  ) async {
    _prefs = _prefs.withRecipients(kind, contactIds);
    return _saved;
  }

  @override
  Future<ActionResult> setAlertFallback(AlertChannelChoice choice) async {
    _prefs = _prefs.withFallback(choice);
    return _saved;
  }

  @override
  Future<ActionResult> sendSos({
    required Set<String> contactIds,
    required SosDuration duration,
  }) async {
    if (contactIds.isEmpty) {
      return const ActionResult(
        ActionOutcome.rejected,
        'Elige al menos un contacto.',
      );
    }
    return const ActionResult(
      ActionOutcome.exampleOnly,
      '$_noNotice No se preparó ningún mensaje ni se compartió tu ubicación.',
    );
  }

  @override
  Future<ActionResult> startCheckIn(CheckInWindow window) async {
    final now = _clock.now();
    _checkIn = CheckIn(startedAt: now, dueAt: now.add(window.duration));
    return const ActionResult(
      ActionOutcome.exampleOnly,
      'Ejemplo: la ventana quedó programada solo en esta demostración. '
      'No se avisará a nadie si vence.',
    );
  }

  @override
  Future<ActionResult> confirmCheckIn() async {
    final current = _checkIn;
    if (current != null) _checkIn = current.confirm(_clock.now());
    return const ActionResult(
      ActionOutcome.exampleOnly,
      'Ejemplo: llegada marcada en la demostración. No se avisó a nadie.',
    );
  }

  @override
  Future<ActionResult> cancelCheckIn() async {
    _checkIn = null;
    return _saved;
  }

  @override
  Future<ActionResult> resolveRefugeRequest(
    String requestId, {
    required bool approve,
  }) async {
    _requests = [
      for (final r in _requests)
        r.id == requestId
            ? r.copyWith(
                status: approve
                    ? RefugeRequestStatus.approved
                    : RefugeRequestStatus.denied,
              )
            : r,
    ];
    return ActionResult(
      ActionOutcome.exampleOnly,
      approve
          ? 'Ejemplo: no se activó ningún Refugio ni se avisó a nadie.'
          : 'Ejemplo: solicitud rechazada en la demostración. '
                'No se avisó a nadie.',
    );
  }

  @override
  Future<String?> readKeyword() async => _keyword;

  @override
  Future<ActionResult> saveKeyword(String keyword) async {
    final clean = keyword.trim();
    if (clean.length < 4) {
      return const ActionResult(
        ActionOutcome.rejected,
        'La palabra debe tener al menos 4 caracteres.',
      );
    }
    _keyword = clean;
    return const ActionResult(
      ActionOutcome.exampleOnly,
      'Ejemplo: la palabra se guardó solo en esta demostración. '
      'No se compartió con nadie.',
    );
  }
}
