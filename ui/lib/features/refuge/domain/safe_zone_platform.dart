import 'safe_zone_config.dart';
import 'safe_zone_status.dart';

/// Port to the Android side of the safe-zone feature. One method per method of
/// `contracts/safe-zone-channel.md`. Every method throws a `SafeZoneError`.
abstract interface class SafeZonePlatform {
  Future<SafeZoneStatus> getStatus();

  /// Stores the config; applies it if `monitoringEnabled`.
  Future<void> saveConfig(SafeZoneConfig config);

  /// The stored config, or null when nothing was saved yet.
  Future<SafeZoneConfig?> loadConfig();

  Future<void> startMonitoring();

  Future<void> stopMonitoring();

  Future<PermissionResult> requestPermission(PermissionKind kind);

  /// 4 to 8 digits. Native keeps only a salted hash.
  Future<void> setCancelPin(String pin);

  Future<bool> hasCancelPin();

  Future<DeviceLocation> currentLocation();

  /// Null when the person cancels the system picker.
  Future<PickedContact?> pickContact();

  /// Sends a **real SMS** to every recipient of the stored config.
  Future<List<TestSendResult>> sendTestMessage();

  /// Runs the full pipeline with a **real SMS**; its events are marked test.
  Future<void> runEndToEndTest();

  Future<bool> cancelCountdown();

  /// Events native pushes while the app is alive.
  Stream<SafeZoneEvent> get events;
}
