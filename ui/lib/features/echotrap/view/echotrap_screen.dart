import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:provider/provider.dart';

import '../../../core/theme/theme_extensions.dart';
import '../../../core/timeouts.dart';
import '../../trust_circle/domain/alert_preferences.dart';
import '../../trust_circle/domain/trust_circle_repository.dart';
import '../../trust_circle/domain/trust_contact.dart';
import '../data/scam_alert_sms.dart';
import '../domain/scam_response.dart';
import '../domain/voice_origin_level.dart';

const _phoneBridge = MethodChannel('pe.qhawix.qhawix/echotrap');

class EchoTrapScreen extends StatefulWidget {
  const EchoTrapScreen({super.key});
  @override
  State<EchoTrapScreen> createState() => _EchoTrapScreenState();
}

class _EchoTrapScreenState extends State<EchoTrapScreen> {
  final _myPhone = TextEditingController();
  final _targetPhone = TextEditingController();
  final _contactSearch = TextEditingController();
  final _db = Supabase.instance.client;
  RealtimeChannel? _incomingChannel;
  RealtimeChannel? _callChannel;
  Map<String, dynamic>? _incoming;
  String? _callId;
  String? _analysisCallId;
  String _status = 'Listo para llamar';
  String _tier = 'green';
  String _transcript = '';
  String? _voiceOriginStatus;
  double? _voiceOriginScore;
  List<String> _reasons = const [];
  bool _scamResponseTriggered = false;
  String? _contactsAlertStatus;
  String? _callerNotice;
  String? _savedPhone;
  String _intelligenceSummary = '';
  List<Map<String, dynamic>> _intelligenceSources = const [];
  bool _isCallee = false;
  bool _busy = false;
  bool _consentAnalysis = false;
  bool _joiningRoom = false;
  bool _intelligenceLoading = false;
  bool _intelligenceRequested = false;
  bool _muted = false;
  int _selectedTab = 0;
  bool _loadingContacts = false;
  bool _contactsPermissionGranted = false;
  String? _contactsError;
  String? _selectedContactName;
  String? _selectedContactNumber;
  List<Map<String, String>> _deviceContacts = const [];
  Room? _room;
  EventsListener<RoomEvent>? _roomListener;
  Future<void> Function()? _removeAudioRenderer;
  final List<int> _pendingPcm = [];
  final List<int> _voiceSamplePcm = [];
  String _transcriptContext = '';
  int _sequence = 0;
  bool _sendingChunk = false;
  bool _voiceScanRequested = false;

  @override
  void initState() {
    super.initState();
    _loadProfileAndListen();
  }

  Future<void> _loadProfileAndListen() async {
    final user = _db.auth.currentUser;
    if (user == null) return;
    try {
      await _db.functions.invoke('call-control', body: {'action': 'expire'});
    } catch (_) {
      // A missed-call cleanup failure must not hide current profile or calls.
    }
    final profile = await _db
        .from('profiles')
        .select('phone_e164')
        .eq('id', user.id)
        .maybeSingle();
    if (profile?['phone_e164'] is String) {
      final phone = profile!['phone_e164'] as String;
      if (mounted) {
        setState(() {
          _myPhone.text = phone;
          _savedPhone = phone;
        });
      }
    }
    final channel = _db.channel('incoming-${user.id}');
    channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'qhawix_calls',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'callee_id',
        value: user.id,
      ),
      callback: (payload) {
        final row = Map<String, dynamic>.from(payload.newRecord);
        if (row['status'] == 'ringing' && mounted) {
          setState(() => _incoming = row);
        }
      },
    );
    _incomingChannel = channel;
    channel.subscribe();
    // La suscripción recibe llamadas nuevas; esta consulta recupera las que ya
    // estaban sonando cuando el usuario abrió Qhawix.
    try {
      final pending = await _db
          .from('qhawix_calls')
          .select('id, caller_id, callee_id, room_name, status, created_at')
          .eq('callee_id', user.id)
          .eq('status', 'ringing')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      if (pending != null && mounted && _incoming == null) {
        setState(() => _incoming = Map<String, dynamic>.from(pending));
      }
    } catch (_) {
      // La llamada seguirá apareciendo por Realtime si la conexión se recupera.
    }
  }

  Future<void> _showContacts() async {
    setState(() => _selectedTab = 1);
    await _loadDeviceContacts(requestPermission: true);
  }

  Future<void> _loadDeviceContacts({bool requestPermission = false}) async {
    if (_loadingContacts) return;
    setState(() {
      _loadingContacts = true;
      _contactsError = null;
    });
    try {
      var permission = await Permission.contacts.status;
      if (requestPermission && !permission.isGranted) {
        permission = await Permission.contacts.request();
      }
      if (!permission.isGranted) {
        if (mounted) {
          setState(() {
            _contactsPermissionGranted = false;
            _contactsError = permission.isPermanentlyDenied
                ? 'El permiso está desactivado. Ábrelo en Ajustes para mostrar tu agenda.'
                : 'Permite el acceso para ver tus contactos en EchoTrap.';
          });
        }
        return;
      }
      final rows = await _phoneBridge.invokeListMethod<Object?>(
        'loadDeviceContacts',
      );
      final contacts = (rows ?? const <Object?>[])
          .whereType<Map>()
          .map(
            (row) => <String, String>{
              'name': row['name']?.toString() ?? '',
              'phone': row['phone']?.toString() ?? '',
            },
          )
          .where((row) => row['name']!.isNotEmpty && row['phone']!.isNotEmpty)
          .toList(growable: false);
      if (mounted) {
        setState(() {
          _contactsPermissionGranted = true;
          _deviceContacts = contacts;
        });
      }
    } on PlatformException catch (error) {
      if (mounted) {
        setState(() {
          _contactsError =
              error.message ?? 'No se pudieron cargar tus contactos.';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _contactsError = 'No se pudieron cargar tus contactos.');
      }
    } finally {
      if (mounted) setState(() => _loadingContacts = false);
    }
  }

  Future<void> _requestContactsSettings() async {
    await openAppSettings();
  }

  void _selectContact(Map<String, String> contact) {
    final name = contact['name'] ?? '';
    final phone = contact['phone'] ?? '';
    setState(() {
      _targetPhone.text = phone;
      _selectedContactName = name;
      _selectedContactNumber = phone;
      _selectedTab = 0;
    });
    if (!RegExp(r'^\+[1-9][0-9]{7,14}$').hasMatch(phone)) {
      _notice('Revisa el prefijo internacional del número antes de llamar.');
    }
  }

  Future<void> _savePhone() async {
    final phone = _myPhone.text.trim();
    if (!RegExp(r'^\+[1-9][0-9]{7,14}$').hasMatch(phone)) {
      _notice(
        'Escribe el número con código de país, por ejemplo +51987654321.',
      );
      return;
    }
    try {
      await _db
          .from('profiles')
          .update({'phone_e164': phone})
          .eq('id', _db.auth.currentUser!.id);
      setState(() => _savedPhone = phone);
      _notice('Tu número quedó guardado para recibir llamadas Qhawix.');
    } catch (_) {
      _notice('No se pudo guardar. Quizá ese número ya está registrado.');
    }
  }

  Future<void> _startCall() async {
    if (_savedPhone == null || _savedPhone != _myPhone.text.trim()) {
      _notice('Guarda primero tu número para recibir llamadas.');
      return;
    }
    if (!_consentAnalysis) {
      _notice(
        'Confirma primero que entiendes cómo se usa el audio para el análisis.',
      );
      return;
    }
    final phone = _targetPhone.text.trim();
    if (!RegExp(r'^\+[1-9][0-9]{7,14}$').hasMatch(phone)) {
      _notice('Escribe el número con + y código de país.');
      return;
    }
    setState(() {
      _busy = true;
      _status = 'Llamando…';
      _tier = 'green';
      _transcript = '';
      _transcriptContext = '';
      _isCallee = false;
      _intelligenceSummary = '';
      _intelligenceSources = const [];
      _intelligenceRequested = false;
    });
    try {
      final result = await _db.functions.invoke(
        'call-control',
        body: {'action': 'start', 'phone': phone},
      );
      final data = Map<String, dynamic>.from(result.data as Map);
      _setCallId(data['call_id'] as String);
      setState(
        () => _status = 'Llamando a ${data['callee_name'] ?? 'Qhawix'}…',
      );
    } on FunctionException catch (e) {
      _notice(_friendlyError(e.details));
      setState(() => _status = 'No se pudo iniciar');
    } catch (_) {
      _notice('No se pudo iniciar la llamada.');
      setState(() => _status = 'No se pudo iniciar');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _setCallId(String id) {
    _callId = id;
    final channel = _db.channel('call-$id');
    channel.onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'qhawix_calls',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'id',
        value: id,
      ),
      callback: (payload) {
        final row = Map<String, dynamic>.from(payload.newRecord);
        final status = row['status'];
        if (status == 'active' && !_isCallee && _room == null) {
          unawaited(_joinCall(id));
        }
        if ((status == 'ended' || status == 'rejected' || status == 'missed') &&
            mounted) {
          setState(() {
            _status = status == 'rejected'
                ? 'La llamada fue rechazada'
                : 'La llamada terminó';
            _callId = null;
            _incoming = null;
            _tier = 'green';
          });
          unawaited(_leaveRoom(notify: false));
        }
      },
    );
    _callChannel = channel;
    channel.subscribe();
    // Recupera el estado por si la otra persona contestó antes de que
    // Realtime terminara de suscribirse en este teléfono.
    unawaited(_syncCallState(id));
  }

  Future<void> _syncCallState(String id) async {
    try {
      final call = await _db
          .from('qhawix_calls')
          .select('status')
          .eq('id', id)
          .maybeSingle();
      if (!mounted || _callId != id || call == null) return;
      if (call['status'] == 'active' && !_isCallee && _room == null) {
        unawaited(_joinCall(id));
      }
      if (call['status'] == 'rejected' ||
          call['status'] == 'ended' ||
          call['status'] == 'missed') {
        setState(() {
          _status = call['status'] == 'rejected'
              ? 'La llamada fue rechazada'
              : 'La llamada terminó';
          _callId = null;
          _incoming = null;
          _tier = 'green';
        });
        unawaited(_leaveRoom(notify: false));
      }
    } catch (_) {
      // Realtime mantiene el flujo si la consulta de recuperación falla.
    }
  }

  Future<void> _answerIncoming() async {
    if (!_consentAnalysis) {
      _notice(
        'Confirma primero que entiendes cómo se usa el audio para el análisis.',
      );
      return;
    }
    final incoming = _incoming;
    if (incoming == null) return;
    final id = incoming['id'] as String;
    _isCallee = true;
    _transcriptContext = '';
    _intelligenceSummary = '';
    _intelligenceSources = const [];
    _intelligenceRequested = false;
    setState(() {
      _incoming = null;
      _callId = id;
      _status = 'Contestando…';
    });
    _setCallId(id);
    try {
      await _db.functions.invoke(
        'call-control',
        body: {'action': 'accept', 'call_id': id},
      );
      await _joinCall(id);
    } catch (_) {
      _notice('No se pudo contestar.');
      setState(() {
        _status = 'No se pudo contestar';
        _callId = null;
        _isCallee = false;
      });
    }
  }

  Future<void> _rejectIncoming() async {
    final incoming = _incoming;
    if (incoming == null) return;
    setState(() => _incoming = null);
    try {
      await _db.functions.invoke(
        'call-control',
        body: {'action': 'reject', 'call_id': incoming['id']},
      );
    } catch (_) {
      _notice('No se pudo rechazar la llamada.');
    }
  }

  Future<void> _joinCall(String id) async {
    if (_room != null || _joiningRoom) return;
    _joiningRoom = true;
    setState(() => _status = 'Conectando audio…');
    try {
      final response = await _db.functions.invoke(
        'call-control',
        body: {'action': 'token', 'call_id': id},
      );
      final data = Map<String, dynamic>.from(response.data as Map);
      _analysisCallId = data['analysis_call_id'] as String;
      final room = Room();
      final listener = room.createListener();
      listener.on<TrackSubscribedEvent>((event) {
        if (_isCallee && event.track is RemoteAudioTrack) {
          _listenToCaller(event.track as RemoteAudioTrack);
        }
      });
      listener.on<DataReceivedEvent>((event) {
        // Only the person being called can warn the caller.
        if (_isCallee || event.topic != ScamNotice.topic) return;
        final notice = ScamNotice.tryParse(event.data);
        if (notice == null) return;
        if (mounted) setState(() => _callerNotice = notice.spokenText);
        unawaited(
          _phoneBridge
              .invokeMethod<void>('speakWarning', {'text': notice.spokenText})
              .catchError((_) {}),
        );
      });
      _room = room;
      _roomListener = listener;
      await room.connect(data['url'] as String, data['token'] as String);
      await room.localParticipant?.setMicrophoneEnabled(true);
      if (mounted) {
        setState(
          () => _status =
              'Llamada conectada${_isCallee ? ' · Qhawix analiza la voz entrante' : ''}',
        );
      }
    } on FunctionException catch (error) {
      final message = _friendlyError(error.details);
      await _leaveRoom(notify: true);
      if (mounted) {
        setState(() => _status = message);
      }
      _notice(message);
    } catch (_) {
      await _leaveRoom(notify: true);
      if (mounted) {
        setState(() => _status = 'No se pudo conectar el audio');
      }
      _notice(
        'No se pudo conectar el audio de Qhawix. Revisa el servidor de voz y la conexión.',
      );
    } finally {
      _joiningRoom = false;
    }
  }

  void _listenToCaller(RemoteAudioTrack track) {
    if (_removeAudioRenderer != null) return;
    _removeAudioRenderer = track.addAudioRenderer(
      options: const AudioRendererOptions(
        sampleRate: 24000,
        channels: 1,
        format: AudioFormat.Int16,
      ),
      onFrame: (frame) {
        if (!_isCallee || frame.format != AudioFormat.Int16) return;
        _pendingPcm.addAll(frame.data);
        if (!_voiceScanRequested) {
          _voiceSamplePcm.addAll(frame.data);
          const voiceSampleBytes = 24000 * 2 * 10;
          if (_voiceSamplePcm.length >= voiceSampleBytes) {
            _voiceScanRequested = true;
            final sample = Uint8List.fromList(
              _voiceSamplePcm.sublist(0, voiceSampleBytes),
            );
            unawaited(_checkVoiceOrigin(sample));
          }
        }
        const chunkBytes = 24000 * 2 * 4;
        if (_pendingPcm.length >= chunkBytes && !_sendingChunk) {
          final pcm = Uint8List.fromList(_pendingPcm.sublist(0, chunkBytes));
          _pendingPcm.removeRange(0, chunkBytes);
          unawaited(_transcribeChunk(pcm));
        }
      },
    );
  }

  /// Red call: warn the caller out loud and warn the trusted contacts, once.
  void _maybeRespondToScam() {
    if (!_isCallee || _scamResponseTriggered || _effectiveTier != 'red') {
      return;
    }
    _scamResponseTriggered = true;
    unawaited(_respondToScam());
  }

  Future<void> _respondToScam() async {
    final warned = await _alertTrustedContacts().timeout(
      AppTimeouts.echoTrapContactAlert,
      onTimeout: () => 0,
    );
    try {
      await _room?.localParticipant?.publishData(
        ScamNotice(reported: warned > 0).encode(),
        reliable: true,
        topic: ScamNotice.topic,
      );
    } catch (_) {
      // The warning to the caller is best effort; the alert to contacts stands.
    }
  }

  /// Sends a real SMS to the contacts chosen for this event (all active
  /// contacts when none was chosen). Returns how many were sent.
  Future<int> _alertTrustedContacts() async {
    String? status;
    var sent = 0;
    try {
      final snapshot = await context.read<TrustCircleRepository>().load();
      final chosen = snapshot.alertPreferences.recipientsOf(
        AlertEventKind.voiceCloneDetected,
      );
      final phones = [
        for (final contact in snapshot.contacts)
          if (contact.status == ContactStatus.active &&
              contact.permissions.receiveAlerts &&
              (chosen.isEmpty || chosen.contains(contact.id)))
            contact.phone,
      ];
      if (phones.isEmpty) {
        status =
            'No hay contactos de confianza activos. Agrégalos en Red para que se les avise.';
      } else if (!await const ScamAlertSms().ensurePermission()) {
        status =
            'No se avisó a tus contactos: falta el permiso de SMS. Actívalo en Ajustes.';
      } else {
        sent = await const ScamAlertSms().sendAll(phones, scamAlertSmsText);
        status = sent == 0
            ? 'No se pudo enviar el SMS a tus contactos.'
            : sent == 1
            ? 'Se avisó por SMS a 1 contacto de confianza.'
            : 'Se avisó por SMS a $sent contactos de confianza.';
      }
    } catch (_) {
      status = 'No se pudo avisar a tus contactos de confianza.';
    }
    if (mounted) setState(() => _contactsAlertStatus = status);
    return sent;
  }

  Future<void> _checkVoiceOrigin(Uint8List pcm) async {
    final callId = _callId;
    if (callId == null) return;
    if (mounted) {
      setState(() => _voiceOriginStatus = 'Revisando una muestra de audio…');
    }
    try {
      final result = await _db.functions.invoke(
        'voice-origin',
        body: {'call_id': callId, 'audio': base64Encode(_wrapWav(pcm, 24000))},
      );
      final data = Map<String, dynamic>.from(result.data as Map);
      if (!mounted) return;
      setState(() {
        _voiceOriginScore = data['score'] is num
            ? (data['score'] as num).toDouble()
            : null;
        _voiceOriginStatus =
            data['available'] == true && data['status'] == 'done'
            ? (_voiceOriginScore == null
                  ? 'No se obtuvo un resultado concluyente.'
                  : 'Voz: ${voiceOriginPercent(_voiceOriginScore!)}% de señal sintética')
            : 'La revisión de origen de voz no está disponible.';
      });
      _maybeRespondToScam();
    } catch (_) {
      if (mounted) {
        setState(
          () => _voiceOriginStatus =
              'La revisión de origen de voz no está disponible.',
        );
      }
    }
  }

  Future<void> _transcribeChunk(Uint8List pcm) async {
    if (_sendingChunk || _analysisCallId == null || !_isCallee) return;
    _sendingChunk = true;
    try {
      _sequence++;
      final wav = _wrapWav(pcm, 24000);
      final result = await _db.functions.invoke(
        'transcribe',
        body: {
          'call_id': _analysisCallId,
          'seq': _sequence,
          'mime': 'audio/wav',
          'audio': base64Encode(wav),
          'context': _transcriptContext,
        },
      );
      final data = Map<String, dynamic>.from(result.data as Map);
      final text = (data['text'] as String?)?.trim() ?? '';
      final verdict = data['verdict'];
      if (text.isEmpty) {
        final degraded = data['degraded'];
        if (mounted && degraded is List && degraded.contains('stt')) {
          setState(
            () => _status =
                'Llamada conectada · no se pudo transcribir este tramo',
          );
        }
        return;
      }
      _transcriptContext = '$_transcriptContext\nLLAMANTE: $text'.trim();
      if (_transcriptContext.length > 6000) {
        _transcriptContext = _transcriptContext.substring(
          _transcriptContext.length - 6000,
        );
      }
      if (mounted && text.isNotEmpty) {
        setState(() {
          _transcript = text;
          _status = data['transcription_provider'] == 'gemini'
              ? 'Llamada conectada · transcripción de respaldo activa'
              : 'Llamada conectada · análisis en vivo';
          if (verdict is Map && verdict['tier'] is String) {
            _tier = verdict['tier'] as String;
            _reasons = (verdict['reasons'] as List? ?? const [])
                .whereType<String>()
                .map((reason) => reason.trim())
                .where((reason) => reason.isNotEmpty)
                .toList(growable: false);
          }
        });
        _maybeRespondToScam();
        final tier = verdict is Map ? verdict['tier'] : null;
        final callId = _callId;
        if ((tier == 'amber' || tier == 'red') &&
            callId != null &&
            !_intelligenceRequested) {
          _intelligenceRequested = true;
          unawaited(
            _loadCallIntelligence(
              callId,
              _transcriptContext.length > 1200
                  ? _transcriptContext.substring(
                      _transcriptContext.length - 1200,
                    )
                  : _transcriptContext,
            ),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _status =
              'Llamada conectada · análisis temporalmente no disponible',
        );
      }
    } finally {
      _sendingChunk = false;
    }
  }

  Future<void> _loadCallIntelligence(String callId, String transcript) async {
    setState(() => _intelligenceLoading = true);
    try {
      final response = await _db.functions.invoke(
        'call-intelligence',
        body: {'qhawix_call_id': callId, 'transcript': transcript},
      );
      final data = Map<String, dynamic>.from(response.data as Map);
      final sources = (data['sources'] as List? ?? const [])
          .whereType<Map>()
          .map((source) => Map<String, dynamic>.from(source))
          .toList(growable: false);
      if (!mounted) return;
      setState(() {
        _intelligenceSummary = data['summary'] as String? ?? '';
        _intelligenceSources = sources;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _intelligenceSummary =
              'La consulta web no respondió. Verifica siempre por el canal oficial de la entidad.';
        });
      }
    } finally {
      if (mounted) setState(() => _intelligenceLoading = false);
    }
  }

  void _appendDialDigit(String digit) {
    if (_targetPhone.text.length >= 16) return;
    setState(() {
      _targetPhone.text += digit;
      _selectedContactName = null;
      _selectedContactNumber = null;
    });
  }

  void _removeDialDigit() {
    final value = _targetPhone.text;
    if (value.isEmpty) return;
    setState(() {
      _targetPhone.text = value.substring(0, value.length - 1);
      _selectedContactName = null;
      _selectedContactNumber = null;
    });
  }

  Future<void> _toggleMute() async {
    final enabled = !_muted;
    try {
      await _room?.localParticipant?.setMicrophoneEnabled(!enabled);
      if (mounted) setState(() => _muted = enabled);
    } catch (_) {
      _notice('No se pudo cambiar el micrófono.');
    }
  }

  Uint8List _wrapWav(Uint8List pcm, int rate) {
    final bytes = ByteData(44 + pcm.length);
    void tag(String text, int offset) {
      for (var i = 0; i < text.length; i++) {
        bytes.setUint8(offset + i, text.codeUnitAt(i));
      }
    }

    tag('RIFF', 0);
    bytes.setUint32(4, 36 + pcm.length, Endian.little);
    tag('WAVE', 8);
    tag('fmt ', 12);
    bytes.setUint32(16, 16, Endian.little);
    bytes.setUint16(20, 1, Endian.little);
    bytes.setUint16(22, 1, Endian.little);
    bytes.setUint32(24, rate, Endian.little);
    bytes.setUint32(28, rate * 2, Endian.little);
    bytes.setUint16(32, 2, Endian.little);
    bytes.setUint16(34, 16, Endian.little);
    tag('data', 36);
    bytes.setUint32(40, pcm.length, Endian.little);
    bytes.buffer.asUint8List().setRange(44, 44 + pcm.length, pcm);
    return bytes.buffer.asUint8List();
  }

  Future<void> _leaveRoom({bool notify = true}) async {
    final id = _callId;
    final room = _room;
    _room = null;
    await _removeAudioRenderer?.call();
    _removeAudioRenderer = null;
    await _roomListener?.dispose();
    _roomListener = null;
    await room?.disconnect();
    _pendingPcm.clear();
    _voiceSamplePcm.clear();
    _transcriptContext = '';
    _voiceScanRequested = false;
    _voiceOriginScore = null;
    _voiceOriginStatus = null;
    _reasons = const [];
    _scamResponseTriggered = false;
    _contactsAlertStatus = null;
    _callerNotice = null;
    _analysisCallId = null;
    _muted = false;
    if (notify && id != null) {
      try {
        await _db.functions.invoke(
          'call-control',
          body: {'action': 'end', 'call_id': id},
        );
      } catch (_) {
        _notice('Se cerró el audio; no se pudo actualizar el estado remoto.');
      }
    }
    if (mounted && notify) {
      setState(() {
        _status = 'Llamada terminada';
        _callId = null;
        _tier = 'green';
      });
    }
  }

  void _notice(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  String _friendlyError(dynamic error) {
    if (error is Map) {
      switch (error['error']) {
        case 'user_not_found':
          return 'Ese número todavía no tiene una cuenta Qhawix.';
        case 'voice_service_not_configured':
          return 'El servidor de voz de Qhawix todavía no está configurado.';
        case 'cannot_call_self':
          return 'No puedes llamarte a ti mismo.';
      }
    }
    return 'No se pudo completar la solicitud.';
  }

  VoiceOriginLevel? get _voiceLevel {
    final score = _voiceOriginScore;
    return score == null ? null : classifyVoiceOrigin(score);
  }

  /// The call is as risky as its worst signal: what is said or how it sounds.
  String get _effectiveTier {
    if (_tier == 'red' || _voiceLevel == VoiceOriginLevel.synthetic) {
      return 'red';
    }
    if (_tier == 'amber' || _voiceLevel == VoiceOriginLevel.doubtful) {
      return 'amber';
    }
    return 'green';
  }

  Color _tierColor(String tier) {
    final palette = context.riskPalette;
    return switch (tier) {
      'red' => palette.high.foreground,
      'amber' => palette.caution.foreground,
      _ => palette.noneDetected.foreground,
    };
  }

  Color get _riskColor => _tierColor(_effectiveTier);

  /// One short sentence on why the call was flagged.
  String get _shortReason {
    final parts = <String>[];
    if (_voiceLevel == VoiceOriginLevel.synthetic) {
      parts.add('la voz parece generada por IA');
    }
    for (final reason in _reasons) {
      if (parts.length >= 2) break;
      parts.add(
        reason.endsWith('.') ? reason.substring(0, reason.length - 1) : reason,
      );
    }
    if (parts.isEmpty) return '';
    final text = parts.join('; ');
    final trimmed = text.length > 140 ? '${text.substring(0, 137)}…' : text;
    return '${trimmed[0].toUpperCase()}${trimmed.substring(1)}.';
  }

  @override
  void dispose() {
    _myPhone.dispose();
    _targetPhone.dispose();
    _contactSearch.dispose();
    if (_incomingChannel != null) {
      unawaited(_db.removeChannel(_incomingChannel!));
    }
    if (_callChannel != null) {
      unawaited(_db.removeChannel(_callChannel!));
    }
    unawaited(_leaveRoom(notify: false));
    super.dispose();
  }

  Widget _dialKey(String digit, {String letters = ''}) => Material(
    color: Theme.of(context).colorScheme.surfaceContainerLow,
    shape: const CircleBorder(),
    child: InkWell(
      customBorder: const CircleBorder(),
      onTap: () => _appendDialDigit(digit),
      child: SizedBox(
        height: 62,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(digit, style: Theme.of(context).textTheme.headlineSmall),
            if (letters.isNotEmpty)
              Text(
                letters,
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(letterSpacing: 1.4),
              ),
          ],
        ),
      ),
    ),
  );

  Future<void> _openOfficialSource(String rawUrl) async {
    final uri = Uri.tryParse(rawUrl);
    if (uri == null || uri.scheme != 'https') return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      _notice('No se pudo abrir la fuente. Copia el enlace y revísalo luego.');
    }
  }

  /// Shown to the person once the call turned red and the automatic warning ran.
  Widget _autoResponseCard() => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.record_voice_over, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text('Se avisó con voz sintética a quien llama.'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.sms_outlined, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _contactsAlertStatus ?? 'Avisando a tus contactos…',
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  /// TruthScan result: green under 10%, yellow 10-30%, red from 30%.
  Widget _voiceOriginRow() {
    final score = _voiceOriginScore;
    final level = _voiceLevel;
    if (score == null || level == null) {
      return Row(
        children: [
          const Icon(Icons.graphic_eq, size: 19),
          const SizedBox(width: 8),
          Expanded(
            child: Text(_voiceOriginStatus ?? 'Voz: todavía no revisada'),
          ),
        ],
      );
    }
    final percent = voiceOriginPercent(score);
    final (tier, label, icon) = switch (level) {
      VoiceOriginLevel.normal => ('green', 'Voz normal', Icons.check_circle),
      VoiceOriginLevel.doubtful => ('amber', 'Voz dudosa', Icons.help),
      VoiceOriginLevel.synthetic => (
        'red',
        'Posible voz clonada por IA',
        Icons.warning_rounded,
      ),
    };
    final color = _tierColor(tier);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1.2),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.w700),
            ),
          ),
          Text(
            '$percent%',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _riskSummary() {
    final tier = _effectiveTier;
    final headline = switch (tier) {
      'red' => 'Es una estafa',
      'amber' => 'Posible estafa',
      _ => 'Sin señales de estafa',
    };
    final reason = _shortReason;
    return Card(
      color: _riskColor.withValues(alpha: .14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: _riskColor, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              tier == 'green' ? Icons.verified_user_outlined : Icons.gpp_bad,
              color: _riskColor,
              size: 34,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    headline,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: _riskColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (reason.isNotEmpty && tier != 'green') Text(reason),
                  if (tier == 'green') Text(_status),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileNumber() => Card(
    child: ExpansionTile(
      leading: const Icon(Icons.phone_android),
      title: const Text('Mi número Qhawix'),
      subtitle: Text(_savedPhone ?? 'Guárdalo para recibir llamadas'),
      initiallyExpanded: _savedPhone == null,
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      children: [
        TextField(
          controller: _myPhone,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            hintText: '+51987654321',
            helperText:
                'Incluye el código de país. Este número debe ser único.',
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: OutlinedButton.icon(
            onPressed: _savePhone,
            icon: const Icon(Icons.save_outlined),
            label: const Text('Guardar número'),
          ),
        ),
      ],
    ),
  );

  Widget _dialerBody() => ListView(
    padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
    children: [
      _profileNumber(),
      const SizedBox(height: 14),
      Text(
        'Llamar por Qhawix',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      Text(
        'Marca el número de otra persona que ya usa Qhawix.',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _targetPhone,
        keyboardType: TextInputType.phone,
        onChanged: (value) {
          if (value != _selectedContactNumber && _selectedContactName != null) {
            setState(() {
              _selectedContactName = null;
              _selectedContactNumber = null;
            });
          } else {
            setState(() {});
          }
        },
        textAlign: TextAlign.center,
        style: Theme.of(
          context,
        ).textTheme.headlineMedium?.copyWith(letterSpacing: 1.2),
        decoration: InputDecoration(
          hintText: 'Número con código de país',
          suffixIcon: IconButton(
            tooltip: 'Borrar número',
            onPressed: () => setState(() {
              _targetPhone.clear();
              _selectedContactName = null;
              _selectedContactNumber = null;
            }),
            icon: const Icon(Icons.backspace_outlined),
          ),
          border: InputBorder.none,
        ),
      ),
      if (_selectedContactName != null) ...[
        Text(
          _selectedContactName!,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
      ],
      GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 8,
        crossAxisSpacing: 24,
        childAspectRatio: 1.55,
        children: [
          _dialKey('1'),
          _dialKey('2', letters: 'ABC'),
          _dialKey('3', letters: 'DEF'),
          _dialKey('4', letters: 'GHI'),
          _dialKey('5', letters: 'JKL'),
          _dialKey('6', letters: 'MNO'),
          _dialKey('7', letters: 'PQRS'),
          _dialKey('8', letters: 'TUV'),
          _dialKey('9', letters: 'WXYZ'),
          _dialKey('+'),
          _dialKey('0'),
          Material(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _removeDialDigit,
              onLongPress: () => setState(() {
                _targetPhone.clear();
                _selectedContactName = null;
                _selectedContactNumber = null;
              }),
              child: const SizedBox(
                height: 62,
                child: Icon(Icons.backspace_outlined),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Card(
        child: ListTile(
          leading: Icon(
            _consentAnalysis ? Icons.shield : Icons.shield_outlined,
            color: _consentAnalysis ? Colors.green : null,
          ),
          title: Text(
            _consentAnalysis ? 'Protección activada' : 'Activa la protección',
          ),
          subtitle: const Text('Revisa el permiso en la pestaña Protección.'),
          onTap: () => setState(() => _selectedTab = 2),
        ),
      ),
      const SizedBox(height: 4),
      SizedBox(
        height: 54,
        child: FilledButton.icon(
          onPressed:
              _busy ||
                  _callId != null ||
                  !_consentAnalysis ||
                  _savedPhone == null ||
                  _savedPhone != _myPhone.text.trim() ||
                  !RegExp(r'^\+[1-9][0-9]{7,14}$').hasMatch(_targetPhone.text)
              ? null
              : _startCall,
          icon: Icon(_busy ? Icons.hourglass_top : Icons.call),
          label: Text(_busy ? 'Conectando…' : 'Llamar'),
        ),
      ),
      const SizedBox(height: 12),
      Text(
        'Qhawix analiza solo llamadas hechas dentro de la app. No identifica al titular de un número ni certifica quién habla.',
        textAlign: TextAlign.center,
      ),
    ],
  );

  Widget _incomingBody() => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircleAvatar(
            radius: 42,
            child: Icon(Icons.call_received, size: 38),
          ),
          const SizedBox(height: 18),
          Text(
            'Llamada entrante',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 6),
          const Text('Usuario Qhawix'),
          const SizedBox(height: 18),
          CheckboxListTile(
            value: _consentAnalysis,
            onChanged: (value) =>
                setState(() => _consentAnalysis = value ?? false),
            title: const Text('Acepto el análisis de voz'),
            subtitle: const Text(
              'Fragmentos de voz a Deepgram o Gemini de respaldo y una muestra de 10 segundos a TruthScan. QHAWIX no guarda el audio ni la transcripción; no identifica a quien habla.',
            ),
          ),
          const SizedBox(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              FilledButton.tonalIcon(
                onPressed: _rejectIncoming,
                icon: const Icon(Icons.call_end),
                label: const Text('Rechazar'),
              ),
              FilledButton.icon(
                onPressed: _consentAnalysis ? _answerIncoming : null,
                icon: const Icon(Icons.call),
                label: const Text('Contestar'),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _contactsBody() {
    final query = _contactSearch.text.trim().toLowerCase();
    final contacts = _deviceContacts
        .where((contact) {
          if (query.isEmpty) return true;
          return (contact['name'] ?? '').toLowerCase().contains(query) ||
              (contact['phone'] ?? '').toLowerCase().contains(query);
        })
        .toList(growable: false);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
          child: TextField(
            controller: _contactSearch,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Buscar contacto',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                tooltip: 'Actualizar agenda',
                onPressed: _loadingContacts
                    ? null
                    : () => _loadDeviceContacts(requestPermission: true),
                icon: const Icon(Icons.refresh),
              ),
            ),
          ),
        ),
        Expanded(
          child: _loadingContacts
              ? const Center(child: CircularProgressIndicator())
              : !_contactsPermissionGranted
              ? _contactsPermissionPrompt()
              : contacts.isEmpty
              ? Center(
                  child: Text(
                    _deviceContacts.isEmpty
                        ? 'No encontramos números en tu agenda.'
                        : 'No hay contactos que coincidan.',
                  ),
                )
              : ListView.separated(
                  itemCount: contacts.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final contact = contacts[index];
                    final name = contact['name'] ?? 'Contacto';
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(
                          name.trim().isEmpty
                              ? '?'
                              : name.trim()[0].toUpperCase(),
                        ),
                      ),
                      title: Text(name),
                      subtitle: Text(contact['phone'] ?? ''),
                      trailing: const Icon(Icons.call_outlined),
                      onTap: () => _selectContact(contact),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 12),
          child: Text(
            'Tus contactos se leen solo en este teléfono. Al elegir uno, su número se copia al marcador de EchoTrap.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }

  Widget _contactsPermissionPrompt() => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.contacts_outlined, size: 44),
          const SizedBox(height: 12),
          Text(
            _contactsError ?? 'Da permiso para mostrar tu agenda.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed:
                _contactsError?.startsWith('El permiso está desactivado') ==
                    true
                ? _requestContactsSettings
                : () => _loadDeviceContacts(requestPermission: true),
            icon: const Icon(Icons.contacts),
            label: Text(
              _contactsError?.startsWith('El permiso está desactivado') == true
                  ? 'Abrir Ajustes'
                  : 'Permitir contactos',
            ),
          ),
        ],
      ),
    ),
  );

  Widget _protectionBody() => ListView(
    padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
    children: [
      Icon(
        Icons.shield_outlined,
        size: 56,
        color: Theme.of(context).colorScheme.primary,
      ),
      const SizedBox(height: 12),
      Text(
        'Protección EchoTrap',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: 8),
      Text(
        'Analiza llamadas hechas dentro de Qhawix. Para transcribir, procesa fragmentos cortos con Deepgram o Gemini si Deepgram no está disponible. Una muestra de 10 segundos se revisa con TruthScan para estimar señales de audio sintético.',
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 18),
      Card(
        child: CheckboxListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          value: _consentAnalysis,
          onChanged: (value) =>
              setState(() => _consentAnalysis = value ?? false),
          title: const Text('Permitir análisis de voz'),
          subtitle: const Text(
            'El audio se envía desde esta llamada a Deepgram o, como respaldo, a Gemini; una muestra de 10 segundos se envía a TruthScan. QHAWIX no conserva el audio ni la transcripción, solo las alertas de riesgo. Si aparecen señales de riesgo, puede consultar Exa usando solo la entidad mencionada. Informa a la otra persona antes de analizar; estas señales no identifican a alguien ni demuestran una estafa.',
          ),
        ),
      ),
      const SizedBox(height: 12),
      const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'EchoTrap no escucha ni bloquea llamadas normales del operador, WhatsApp u otras aplicaciones. La protección se aplica a llamadas realizadas y contestadas dentro de Qhawix.',
          ),
        ),
      ),
      const SizedBox(height: 8),
      Text(
        'Tus contactos permanecen en el teléfono; solo el número que selecciones se usa para buscar a la cuenta Qhawix correspondiente.',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.labelSmall,
      ),
    ],
  );

  /// Web search kept short: a one-line summary, sources behind a tap.
  Widget _sourcesPanel() {
    if (_intelligenceLoading) {
      return const Card(
        child: ListTile(
          dense: true,
          leading: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          title: Text('Buscando fuentes oficiales…'),
        ),
      );
    }
    if (_intelligenceSummary.isEmpty && _intelligenceSources.isEmpty) {
      return const SizedBox.shrink();
    }
    final firstSentence = _intelligenceSummary
        .split(RegExp(r'(?<=[.!?])\s'))
        .first;
    final summary = firstSentence.length > 120
        ? '${firstSentence.substring(0, 117)}…'
        : firstSentence;
    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.travel_explore),
        title: Text(summary.isEmpty ? 'Fuentes oficiales' : summary),
        subtitle: _intelligenceSources.isEmpty
            ? null
            : Text('${_intelligenceSources.length} fuentes · toca para ver'),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        children: [
          for (final source in _intelligenceSources.take(3))
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: const Icon(Icons.open_in_new, size: 18),
              title: Text(source['title'] as String? ?? 'Fuente oficial'),
              onTap: source['url'] is String
                  ? () => _openOfficialSource(source['url'] as String)
                  : null,
            ),
          Text(
            'Una noticia no demuestra quién llama; su ausencia tampoco confirma que sea legítima.',
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }

  Widget _activeCallBody() => ListView(
    padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
    children: [
      const SizedBox(height: 12),
      CircleAvatar(
        radius: 44,
        backgroundColor: _riskColor.withValues(alpha: .13),
        child: Icon(
          _isCallee ? Icons.shield_outlined : Icons.call_made,
          color: _riskColor,
          size: 42,
        ),
      ),
      const SizedBox(height: 16),
      Text(
        _isCallee ? 'Protección de llamada activa' : 'Llamando por Qhawix',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: 4),
      Text(_status, textAlign: TextAlign.center),
      const SizedBox(height: 18),
      _riskSummary(),
      if (_isCallee && _scamResponseTriggered) _autoResponseCard(),
      if (!_isCallee && _callerNotice != null)
        Card(
          color: context.riskPalette.high.background,
          child: ListTile(
            leading: Icon(
              Icons.record_voice_over,
              color: context.riskPalette.high.foreground,
            ),
            title: Text(
              _callerNotice!,
              style: TextStyle(color: context.riskPalette.high.foreground),
            ),
          ),
        ),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Lo que dice la otra persona',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(_transcript.isEmpty ? 'Esperando voz…' : _transcript),
              const SizedBox(height: 12),
              _voiceOriginRow(),
              const SizedBox(height: 4),
              Text(
                'Estimación experimental de voz sintética. No identifica a la persona ni sirve como prueba.',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ),
      ),
      _sourcesPanel(),
      const SizedBox(height: 12),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FilledButton.tonalIcon(
            onPressed: _toggleMute,
            icon: Icon(_muted ? Icons.mic_off : Icons.mic),
            label: Text(_muted ? 'Micrófono apagado' : 'Silenciar'),
          ),
          const SizedBox(width: 16),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () => _leaveRoom(),
            icon: const Icon(Icons.call_end),
            label: const Text('Terminar'),
          ),
        ],
      ),
    ],
  );

  /// Leaves EchoTrap for the Inicio menu, even when it was opened without a
  /// route underneath (cold start, restored route).
  void _leaveToHome() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/inicio');
    }
  }

  @override
  Widget build(BuildContext context) {
    final inCall = _incoming != null || _callId != null;
    final page = _selectedTab == 1
        ? _contactsBody()
        : _selectedTab == 2
        ? _protectionBody()
        : _dialerBody();
    return PopScope(
      // Never drop out of a live call by accident with the system back.
      canPop: !inCall,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('EchoTrap'),
          automaticallyImplyLeading: false,
          leading: inCall
              ? null
              : IconButton(
                  tooltip: 'Volver al inicio',
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _leaveToHome,
                ),
          actions: [
            if (!inCall)
              IconButton(
                tooltip: 'Cerrar sesión',
                icon: const Icon(Icons.logout),
                onPressed: () => _db.auth.signOut(),
              ),
          ],
        ),
        body: _incoming != null
            ? _incomingBody()
            : _callId != null
            ? _activeCallBody()
            : page,
        bottomNavigationBar: inCall
            ? null
            : NavigationBar(
                selectedIndex: _selectedTab,
                onDestinationSelected: (index) {
                  if (index == 1) {
                    _showContacts();
                  } else {
                    setState(() => _selectedTab = index);
                  }
                },
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.dialpad_outlined),
                    selectedIcon: Icon(Icons.dialpad),
                    label: 'Llamar',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.contacts_outlined),
                    selectedIcon: Icon(Icons.contacts),
                    label: 'Contactos',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.shield_outlined),
                    selectedIcon: Icon(Icons.shield),
                    label: 'Protección',
                  ),
                ],
              ),
      ),
    );
  }
}
