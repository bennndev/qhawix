import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../domain/action_result.dart';
import '../domain/alert_preferences.dart';
import '../domain/check_in.dart';
import '../domain/clock.dart';
import '../domain/refuge_request.dart';
import '../domain/sos.dart';
import '../domain/trust_circle_repository.dart';
import '../domain/trust_circle_snapshot.dart';
import '../domain/trust_contact.dart';
import 'trust_circle_local_mapper.dart';

/// On-device Trust Circle store. Contacts never leave the phone except when
/// the person sends SMS/WhatsApp from their own apps.
class LocalTrustCircleRepository implements TrustCircleRepository {
  LocalTrustCircleRepository({
    required Clock clock,
    Future<Directory> Function()? supportDirectory,
    Future<bool> Function(Uri uri)? launchUri,
  }) : _clock = clock,
       _supportDirectory =
           supportDirectory ?? getApplicationSupportDirectory,
       _launchUri = launchUri ?? _defaultLaunch;

  final Clock _clock;
  final Future<Directory> Function() _supportDirectory;
  final Future<bool> Function(Uri uri) _launchUri;

  static const _fileName = 'trust_circle.json';

  List<TrustContact> _contacts = [];
  List<RefugeRequest> _requests = [];
  AlertPreferences _prefs = const AlertPreferences();
  CheckIn? _checkIn;
  String? _keyword;
  bool _setupComplete = false;
  int _nextId = 1;
  bool _loaded = false;

  @override
  bool get usesExampleData => false;

  static Future<bool> _defaultLaunch(Uri uri) => launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

  Future<File> _file() async {
    final dir = await _supportDirectory();
    return File('${dir.path}/$_fileName');
  }

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    _loaded = true;
    final file = await _file();
    if (!await file.exists()) return;
    try {
      final map = jsonDecode(await file.readAsString()) as Map<String, Object?>;
      final contacts = (map['contacts'] as List<Object?>? ?? const [])
          .cast<Map<String, Object?>>();
      _contacts = [
        for (final c in contacts) TrustCircleLocalMapper.contactFromJson(c),
      ];
      _prefs = TrustCircleLocalMapper.prefsFromJson(
        (map['alertPreferences'] as Map?)?.cast<String, Object?>(),
      );
      _checkIn = TrustCircleLocalMapper.checkInFromJson(
        (map['checkIn'] as Map?)?.cast<String, Object?>(),
      );
      _keyword = map['keyword'] as String?;
      _setupComplete = map['setupComplete'] as bool? ?? false;
      _nextId = map['nextId'] as int? ?? (_contacts.length + 1);
      _requests = const [];
    } on Object {
      // Corrupt file: start empty rather than crash the module.
      _contacts = [];
    }
  }

  Future<void> _persist() async {
    final file = await _file();
    final payload = <String, Object?>{
      'schemaVersion': TrustCircleLocalMapper.schemaVersion,
      'setupComplete': _setupComplete,
      'nextId': _nextId,
      'keyword': _keyword,
      'contacts': [
        for (final c in _contacts) TrustCircleLocalMapper.contactToJson(c),
      ],
      'alertPreferences': TrustCircleLocalMapper.prefsToJson(_prefs),
      'checkIn': TrustCircleLocalMapper.checkInToJson(_checkIn),
    };
    await file.writeAsString(jsonEncode(payload), flush: true);
  }

  ActionResult get _saved => const ActionResult(
        ActionOutcome.saved,
        'Guardado en este teléfono. No se envió ningún mensaje.',
      );

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
  Future<TrustCircleSnapshot> load() async {
    await _ensureLoaded();
    return TrustCircleSnapshot(
      contacts: List.unmodifiable(_contacts),
      refugeRequests: List.unmodifiable(_requests),
      alertPreferences: _prefs,
      checkIn: _checkIn,
      hasKeyword: _keyword != null,
      setupComplete: _setupComplete,
    );
  }

  @override
  Future<ActionResult> completeSetup() async {
    await _ensureLoaded();
    _setupComplete = true;
    await _persist();
    return const ActionResult(
      ActionOutcome.saved,
      'Listo. Ya puedes agregar contactos de confianza.',
    );
  }

  @override
  Future<ActionResult> addContact({
    required String name,
    required String phone,
  }) async {
    await _ensureLoaded();
    final cleanName = name.trim();
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (cleanName.isEmpty || digits.length < 6) {
      return const ActionResult(
        ActionOutcome.rejected,
        'Revisa el nombre y el número: faltan datos.',
      );
    }
    final normalized = phone.trim();
    for (final c in _contacts) {
      if (c.phone.replaceAll(RegExp(r'\D'), '') == digits) {
        return const ActionResult(
          ActionOutcome.rejected,
          'Ese número ya está en tu red.',
        );
      }
    }
    _contacts = [
      ..._contacts,
      TrustContact(id: 'c${_nextId++}', name: cleanName, phone: normalized),
    ];
    await _persist();
    return const ActionResult(
      ActionOutcome.saved,
      'Contacto agregado en este teléfono. No se envió ningún mensaje. '
      'Avisa a esa persona: puede recibir SMS o WhatsApp desde tu celular.',
    );
  }

  @override
  Future<ActionResult> inviteToInstall(String contactId) async {
    await _ensureLoaded();
    final contact = _find(contactId);
    if (contact == null || contact.hasApp) {
      return const ActionResult(
        ActionOutcome.rejected,
        'Este contacto ya tiene la app o no existe.',
      );
    }
    _replace(contactId, (c) => c.copyWith(installInvitePending: true));
    await _persist();
    final uri = Uri.parse(
      'https://wa.me/${contact.phone.replaceAll(RegExp(r'\D'), '')}'
      '?text=${Uri.encodeComponent('Te comparto QHAWIX, por si quieres instalarla.')}',
    );
    final opened = await _launchUri(uri);
    return ActionResult(
      ActionOutcome.saved,
      opened
          ? 'Se abrió WhatsApp con un mensaje para que lo envíes tú. '
              'QHAWIX no envía invitaciones desde el servidor.'
          : 'Marcado como pendiente de instalar. No se pudo abrir WhatsApp.',
    );
  }

  @override
  Future<ActionResult> updatePermissions(
    String contactId,
    ContactPermissions permissions,
  ) async {
    await _ensureLoaded();
    final contact = _find(contactId);
    final violation = contact?.permissionViolation(permissions);
    if (violation != null) {
      return ActionResult(ActionOutcome.rejected, violation);
    }
    _replace(contactId, (c) => c.copyWith(permissions: permissions));
    await _persist();
    return _saved;
  }

  @override
  Future<ActionResult> setContactChannel(
    String contactId,
    AlertChannel channel,
  ) async {
    await _ensureLoaded();
    final violation = _find(contactId)?.channelViolation(channel);
    if (violation != null || channel == AlertChannel.push) {
      return ActionResult(
        ActionOutcome.rejected,
        violation ?? 'Las notificaciones push siempre van primero.',
      );
    }
    _replace(contactId, (c) => c.copyWith(channel: channel));
    await _persist();
    return _saved;
  }

  @override
  Future<ActionResult> setContactPaused(
    String contactId, {
    required bool paused,
  }) async {
    await _ensureLoaded();
    _replace(
      contactId,
      (c) => c.copyWith(
        status: paused ? ContactStatus.paused : ContactStatus.active,
      ),
    );
    await _persist();
    return _saved;
  }

  @override
  Future<ActionResult> removeContact(String contactId) async {
    await _ensureLoaded();
    _contacts = [
      for (final c in _contacts)
        if (c.id != contactId) c,
    ];
    _prefs = _prefs.without(contactId);
    await _persist();
    return const ActionResult(
      ActionOutcome.saved,
      'Se quitó el contacto de este teléfono. No se avisó a nadie.',
    );
  }

  @override
  Future<ActionResult> setAlertRecipients(
    AlertEventKind kind,
    Set<String> contactIds,
  ) async {
    await _ensureLoaded();
    _prefs = _prefs.withRecipients(kind, contactIds);
    await _persist();
    return _saved;
  }

  @override
  Future<ActionResult> setAlertFallback(AlertChannelChoice choice) async {
    await _ensureLoaded();
    _prefs = _prefs.withFallback(choice);
    await _persist();
    return _saved;
  }

  @override
  Future<ActionResult> sendSos({
    required Set<String> contactIds,
    required SosDuration duration,
  }) async {
    await _ensureLoaded();
    if (contactIds.isEmpty) {
      return const ActionResult(
        ActionOutcome.rejected,
        'Elige al menos un contacto.',
      );
    }
    final targets = [
      for (final id in contactIds) ?_find(id),
    ];
    if (targets.isEmpty) {
      return const ActionResult(
        ActionOutcome.rejected,
        'No hay contactos válidos seleccionados.',
      );
    }
    final first = targets.first;
    final body = 'SOS QHAWIX: necesito ayuda. '
        'Ubicación temporal por ${duration.minutes} min (envíala tú si quieres).';
    final digits = first.phone.replaceAll(RegExp(r'\D'), '');
    final uri = first.channel == AlertChannel.whatsapp
        ? Uri.parse(
            'https://wa.me/$digits?text=${Uri.encodeComponent(body)}',
          )
        : Uri(scheme: 'sms', path: digits, queryParameters: {'body': body});
    final opened = await _launchUri(uri);
    return ActionResult(
      ActionOutcome.saved,
      opened
          ? 'Se abrió tu app de mensajes con el texto listo. '
              'Debes enviarlo tú. QHAWIX no garantiza una respuesta de emergencia.'
          : 'No se pudo abrir la app de mensajes. Prueba escribirles tú.',
    );
  }

  @override
  Future<ActionResult> startCheckIn(CheckInWindow window) async {
    await _ensureLoaded();
    final now = _clock.now();
    _checkIn = CheckIn(startedAt: now, dueAt: now.add(window.duration));
    await _persist();
    return const ActionResult(
      ActionOutcome.saved,
      'Ventana de llegada guardada en este teléfono. '
      'Aún no se avisa a nadie si vence (falta el envío real).',
    );
  }

  @override
  Future<ActionResult> confirmCheckIn() async {
    await _ensureLoaded();
    final current = _checkIn;
    if (current != null) _checkIn = current.confirm(_clock.now());
    await _persist();
    return const ActionResult(
      ActionOutcome.saved,
      'Llegada marcada en este teléfono. No se avisó a nadie automáticamente.',
    );
  }

  @override
  Future<ActionResult> cancelCheckIn() async {
    await _ensureLoaded();
    _checkIn = null;
    await _persist();
    return _saved;
  }

  @override
  Future<ActionResult> resolveRefugeRequest(
    String requestId, {
    required bool approve,
  }) async {
    await _ensureLoaded();
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
    await _persist();
    return ActionResult(
      ActionOutcome.saved,
      approve
          ? 'Registrado en este teléfono. La activación remota de Refugio '
              'aún no está conectada al servidor.'
          : 'Solicitud rechazada en este teléfono.',
    );
  }

  @override
  Future<String?> readKeyword() async {
    await _ensureLoaded();
    return _keyword;
  }

  @override
  Future<ActionResult> saveKeyword(String keyword) async {
    await _ensureLoaded();
    final clean = keyword.trim();
    if (clean.length < 4) {
      return const ActionResult(
        ActionOutcome.rejected,
        'La palabra debe tener al menos 4 caracteres.',
      );
    }
    _keyword = clean;
    await _persist();
    return const ActionResult(
      ActionOutcome.saved,
      'Palabra guardada solo en este teléfono. No se compartió con nadie.',
    );
  }
}
