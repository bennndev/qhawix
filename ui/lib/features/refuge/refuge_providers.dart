import 'dart:async';

import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../trust_circle/domain/trust_circle_repository.dart';
import 'data/packages_safe_zone_platform.dart';
import 'data/trust_circle_recipient_source.dart';
import 'domain/alert_recipient_source.dart';
import 'domain/clock.dart';
import 'domain/safe_zone_platform.dart';
import 'viewmodel/safe_zone_status_view_model.dart';

/// Providers for the Refugio module (platform port and view models).
///
/// By default the platform is the package-based Android adapter. Recipients
/// come from the Trust Circle repository, so `trustCircleProviders()` must sit
/// above these in the tree. [platform], [recipientSource] and [clock] let tests
/// inject their own.
List<SingleChildWidget> refugeProviders({
  SafeZonePlatform? platform,
  AlertRecipientSource? recipientSource,
  Clock? clock,
}) {
  final port = platform ?? PackagesSafeZonePlatform();
  if (port is PackagesSafeZonePlatform) {
    unawaited(port.ensureInitialized());
  }
  return [
    Provider<Clock>.value(value: clock ?? const SystemClock()),
    Provider<SafeZonePlatform>.value(value: port),
    Provider<AlertRecipientSource>(
      create: (context) =>
          recipientSource ??
          TrustCircleRecipientSource(context.read<TrustCircleRepository>()),
    ),
    ChangeNotifierProvider<SafeZoneStatusViewModel>(
      lazy: false,
      create: (_) => SafeZoneStatusViewModel(platform: port)..load(),
    ),
  ];
}
