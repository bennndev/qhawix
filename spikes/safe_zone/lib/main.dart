import 'dart:async';

import 'package:another_telephony/telephony.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:native_geofence/native_geofence.dart';
import 'package:permission_handler/permission_handler.dart';

import 'background.dart';
import 'spike_log.dart';

// Optional: --dart-define-from-file=spike.local.json  ({"SPIKE_NUMBER": "..."}).
const _definedNumber = String.fromEnvironment('SPIKE_NUMBER');
const _spikePin = '1234'; // spike only: the real feature stores a salted hash

final _navKey = GlobalKey<NavigatorState>();
final _notifications = FlutterLocalNotificationsPlugin();

void _openPin() {
  _navKey.currentState
      ?.push(MaterialPageRoute<void>(builder: (_) => const PinScreen()));
}

void _onNotificationResponse(NotificationResponse r) {
  SpikeStore.log(
      'notification_response action=${r.actionId} type=${r.notificationResponseType.name}');
  _openPin();
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AndroidAlarmManager.initialize();
  await _notifications.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    ),
    onDidReceiveNotificationResponse: _onNotificationResponse,
  );
  final launch = await _notifications.getNotificationAppLaunchDetails();
  final launchedByNotification = launch?.didNotificationLaunchApp ?? false;
  await SpikeStore.log(
      'app_start launchedByNotification=$launchedByNotification');
  runApp(SpikeApp(openPinOnStart: launchedByNotification));
}

class SpikeApp extends StatelessWidget {
  const SpikeApp({super.key, required this.openPinOnStart});
  final bool openPinOnStart;

  @override
  Widget build(BuildContext context) {
    if (openPinOnStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openPin());
    }
    return MaterialApp(
      navigatorKey: _navKey,
      title: 'QHAWIX spike',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const SpikeScreen(),
    );
  }
}

class PinScreen extends StatefulWidget {
  const PinScreen({super.key});
  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  final _pin = TextEditingController();
  String _msg = '';

  Future<void> _submit() async {
    if (_pin.text == _spikePin) {
      await SpikeStore.writeJson('pending_send.json', {'cancelled': true});
      await AndroidAlarmManager.cancel(alarmCountdownId);
      await _notifications.cancel(id: 1);
      await SpikeStore.log('countdown_cancelled_by_pin');
      if (mounted) Navigator.of(context).pop();
    } else {
      await SpikeStore.log('pin_wrong');
      setState(() => _msg = 'PIN incorrecto. El envío sigue en marcha.');
      _pin.clear();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Cancelar envío')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            const Text('Ingresa tu PIN para cancelar el envío (spike: 1234).'),
            TextField(
              controller: _pin,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 8,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'PIN'),
              onSubmitted: (_) => _submit(),
            ),
            FilledButton(
                onPressed: _submit, child: const Text('Cancelar envío')),
            Text(_msg),
          ]),
        ),
      );
}

class SpikeScreen extends StatefulWidget {
  const SpikeScreen({super.key});
  @override
  State<SpikeScreen> createState() => _SpikeScreenState();
}

class _SpikeScreenState extends State<SpikeScreen> with WidgetsBindingObserver {
  final _number = TextEditingController(text: _definedNumber);
  final _radius = TextEditingController(text: '100');
  final _contactOut = ValueNotifier<String>('');
  Map<Permission, PermissionStatus> _perms = {};
  List<String> _log = [];
  Timer? _timer;

  static const _tracked = <String, Permission>{
    'Ubicación (en uso)': Permission.location,
    'Ubicación (todo el tiempo)': Permission.locationAlways,
    'SMS (enviar)': Permission.sms,
    'Notificaciones': Permission.notification,
    'Sin optimización de batería': Permission.ignoreBatteryOptimizations,
    'Alarmas exactas': Permission.scheduleExactAlarm,
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _saveConfig();
    _refresh();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) => _refresh());
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final perms = <Permission, PermissionStatus>{};
    for (final p in _tracked.values) {
      perms[p] = await p.status;
    }
    final log = await SpikeStore.readLog();
    if (mounted) {
      setState(() {
        _perms = perms;
        _log = log;
      });
    }
  }

  Future<void> _saveConfig({double? lat, double? lng}) async {
    final old = await SpikeStore.readJson('config.json');
    await SpikeStore.writeJson('config.json', {
      ...old,
      'number': _number.text.trim(),
      'radius': double.tryParse(_radius.text) ?? 100,
      if (lat != null) 'homeLat': lat,
      if (lng != null) 'homeLng': lng,
    });
  }

  Future<void> _request(Permission p, String label) async {
    final before = await p.status;
    final after = await p.request();
    await SpikeStore.log('perm_request $label $before -> $after');
    _refresh();
  }

  Future<void> _requestAllInOrder() async {
    // Order mandated by Android: foreground location first, then background.
    await _request(Permission.location, 'location');
    await _request(Permission.locationAlways, 'locationAlways');
    await _request(Permission.sms, 'sms');
    await _request(Permission.notification, 'notification');
    await _request(
        Permission.ignoreBatteryOptimizations, 'ignoreBatteryOptimizations');
  }

  Future<void> _q1Alarm() async {
    await _saveConfig();
    final ok = await AndroidAlarmManager.oneShot(
      const Duration(seconds: 60),
      alarmSmsId,
      alarmCallback,
      exact: true,
      wakeup: true,
      allowWhileIdle: true,
      rescheduleOnReboot: true,
    );
    await SpikeStore.log('q1_alarm_scheduled ok=$ok in=60s (SMS REAL al disparar)');
  }

  Future<void> _q2Register() async {
    await _saveConfig();
    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
    await _saveConfig(lat: pos.latitude, lng: pos.longitude);
    await registerHomeGeofence(
        pos.latitude, pos.longitude, double.tryParse(_radius.text) ?? 100);
  }

  Future<void> _q2List() async {
    await NativeGeofenceManager.instance.initialize();
    final list = await NativeGeofenceManager.instance.getRegisteredGeofences();
    await SpikeStore.log('geofences_registered count=${list.length} $list');
  }

  Future<void> _q2Remove() async {
    await NativeGeofenceManager.instance.initialize();
    await NativeGeofenceManager.instance.removeAllGeofences();
    await SpikeStore.log('geofences_removed');
  }

  Future<void> _q3RebootAlarm() async {
    final ok = await AndroidAlarmManager.oneShot(
      const Duration(minutes: 10),
      alarmRebootId,
      alarmCallback,
      exact: true,
      wakeup: true,
      allowWhileIdle: true,
      rescheduleOnReboot: true,
    );
    await SpikeStore.log('q3_reboot_alarm_scheduled ok=$ok in=10min');
  }

  Future<void> _q4Countdown() async {
    await _saveConfig();
    const seconds = 45;
    await SpikeStore.writeJson('pending_send.json', {'cancelled': false});
    await _notifications.show(
      id: 1,
      title: 'QHAWIX',
      body: 'Acción automática en $seconds s. Toca Cancelar para detenerla.',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'countdown',
          'Cuenta regresiva',
          importance: Importance.max,
          priority: Priority.high,
          ongoing: true,
          autoCancel: false,
          category: AndroidNotificationCategory.alarm,
          visibility: NotificationVisibility.public,
          actions: [
            AndroidNotificationAction('cancel', 'Cancelar',
                showsUserInterface: true),
          ],
        ),
      ),
    );
    final ok = await AndroidAlarmManager.oneShot(
      const Duration(seconds: seconds),
      alarmCountdownId,
      alarmCallback,
      exact: true,
      wakeup: true,
      allowWhileIdle: true,
    );
    await SpikeStore.log(
        'q4_countdown_started ok=$ok in=${seconds}s (SMS REAL si nadie cancela)');
  }

  Future<void> _q6Pick() async {
    final c = await FlutterNativeContactPicker().selectPhoneNumber();
    final text =
        c == null ? 'cancelado' : '${c.fullName} / ${c.selectedPhoneNumber}';
    _contactOut.value = text;
    await SpikeStore.log(
        'q6_contact_picked ${c == null ? 'null' : 'name_len=${c.fullName?.length}'}');
  }

  Future<void> _q7Ui() => logOneShotLocation('Q7 UI isolate');

  Future<void> _q7Alarm() async {
    final ok = await AndroidAlarmManager.oneShot(
      const Duration(seconds: 15),
      alarmLocationId,
      alarmCallback,
      exact: true,
      wakeup: true,
      allowWhileIdle: true,
    );
    await SpikeStore.log('q7_alarm_scheduled ok=$ok in=15s');
  }

  Future<void> _q8Ui() async {
    await _saveConfig();
    await SpikeStore.log('q8_ui_send (SMS REAL)');
    final cfg = await SpikeStore.readJson('config.json');
    final number = (cfg['number'] as String?) ?? '';
    if (number.isEmpty) {
      return SpikeStore.log('sms_skipped_no_number tag=Q8 UI');
    }
    try {
      await Telephony.instance.sendSms(
        to: number,
        message: 'Prueba QHAWIX: Q8 UI',
        statusListener: (s) => SpikeStore.log('sms_status ${s.name} tag=Q8 UI'),
      );
      await SpikeStore.log('sms_call_returned tag=Q8 UI');
    } catch (e) {
      await SpikeStore.log('sms_error tag=Q8 UI $e');
    }
  }

  Widget _btn(String text, Future<void> Function() fn) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: FilledButton.tonal(
          onPressed: () async {
            try {
              await fn();
            } catch (e) {
              await SpikeStore.log('button_error "$text" $e');
            }
            _refresh();
          },
          child: Text(text, textAlign: TextAlign.center),
        ),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('QHAWIX · spike zona segura')),
        body: ListView(padding: const EdgeInsets.all(12), children: [
          const Text(
              'Los botones marcados SMS REAL envían un mensaje de texto real '
              'al número indicado (consume saldo de la SIM).',
              style: TextStyle(fontWeight: FontWeight.bold)),
          TextField(
            controller: _number,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
                labelText: 'Número destinatario (SMS REAL)'),
            onChanged: (_) => _saveConfig(),
          ),
          TextField(
            controller: _radius,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
                labelText: 'Radio de casa (m, mínimo 100)'),
            onChanged: (_) => _saveConfig(),
          ),
          const Divider(),
          const Text('Permisos (Q5)',
              style: TextStyle(fontWeight: FontWeight.bold)),
          for (final e in _tracked.entries)
            Row(children: [
              Expanded(child: Text('${e.key}: ${_perms[e.value]?.name ?? '?'}')),
              TextButton(
                  onPressed: () => _request(e.value, e.key),
                  child: const Text('Pedir')),
            ]),
          _btn('Pedir todos en orden', _requestAllInOrder),
          _btn('Abrir ajustes de la app', () async {
            await openAppSettings();
          }),
          const Divider(),
          _btn('Q1 · Alarma en 60 s → SMS REAL', _q1Alarm),
          _btn('Q2/Q3 · Registrar geocerca en mi posición', _q2Register),
          _btn('Q2 · Listar geocercas registradas', _q2List),
          _btn('Q2 · Quitar geocercas', _q2Remove),
          _btn('Q3 · Alarma de reinicio (10 min)', _q3RebootAlarm),
          _btn('Q4 · Cuenta regresiva 45 s con Cancelar → SMS REAL',
              _q4Countdown),
          _btn('Q6 · Elegir contacto (sin permiso)', _q6Pick),
          ValueListenableBuilder<String>(
              valueListenable: _contactOut,
              builder: (_, v, _) => Text('Contacto: $v')),
          _btn('Q7 · Ubicación puntual (pantalla)', _q7Ui),
          _btn('Q7 · Alarma 15 s: ubicación desde isolate', _q7Alarm),
          _btn('Q8 · SMS REAL ahora desde pantalla (con estado)', _q8Ui),
          const Divider(),
          Row(children: [
            const Expanded(
                child: Text('Registro persistido',
                    style: TextStyle(fontWeight: FontWeight.bold))),
            TextButton(
                onPressed: () async {
                  await SpikeStore.clearLog();
                  _refresh();
                },
                child: const Text('Borrar')),
          ]),
          SelectableText(_log.take(120).join('\n'),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 11)),
        ]),
      );
}
