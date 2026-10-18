import 'dart:async';
import 'dart:ui';

import 'package:another_telephony/telephony.dart';
import 'package:geolocator/geolocator.dart';
import 'package:native_geofence/native_geofence.dart';
import 'package:permission_handler/permission_handler.dart';

import 'spike_log.dart';

const alarmSmsId = 1;
const alarmLocationId = 2;
const alarmCountdownId = 3;
const alarmRebootId = 4;
const homeGeofenceId = 'spike_home';

/// Sends a REAL SMS to the configured number and logs every status callback.
/// Returns after a grace period so the process stays alive for sent/delivered.
Future<void> sendRealSms(String tag, {bool waitForStatus = true}) async {
  final cfg = await SpikeStore.readJson('config.json');
  final number = (cfg['number'] as String?) ?? '';
  if (number.isEmpty) {
    await SpikeStore.log('sms_skipped_no_number tag=$tag');
    return;
  }
  final smsPerm = await Permission.sms.status;
  await SpikeStore.log('sms_attempt tag=$tag perm_sms=$smsPerm');
  try {
    await Telephony.backgroundInstance.sendSms(
      to: number,
      message: 'Prueba QHAWIX: $tag',
      statusListener: (status) => SpikeStore.log('sms_status ${status.name} tag=$tag'),
    );
    await SpikeStore.log('sms_call_returned tag=$tag');
    if (waitForStatus) await Future<void>.delayed(const Duration(seconds: 20));
  } catch (e) {
    await SpikeStore.log('sms_error tag=$tag $e');
  }
}

Future<void> logOneShotLocation(String tag) async {
  try {
    final enabled = await Geolocator.isLocationServiceEnabled();
    final perm = await Geolocator.checkPermission();
    await SpikeStore.log('loc_try tag=$tag service=$enabled perm=$perm');
    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 25),
      ),
    );
    await SpikeStore.log('loc_ok tag=$tag lat=${pos.latitude.toStringAsFixed(5)} '
        'lng=${pos.longitude.toStringAsFixed(5)} acc=${pos.accuracy.toStringAsFixed(1)}m');
  } catch (e) {
    await SpikeStore.log('loc_error tag=$tag $e');
  }
}

/// android_alarm_manager_plus entry point (runs in its own isolate).
@pragma('vm:entry-point')
Future<void> alarmCallback(int id, Map<String, dynamic> params) async {
  DartPluginRegistrant.ensureInitialized();
  await SpikeStore.log('alarm_fired id=$id params=$params');
  switch (id) {
    case alarmSmsId:
      await sendRealSms('Q1 alarm');
    case alarmLocationId:
      await logOneShotLocation('Q7 alarm isolate');
    case alarmCountdownId:
      final pending = await SpikeStore.readJson('pending_send.json');
      if (pending['cancelled'] == true) {
        await SpikeStore.log('countdown_end_cancelled_no_sms');
      } else {
        await SpikeStore.log('countdown_end_sending');
        await sendRealSms('Q4 countdown');
      }
    case alarmRebootId:
      await SpikeStore.log('reboot_alarm_ok');
  }
}

/// native_geofence entry point (runs in a fresh isolate, app may be dead).
@pragma('vm:entry-point')
Future<void> geofenceTriggered(GeofenceCallbackParams params) async {
  DartPluginRegistrant.ensureInitialized();
  await SpikeStore.log('geofence event=${params.event.name} '
      'loc=${params.location} ids=${params.geofences.map((g) => g.id).join(',')}');
  if (params.event == GeofenceEvent.exit) {
    await logOneShotLocation('Q7 geofence isolate');
    await sendRealSms('Q2 geofence exit');
  }
}

Future<void> registerHomeGeofence(double lat, double lng, double radius) async {
  await NativeGeofenceManager.instance.initialize();
  await NativeGeofenceManager.instance.createGeofence(
    Geofence(
      id: homeGeofenceId,
      location: Location(latitude: lat, longitude: lng),
      radiusMeters: radius,
      triggers: {GeofenceEvent.enter, GeofenceEvent.exit},
      iosSettings: const IosGeofenceSettings(initialTrigger: false),
      androidSettings: const AndroidGeofenceSettings(
        // Enter fires at registration (and after reboot re-registration)
        // when the phone is already inside: proves Q3 without walking.
        initialTriggers: {GeofenceEvent.enter},
      ),
    ),
    geofenceTriggered,
  );
  await SpikeStore.log('geofence_registered lat=$lat lng=$lng r=$radius');
}
