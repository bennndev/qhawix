import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

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
                  : 'Señal estimada de audio sintético: ${(_voiceOriginScore! * 100).round()}%')
            : 'La revisión de origen de voz no está disponible.';
      });
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
          }
        });
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

  Color get _riskColor => switch (_tier) {
    'red' => Colors.red,
    'amber' => Colors.orange,
    _ => Colors.green,
  };

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

  Widget _riskSummary() => Card(
    color: _riskColor.withValues(alpha: .11),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(Icons.shield_outlined, color: _riskColor, size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _tier == 'red'
                      ? 'Señal de riesgo alta'
                      : _tier == 'amber'
                      ? 'Señal de precaución'
                      : 'Análisis activo',
                  style: TextStyle(
                    color: _riskColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(_status),
              ],
            ),
          ),
        ],
      ),
    ),
  );

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

  Widget _sourcesPanel() => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.travel_explore),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Fuentes públicas',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (_intelligenceLoading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _intelligenceLoading
                ? 'Buscando alertas y canales oficiales…'
                : _intelligenceSummary.isEmpty
                ? 'La búsqueda se inicia si la conversación presenta señales de riesgo.'
                : _intelligenceSummary,
          ),
          for (final source in _intelligenceSources)
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: const Icon(Icons.open_in_new, size: 18),
              title: Text(source['title'] as String? ?? 'Fuente oficial'),
              subtitle: Text(
                [
                  if (source['excerpt'] is String) source['excerpt'] as String,
                  if (source['url'] is String) source['url'] as String,
                ].join('\n'),
              ),
              onTap: source['url'] is String
                  ? () => _openOfficialSource(source['url'] as String)
                  : null,
            ),
          Text(
            'Una alerta o noticia no demuestra que la persona que llama esté implicada. Si no aparece un resultado, eso tampoco confirma que sea legítima.',
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    ),
  );

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
              Row(
                children: [
                  Icon(Icons.graphic_eq, size: 19),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _voiceOriginStatus ??
                          'Origen de voz: todavía no revisado',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'TruthScan entrega una estimación experimental de audio sintético. No reconoce la identidad, no determina si es una estafa y no sirve como prueba.',
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

  @override
  Widget build(BuildContext context) {
    final inCall = _incoming != null || _callId != null;
    final page = _selectedTab == 1
        ? _contactsBody()
        : _selectedTab == 2
        ? _protectionBody()
        : _dialerBody();
    return Scaffold(
      appBar: AppBar(
        title: const Text('EchoTrap'),
        automaticallyImplyLeading: false,
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
    );
  }
}
