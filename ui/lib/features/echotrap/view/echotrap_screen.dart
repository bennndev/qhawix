import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../domain/echotrap_signal_analyzer.dart';

const _phoneBridge = MethodChannel('pe.qhawix.qhawix/echotrap');
const _audioBridge = EventChannel('pe.qhawix.qhawix/echotrap/audio');
const _previewRequested = bool.fromEnvironment('ECHOTRAP_PREVIEW');

/// EchoTrap stays inside its module. Supabase starts lazily here so the other
/// QHAWIX modules and application startup do not depend on EchoTrap settings.
class EchoTrapScreen extends StatefulWidget {
  const EchoTrapScreen({super.key});

  @override
  State<EchoTrapScreen> createState() => _EchoTrapScreenState();
}

class _EchoTrapScreenState extends State<EchoTrapScreen> {
  bool get _isPreviewMode => kDebugMode && _previewRequested;

  final _email = TextEditingController();
  final _password = TextEditingController();
  final _ownPhone = TextEditingController();
  final _destination = TextEditingController();
  final _contactName = TextEditingController();
  final _contactPhone = TextEditingController();
  final _contactsStorage = const FlutterSecureStorage();
  final List<Map<String, String>> _contacts = [];
  StreamSubscription<Object?>? _audioSubscription;
  SupabaseClient? _client;
  String _number = '';
  String? _message;
  String? _transcript;
  String? _sourceResult;
  List<Map<String, Object?>> _sources = [];
  String _verdict = 'inconclusive';
  double? _syntheticScore;
  Uint8List _voiceBuffer = Uint8List(0);
  bool _loading = true;
  bool _working = false;
  bool _registering = false;
  bool _consent = false;
  bool _sourceSearchConsent = false;
  bool _monitoring = false;
  bool _voiceSubmitted = false;
  bool _screeningEnabled = false;
  bool _officialSearchDone = false;
  bool _warningSpoken = false;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _openEchoTrap();
    _loadContacts();
  }

  Future<void> _openEchoTrap() async {
    const url = String.fromEnvironment('SUPABASE_URL');
    const key = String.fromEnvironment(
      'SUPABASE_PUBLISHABLE_KEY',
      defaultValue: String.fromEnvironment('SUPABASE_ANON_KEY'),
    );
    if (url.isNotEmpty && key.isNotEmpty) {
      try {
        if (!_isSupabaseInitialized) {
          await Supabase.initialize(url: url, publishableKey: key);
        }
        _client = Supabase.instance.client;
        _ownPhone.text =
            _client!.auth.currentUser?.userMetadata?['echotrap_phone']
                as String? ??
            '';
      } catch (error) {
        _message = 'No se pudo conectar con el acceso de EchoTrap: $error';
      }
    } else {
      if (!_isPreviewMode) {
        _message =
            'Falta configurar el acceso de Supabase para EchoTrap en esta instalación.';
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  bool get _isSupabaseInitialized {
    try {
      Supabase.instance.client;
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _loadContacts() async {
    try {
      final raw = await _contactsStorage.read(key: 'echotrap_contacts_v1');
      if (raw != null) {
        final entries = (jsonDecode(raw) as List)
            .whereType<Map>()
            .map(
              (item) => {
                'name': '${item['name'] ?? ''}',
                'phone': '${item['phone'] ?? ''}',
              },
            )
            .toList();
        if (mounted) {
          setState(() {
            _contacts
              ..clear()
              ..addAll(entries);
          });
        }
        await _syncTrustedPhones();
      }
      final active = await _phoneBridge.invokeMethod<bool>(
        'isCallScreeningEnabled',
      );
      if (mounted) setState(() => _screeningEnabled = active ?? false);
    } catch (_) {
      /* Contacts remain usable on devices without call screening. */
    }
  }

  Future<void> _syncTrustedPhones() async {
    try {
      await _phoneBridge.invokeMethod<void>('setTrustedPhones', {
        'phones': _contacts.map((item) => item['phone']).toList(),
      });
    } catch (_) {}
  }

  Future<void> _saveContacts() async {
    await _contactsStorage.write(
      key: 'echotrap_contacts_v1',
      value: jsonEncode(_contacts),
    );
    await _syncTrustedPhones();
    if (mounted) setState(() {});
  }

  Future<void> _addContact() async {
    _contactName.clear();
    _contactPhone.clear();
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Añadir contacto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _contactName,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            TextField(
              controller: _contactPhone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Teléfono con código de país',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (saved != true) return;
    final name = _contactName.text.trim();
    final phone = _contactPhone.text.trim();
    if (name.isEmpty || phone.length < 7) {
      setState(() => _message = 'Revisa el nombre y el teléfono.');
      return;
    }
    _contacts.add({'name': name, 'phone': phone});
    await _saveContacts();
  }

  Future<void> _enableScreening() async {
    await Permission.notification.request();
    try {
      await _phoneBridge.invokeMethod<void>('requestCallScreening');
      final enabled = await _phoneBridge.invokeMethod<bool>(
        'isCallScreeningEnabled',
      );
      if (mounted) {
        setState(() {
          _screeningEnabled = enabled ?? false;
          _message = _screeningEnabled
              ? 'EchoTrap avisará antes de llamadas de números que no guardaste. Las dejará pasar; no puede escucharlas ni contestarlas.'
              : 'No se activó la función de aviso de llamadas.';
        });
      }
    } on PlatformException catch (error) {
      if (mounted) {
        setState(
          () => _message =
              error.message ??
              'Esta versión de Android no ofrece el filtro de llamadas.',
        );
      }
    }
  }

  @override
  void dispose() {
    _audioSubscription?.cancel();
    _phoneBridge.invokeMethod<void>('stopCapture');
    _email.dispose();
    _password.dispose();
    _ownPhone.dispose();
    _destination.dispose();
    super.dispose();
  }

  Future<void> _authenticate() async {
    final client = _client;
    if (client == null) return;
    setState(() {
      _working = true;
      _message = null;
    });
    try {
      if (_registering) {
        await client.auth.signUp(
          email: _email.text.trim(),
          password: _password.text,
        );
        if (client.auth.currentUser == null) {
          _message = 'Cuenta creada. Revisa tu correo y luego inicia sesión.';
        }
      } else {
        await client.auth.signInWithPassword(
          email: _email.text.trim(),
          password: _password.text,
        );
      }
      _ownPhone.text =
          client.auth.currentUser?.userMetadata?['echotrap_phone'] as String? ??
          '';
    } on AuthException catch (error) {
      _message = error.message;
    } catch (_) {
      _message =
          'No se pudo completar el acceso. Revisa tu conexión e inténtalo de nuevo.';
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _savePhone() async {
    final client = _client;
    if (client == null || client.auth.currentUser == null) return;
    final phone = _ownPhone.text.trim();
    if (phone.length < 7) {
      setState(() => _message = 'Escribe un número válido con código de país.');
      return;
    }
    setState(() {
      _working = true;
      _message = null;
    });
    try {
      final metadata = Map<String, dynamic>.from(
        client.auth.currentUser!.userMetadata ?? {},
      );
      metadata['echotrap_phone'] = phone;
      await client.auth.updateUser(UserAttributes(data: metadata));
      setState(
        () => _message = 'Tu número quedó guardado en tu perfil de EchoTrap.',
      );
    } catch (_) {
      setState(
        () => _message = 'No se pudo guardar el número. Vuelve a intentarlo.',
      );
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _dial() async {
    final number = _number.isNotEmpty ? _number : _destination.text.trim();
    if (number.isEmpty) {
      setState(() => _message = 'Ingresa el número al que quieres llamar.');
      return;
    }
    try {
      await _phoneBridge.invokeMethod<void>('dial', {'number': number});
      setState(
        () => _message =
            'Se abrió la app Teléfono. Toca llamar allí. Al responder, vuelve a EchoTrap, activa el altavoz y empieza la protección.',
      );
    } on PlatformException catch (error) {
      setState(
        () => _message = error.message ?? 'No se pudo abrir la app Teléfono.',
      );
    }
  }

  void _appendDigit(String digit) {
    setState(() {
      if (_number.isEmpty && _destination.text.isNotEmpty) {
        _number = _destination.text;
        _destination.clear();
      }
      _number += digit;
    });
  }

  void _deleteDigit() {
    setState(() {
      if (_number.isNotEmpty) {
        _number = _number.substring(0, _number.length - 1);
      } else if (_destination.text.isNotEmpty) {
        _destination.text = _destination.text.substring(
          0,
          _destination.text.length - 1,
        );
      }
    });
  }

  void _selectContact(String phone) {
    setState(() {
      _number = '';
      _destination.text = phone;
      _selectedTab = 0;
    });
  }

  Future<void> _startMonitoring() async {
    if (!_consent) {
      setState(
        () => _message =
            'Confirma el permiso de análisis antes de activar el micrófono.',
      );
      return;
    }
    try {
      final microphone = await Permission.microphone.request();
      if (!microphone.isGranted) {
        setState(
          () => _message =
              'Sin permiso de micrófono no se puede analizar la llamada.',
        );
        return;
      }
      await Permission.notification.request();
      await _phoneBridge.invokeMethod<void>('startCapture');
      _voiceBuffer = Uint8List(0);
      _voiceSubmitted = false;
      _transcript = null;
      _syntheticScore = null;
      _sourceResult = null;
      _sources = [];
      _verdict = 'inconclusive';
      _officialSearchDone = false;
      _warningSpoken = false;
      _audioSubscription?.cancel();
      _audioSubscription = _audioBridge.receiveBroadcastStream().listen(
        (event) {
          if (event is Uint8List) unawaited(_processAudio(event));
        },
        onError: (_) {
          if (mounted) {
            setState(
              () => _message =
                  'Android no está entregando audio. Activa el altavoz; algunas llamadas silencian el micrófono de otras apps.',
            );
          }
        },
      );
      setState(() {
        _monitoring = true;
        _message =
            'Protección activa. Se analizarán fragmentos con voz y se enviarán a los proveedores solo mientras el permiso siga activo.';
      });
    } on PlatformException catch (error) {
      setState(
        () => _message = error.message ?? 'No se pudo activar el micrófono.',
      );
    }
  }

  Future<void> _processAudio(Uint8List pcm) async {
    final client = _client;
    if (!_monitoring || client == null) return;
    if (!_hasSpeechEnergy(pcm)) {
      if (mounted &&
          _message !=
              'No llega voz desde el micrófono. Activa el altavoz; Android podría estar reservando el audio para la llamada.') {
        setState(
          () => _message =
              'No llega voz desde el micrófono. Activa el altavoz; Android podría estar reservando el audio para la llamada.',
        );
      }
      return;
    }
    const maxVoiceBytes = 16000 * 2 * 10;
    if (!_voiceSubmitted && _voiceBuffer.length < maxVoiceBytes) {
      final remaining = maxVoiceBytes - _voiceBuffer.length;
      _voiceBuffer = Uint8List.fromList([
        ..._voiceBuffer,
        ...pcm.take(remaining),
      ]);
    }
    // Speech is sent only with the consent checkbox enabled; bytes are kept in
    // memory for this call and never written to a file or database.
    if (_consent) {
      try {
        final response = await client.functions.invoke(
          'echotrap-transcribe',
          body: {'pcm16Base64': _base64(pcm)},
        );
        final text = response.data is Map
            ? response.data['transcript']?.toString()
            : null;
        if (text != null && text.trim().isNotEmpty && mounted) {
          final merged = '${_transcript ?? ''} $text'.trim();
          final decision = assessEchoTrapText(merged);
          final previousVerdict = _verdict;
          final nextVerdict = switch (decision.risk) {
            EchoTrapTextRisk.highRisk => 'red',
            EchoTrapTextRisk.caution => 'yellow',
            // No detected phrase is not evidence that the call is safe.
            EchoTrapTextRisk.noSignal => _verdict,
          };
          setState(() {
            _transcript = merged;
            _verdict = nextVerdict;
            _message = decision.message;
          });
          if (nextVerdict != previousVerdict &&
              (nextVerdict == 'red' || nextVerdict == 'yellow')) {
            unawaited(_showRiskAlert(nextVerdict, decision.message));
          }
          if (decision.risk == EchoTrapTextRisk.highRisk) {
            if (!_warningSpoken) {
              _warningSpoken = true;
              await _speakLocal(
                'Alerta de posible estafa. No compartas claves ni códigos. Cuelga y llama al banco desde su aplicación oficial.',
              );
            }
          }
          if (_sourceSearchConsent &&
              !_officialSearchDone &&
              _containsOrganization(merged)) {
            _officialSearchDone = true;
            unawaited(_searchOfficialSource(merged));
          }
        }
      } catch (_) {
        if (mounted) {
          setState(
            () => _message =
                'No se pudo analizar este fragmento. Resultado no verificable; mantén precaución.',
          );
        }
      }
      if (!_voiceSubmitted && _voiceBuffer.length >= maxVoiceBytes) {
        _voiceSubmitted = true;
        unawaited(
          _checkSyntheticVoice(_voiceBuffer.sublist(0, 16000 * 2 * 10)),
        );
      }
    }
  }

  bool _hasSpeechEnergy(Uint8List pcm16) {
    if (pcm16.length < 2) return false;
    var absoluteTotal = 0;
    var count = 0;
    for (var index = 0; index + 1 < pcm16.length; index += 2) {
      final sample = (pcm16[index + 1] << 8) | pcm16[index];
      final signed = sample >= 0x8000 ? sample - 0x10000 : sample;
      absoluteTotal += signed.abs();
      count++;
    }
    return count > 0 && absoluteTotal ~/ count >= 180;
  }

  String _base64(Uint8List bytes) => base64Encode(bytes);

  Future<void> _checkSyntheticVoice(Uint8List pcm) async {
    try {
      final result = await _client!.functions.invoke(
        'echotrap-voice-check',
        body: {'pcm16Base64': _base64(pcm), 'sampleRate': 16000},
      );
      final data = result.data as Map;
      final score = (data['score'] as num?)?.toDouble();
      if (!mounted) return;
      if (score == null) {
        setState(
          () => _message =
              'TruthScan aún no devolvió un resultado. La voz queda sin verificar.',
        );
        return;
      }
      final shouldNotify =
          score >= .75 && _verdict != 'red' && _verdict != 'yellow';
      setState(() {
        _syntheticScore = score;
        if (shouldNotify) {
          _verdict = 'yellow';
          _message =
              'Precaución: el proveedor encontró señales compatibles con audio sintético. No identifica al hablante ni confirma un fraude.';
        }
      });
      if (shouldNotify) {
        unawaited(_showRiskAlert('yellow', _message!));
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _message =
              'La revisión de voz artificial no respondió; el resultado queda sin verificar.',
        );
      }
    }
  }

  bool _containsOrganization(String text) => _institution(text) != null;

  Future<void> _searchOfficialSource(String transcript) async {
    final institution = _institution(transcript);
    if (institution == null) return;
    try {
      final result = await _client!.functions.invoke(
        'echotrap-official-search',
        body: {'institution': institution},
      );
      final data = result.data as Map;
      final sources = (data['sources'] as List? ?? []).cast<Map>();
      if (mounted) {
        setState(() {
          _sources = sources
              .take(3)
              .map((item) => Map<String, Object?>.from(item))
              .toList();
          _sourceResult = _sources.isEmpty
              ? 'No se encontraron avisos oficiales; eso no confirma que la llamada sea legítima.'
              : null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _sourceResult =
              'No se pudo consultar las fuentes. La identidad de quien llama sigue sin verificarse.',
        );
      }
    }
  }

  String? _institution(String text) {
    final normalized = text
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u');
    if (RegExp(
      r'\b(b\s*c\s*p|banco de credito(?: del peru)?)\b',
    ).hasMatch(normalized)) {
      return 'BCP';
    }
    if (RegExp(r'\b(interbank)\b').hasMatch(normalized)) {
      return 'Interbank';
    }
    if (RegExp(r'\b(bbva)\b').hasMatch(normalized)) {
      return 'BBVA';
    }
    if (RegExp(r'\b(scotiabank)\b').hasMatch(normalized)) {
      return 'Scotiabank';
    }
    if (RegExp(r'\b(banco de la nacion|banco nacion)\b').hasMatch(normalized)) {
      return 'Banco de la Nación';
    }
    return null;
  }

  Future<void> _speakLocal(String text) async {
    try {
      await _phoneBridge.invokeMethod<void>('speakWarning', {'text': text});
    } catch (_) {
      /* visual alert remains available */
    }
  }

  Future<void> _showRiskAlert(String level, String text) async {
    try {
      await _phoneBridge.invokeMethod<void>('showRiskAlert', {
        'level': level,
        'text': text,
      });
    } catch (_) {
      // The warning remains visible in the EchoTrap screen.
    }
  }

  Future<void> _stopMonitoring() async {
    await _audioSubscription?.cancel();
    _audioSubscription = null;
    try {
      await _phoneBridge.invokeMethod<void>('stopCapture');
    } catch (_) {}
    if (mounted) {
      setState(() {
        _monitoring = false;
        _voiceBuffer = Uint8List(0);
        _voiceSubmitted = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final user = _client?.auth.currentUser;
    if (user == null && !_isPreviewMode) return _buildAccessScreen();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(
              Icons.shield_moon_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 10),
            Text(['Llamar', 'Contactos', 'Protección'][_selectedTab]),
          ],
        ),
        actions: [
          if (_isPreviewMode)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Center(child: Chip(label: Text('Vista previa'))),
            ),
          if (user != null)
            IconButton(
              tooltip: 'Cerrar sesión',
              onPressed: () async {
                await _stopMonitoring();
                await _client?.auth.signOut();
                setState(() {});
              },
              icon: const Icon(Icons.logout),
            ),
        ],
      ),
      body: Column(
        children: [
          if (_message != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: _Notice(
                text: _message!,
                color: _verdict == 'red'
                    ? Theme.of(context).colorScheme.errorContainer
                    : null,
              ),
            ),
          Expanded(
            child: IndexedStack(
              index: _selectedTab,
              children: [
                _buildDialerPage(),
                _buildContactsPage(),
                _buildProtectionPage(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _selectedTab == 1
          ? FloatingActionButton.extended(
              onPressed: _addContact,
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Añadir contacto'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTab,
        onDestinationSelected: (index) => setState(() => _selectedTab = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dialpad_outlined),
            selectedIcon: Icon(Icons.dialpad),
            label: 'Llamar',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
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

  Widget _buildAccessScreen() {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('EchoTrap'), centerTitle: false),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: colors.secondaryContainer,
                    foregroundColor: colors.onSecondaryContainer,
                    child: const Icon(Icons.shield_moon_outlined, size: 34),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Tus llamadas, con más cuidado',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Entra a EchoTrap para guardar tus contactos y configurar los avisos de llamadas.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  if (_message != null) ...[
                    const SizedBox(height: 20),
                    _Notice(text: _message!),
                  ],
                  if (_client == null) ...[
                    const SizedBox(height: 20),
                    const _Notice(
                      text:
                          'Esta instalación necesita la configuración pública de Qhawix para iniciar sesión. Las claves de proveedores se guardan en el servidor.',
                    ),
                  ] else ...[
                    const SizedBox(height: 24),
                    TextField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(
                        labelText: 'Correo electrónico',
                        prefixIcon: Icon(Icons.mail_outline),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _password,
                      obscureText: true,
                      autofillHints: const [AutofillHints.password],
                      decoration: const InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _working ? null : _authenticate,
                      child: Text(
                        _working
                            ? 'Un momento…'
                            : _registering
                            ? 'Crear cuenta'
                            : 'Iniciar sesión',
                      ),
                    ),
                    Center(
                      child: TextButton(
                        onPressed: () => setState(() {
                          _registering = !_registering;
                          _message = null;
                        }),
                        child: Text(
                          _registering
                              ? 'Ya tengo cuenta'
                              : 'Crear una cuenta nueva',
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDialerPage() {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final enteredNumber = _number.isNotEmpty
        ? _number
        : _destination.text.trim();
    final riskDetected = _verdict == 'red' || _verdict == 'yellow';
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      children: [
        Material(
          color: colors.secondaryContainer,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => setState(() => _selectedTab = 2),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(
                    _monitoring ? Icons.graphic_eq : Icons.shield_outlined,
                    color: colors.onSecondaryContainer,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _monitoring
                              ? 'Protección activa'
                              : _screeningEnabled
                              ? 'Avisos de llamadas activados'
                              : 'Configura tu protección',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: colors.onSecondaryContainer,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _monitoring
                              ? 'Revisando el sonido que entra por el altavoz'
                              : 'Toca para revisar tus opciones de seguridad',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSecondaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: colors.onSecondaryContainer),
                ],
              ),
            ),
          ),
        ),
        if (riskDetected || _monitoring) ...[
          const SizedBox(height: 12),
          _RiskSummary(verdict: _verdict, monitoring: _monitoring),
        ],
        const SizedBox(height: 18),
        Row(
          children: [
            const Spacer(),
            Expanded(
              flex: 5,
              child: Text(
                enteredNumber.isEmpty ? 'Ingresa un número' : enteredNumber,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            Expanded(
              child: IconButton(
                tooltip: 'Borrar último dígito',
                onPressed: enteredNumber.isEmpty ? null : _deleteDigit,
                icon: const Icon(Icons.backspace_outlined),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _Keypad(onDigit: _appendDigit),
        const SizedBox(height: 14),
        SizedBox(
          height: 56,
          child: FilledButton.icon(
            onPressed: enteredNumber.isEmpty ? null : _dial,
            icon: const Icon(Icons.call),
            label: const Text('Llamar'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF257A53),
              foregroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'La app Teléfono confirma la llamada. Cuando contesten, vuelve aquí y activa la protección con el altavoz.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildContactsPage() {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      children: [
        Text('Contactos guardados', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 6),
        Text(
          'Añade aquí los números que quieres reconocer. EchoTrap no lee la agenda del teléfono.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        if (_contacts.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 72),
            child: Column(
              children: [
                Icon(
                  Icons.person_add_alt_1,
                  size: 38,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 12),
                Text(
                  'Todavía no guardaste contactos',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                const Text('Usa “Añadir contacto” para empezar.'),
              ],
            ),
          )
        else
          ..._contacts.map(
            (contact) => Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    child: const Icon(Icons.person_outline),
                  ),
                  title: Text(contact['name'] ?? ''),
                  subtitle: Text(contact['phone'] ?? ''),
                  onTap: () => _selectContact(contact['phone'] ?? ''),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Usar este número',
                        onPressed: () => _selectContact(contact['phone'] ?? ''),
                        icon: const Icon(Icons.call_outlined),
                      ),
                      IconButton(
                        tooltip: 'Quitar contacto',
                        onPressed: () async {
                          _contacts.remove(contact);
                          await _saveContacts();
                        },
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildProtectionPage() {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        Text('Protección de llamadas', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 6),
        Text(
          'Activa solo las funciones que quieras usar. Puedes cambiar los permisos cuando lo necesites.',
          style: theme.textTheme.bodyMedium,
        ),
        if (_isPreviewMode) ...[
          const SizedBox(height: 16),
          const _Notice(
            text:
                'Vista previa local: puedes revisar el marcador y los contactos. El análisis de llamadas requiere la conexión real de tu cuenta.',
          ),
        ],
        const SizedBox(height: 24),
        Text(
          'Avisos de llamadas entrantes',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 6),
        const Text(
          'Android puede avisar sobre números visibles que no están guardados en tu agenda. La llamada seguirá sonando y EchoTrap no la marcará automáticamente como fraude.',
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: _screeningEnabled ? null : _enableScreening,
          icon: Icon(
            _screeningEnabled ? Icons.verified_user : Icons.shield_outlined,
          ),
          label: Text(
            _screeningEnabled
                ? 'Avisos activados'
                : 'Activar avisos en Android',
          ),
        ),
        if (!_isPreviewMode) ...[
          const Divider(height: 32),
          Text('Tu número', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _ownPhone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Número de teléfono',
              helperText: 'Se guarda en el perfil de tu cuenta.',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _working ? null : _savePhone,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Guardar número'),
            ),
          ),
        ],
        const Divider(height: 32),
        Text('Análisis durante la llamada', style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: _consent,
          onChanged: _isPreviewMode
              ? null
              : (value) => setState(() => _consent = value ?? false),
          title: const Text('Permitir análisis temporal de audio'),
          subtitle: const Text(
            'Envía fragmentos breves a Deepgram y TruthScan para transcripción y señales de voz artificial. Qhawix no los guarda. Puedes usar los avisos de números sin activar esto.',
          ),
          controlAffinity: ListTileControlAffinity.leading,
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: _sourceSearchConsent,
          onChanged: _isPreviewMode
              ? null
              : (value) =>
                    setState(() => _sourceSearchConsent = value ?? false),
          title: const Text('Permitir búsqueda de fuentes oficiales'),
          subtitle: const Text(
            'Si la transcripción menciona un banco, se buscarán avisos públicos relacionados. Solo se envía el nombre de la entidad, no el audio ni la transcripción.',
          ),
          controlAffinity: ListTileControlAffinity.leading,
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: _isPreviewMode
              ? null
              : _monitoring
              ? _stopMonitoring
              : _startMonitoring,
          icon: Icon(_monitoring ? Icons.stop : Icons.graphic_eq),
          label: Text(
            _isPreviewMode
                ? 'Análisis no conectado en vista previa'
                : _monitoring
                ? 'Detener análisis'
                : 'Proteger llamada actual',
          ),
          style: FilledButton.styleFrom(
            backgroundColor: _monitoring ? colors.error : null,
            foregroundColor: _monitoring ? colors.onError : null,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Inicia la llamada en Teléfono, activa el altavoz y vuelve aquí. EchoTrap solo analiza el sonido que el micrófono alcanza a captar.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
        _RiskCard(
          verdict: _verdict,
          score: _syntheticScore,
          transcript: _transcript,
          sources: _sourceResult,
          officialSources: _sources,
          onRepeatWarning: () => _speakLocal(
            'No compartas claves ni códigos. Cuelga y contacta a la entidad desde su aplicación oficial.',
          ),
        ),
        const SizedBox(height: 16),
        _Notice(
          text:
              'Límite actual: Android no permite que EchoTrap tome el audio de la llamada celular, silencie tu micrófono ni hable por ti. Tampoco contesta o graba en tu lugar. Las alertas de voz se oyen en este teléfono.',
          color: colors.surfaceContainerHighest,
        ),
      ],
    );
  }
}

class _Keypad extends StatelessWidget {
  const _Keypad({required this.onDigit});
  final ValueChanged<String> onDigit;
  @override
  Widget build(BuildContext context) => GridView.count(
    crossAxisCount: 3,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    childAspectRatio: 1.5,
    children: ['1', '2', '3', '4', '5', '6', '7', '8', '9', '*', '0', '#'].map((
      key,
    ) {
      final caption = switch (key) {
        '2' => 'ABC',
        '3' => 'DEF',
        '4' => 'GHI',
        '5' => 'JKL',
        '6' => 'MNO',
        '7' => 'PQRS',
        '8' => 'TUV',
        '9' => 'WXYZ',
        _ => '',
      };
      return Padding(
        padding: const EdgeInsets.all(3),
        child: Material(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => onDigit(key),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(key, style: Theme.of(context).textTheme.titleLarge),
                if (caption.isNotEmpty)
                  Text(
                    caption,
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(letterSpacing: 1.1),
                  ),
              ],
            ),
          ),
        ),
      );
    }).toList(),
  );
}

class _RiskSummary extends StatelessWidget {
  const _RiskSummary({required this.verdict, required this.monitoring});
  final String verdict;
  final bool monitoring;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isHigh = verdict == 'red';
    final isCaution = verdict == 'yellow';
    final background = isHigh
        ? colors.errorContainer
        : isCaution
        ? colors.tertiaryContainer
        : colors.surfaceContainerHighest;
    final foreground = isHigh
        ? colors.onErrorContainer
        : isCaution
        ? colors.onTertiaryContainer
        : colors.onSurfaceVariant;
    final title = isHigh
        ? 'Señal de riesgo alto'
        : isCaution
        ? 'Revisa esta llamada'
        : 'Análisis en curso';
    final detail = isHigh
        ? 'No compartas claves ni códigos. Considera colgar.'
        : isCaution
        ? 'No confirmes datos personales ni envíes dinero.'
        : monitoring
        ? 'Aún no hay datos suficientes para evaluar.'
        : 'Toca Protección para activar el análisis.';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            isHigh ? Icons.warning_amber_rounded : Icons.info_outline,
            color: foreground,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: foreground,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(detail, style: TextStyle(color: foreground)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RiskCard extends StatelessWidget {
  const _RiskCard({
    required this.verdict,
    required this.score,
    required this.transcript,
    required this.sources,
    required this.officialSources,
    required this.onRepeatWarning,
  });
  final String verdict;
  final double? score;
  final String? transcript;
  final String? sources;
  final List<Map<String, Object?>> officialSources;
  final VoidCallback onRepeatWarning;
  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).colorScheme;
    final color = verdict == 'red'
        ? palette.error
        : verdict == 'yellow'
        ? palette.tertiary
        : palette.primary;
    final label = verdict == 'red'
        ? 'RIESGO ALTO'
        : verdict == 'yellow'
        ? 'PRECAUCIÓN'
        : 'SIN DATOS';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.circle, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(color: color, fontWeight: FontWeight.bold),
                  ),
                ),
                if (score != null)
                  Text('Señal sintética: ${(score! * 100).round()}%'),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Es una estimación del proveedor, todavía no calibrada para llamadas de celular. No identifica a una persona ni confirma quién llama.',
            ),
            if (transcript != null) ...[
              const SizedBox(height: 8),
              Text('Texto reconocido: $transcript'),
            ],
            if (sources != null) ...[
              const SizedBox(height: 8),
              Text('Fuentes oficiales consultadas:\n$sources'),
            ],
            if (officialSources.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'Publicaciones de fuentes oficiales. No identifican a quien llama:',
              ),
              ...officialSources.map((source) {
                final date = source['publishedAt']?.toString().split('T').first;
                final excerpt = source['excerpt']?.toString() ?? '';
                final url = source['url']?.toString() ?? '';
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(source['title']?.toString() ?? 'Fuente oficial'),
                  subtitle: Text(
                    '${source['sourceType'] == 'autoridad_o_justicia' ? 'Autoridad pública o justicia' : 'Entidad oficial'}${date == null ? '' : ' · $date'} · ${excerpt.isEmpty ? 'Abrir la publicación oficial' : excerpt}',
                  ),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () async {
                    final uri = Uri.tryParse(url);
                    if (uri != null && uri.scheme == 'https') {
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  },
                );
              }),
            ],
            if (verdict == 'red')
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onRepeatWarning,
                  icon: const Icon(Icons.volume_up_outlined),
                  label: const Text('Repetir aviso en el teléfono'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text, this.color});
  final String text;
  final Color? color;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: color ?? Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(text),
  );
}
