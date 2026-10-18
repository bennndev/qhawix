import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'data/repositories/web_risk_qr_reputation_repository.dart';
import 'data/services/android_qr_image_decoder.dart';
import 'data/services/android_qr_security_history_repository.dart';
import 'data/services/system_qr_clock.dart';
import 'data/services/url_launcher_external_browser.dart';
import 'domain/repositories/external_browser.dart';
import 'domain/repositories/qr_clock.dart';
import 'domain/repositories/qr_image_decoder.dart';
import 'domain/repositories/qr_reputation_repository.dart';
import 'domain/repositories/qr_security_history_repository.dart';
import 'domain/repositories/qr_security_history_query_repository.dart';
import 'domain/services/qr_reputation_policy.dart';
import 'domain/services/qr_url_inspector.dart';
import 'domain/use_cases/inspect_qr_payload.dart';
import 'viewmodel/qr_shield_view_model.dart';

/// Dependencies used by the QR Shield screen inside the existing app shell.
List<SingleChildWidget> qrShieldProviders() => [
  Provider<QrClock>(create: (_) => const SystemQrClock()),
  Provider<QrImageDecoder>(create: (_) => AndroidQrImageDecoder()),
  Provider<QrSecurityHistoryRepository>(
    create: (_) => AndroidQrSecurityHistoryRepository(),
  ),
  Provider<QrSecurityHistoryQueryRepository>(
    create: (_) => AndroidQrSecurityHistoryRepository(),
  ),
  Provider<QrUrlInspector>(create: (_) => QrUrlInspector()),
  Provider<QrReputationRepository>(
    create: (_) => WebRiskQrReputationRepository(),
    dispose: (_, repository) =>
        (repository as WebRiskQrReputationRepository).close(),
  ),
  Provider<QrReputationPolicy>(create: (_) => const QrReputationPolicy()),
  Provider<InspectQrPayload>(
    create: (context) =>
        InspectQrPayload(urlInspector: context.read<QrUrlInspector>()),
  ),
  Provider<ExternalBrowser>(
    create: (_) => const UrlLauncherExternalBrowser(),
  ),
  ChangeNotifierProvider<QrShieldViewModel>(
    create: (context) => QrShieldViewModel(
      inspectPayload: context.read<InspectQrPayload>(),
      reputationRepository: context.read<QrReputationRepository>(),
      externalBrowser: context.read<ExternalBrowser>(),
      clock: context.read<QrClock>(),
      imageDecoder: context.read<QrImageDecoder>(),
      reputationPolicy: context.read<QrReputationPolicy>(),
      securityHistoryRepository: context.read<QrSecurityHistoryRepository>(),
      securityHistoryQueryRepository:
          context.read<QrSecurityHistoryQueryRepository>(),
    ),
  ),
];
