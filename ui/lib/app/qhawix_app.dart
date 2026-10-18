import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/clock.dart';
import '../core/system_clock.dart';
import '../features/logbook/viewmodel/logbook_view_model.dart';
import '../features/qr_shield/data/repositories/unconfigured_qr_reputation_repository.dart';
import '../features/qr_shield/data/services/url_launcher_external_browser.dart';
import '../features/qr_shield/domain/repositories/qr_reputation_repository.dart';
import '../features/qr_shield/domain/services/qr_url_inspector.dart';
import '../features/qr_shield/domain/use_cases/inspect_qr_payload.dart';
import '../features/qr_shield/viewmodel/qr_shield_view_model.dart';
import '../features/sentinel/data/repositories/google_gmail_inbox_repository.dart';
import '../features/sentinel/domain/ports/sentinel_analysis_port.dart';
import '../features/sentinel/domain/ports/text_redaction_port.dart';
import '../features/sentinel/domain/repositories/gmail_inbox_repository.dart';
import '../features/sentinel/domain/services/sentinel_analyzer.dart';
import '../features/sentinel/domain/services/text_redactor.dart';
import 'qr_shield_router.dart';

class QhawixApp extends StatelessWidget {
  const QhawixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<Clock>(create: (_) => const SystemClock()),
        Provider<SentinelAnalysisPort>(create: (_) => const SentinelAnalyzer()),
        Provider<TextRedactionPort>(create: (_) => const TextRedactor()),
        Provider<GmailInboxRepository>(
          create: (_) => GoogleGmailInboxRepository(
            serverClientId: const String.fromEnvironment(
              'GOOGLE_SERVER_CLIENT_ID',
            ),
          ),
        ),
        Provider<QrUrlInspector>(create: (_) => QrUrlInspector()),
        Provider<QrReputationRepository>(
          create: (_) => const UnconfiguredQrReputationRepository(),
        ),
        Provider<InspectQrPayload>(
          create: (context) => InspectQrPayload(
            urlInspector: context.read<QrUrlInspector>(),
          ),
        ),
        Provider<UrlLauncherExternalBrowser>(
          create: (_) => const UrlLauncherExternalBrowser(),
        ),
        ChangeNotifierProvider<QrShieldViewModel>(
          create: (context) => QrShieldViewModel(
            inspectPayload: context.read<InspectQrPayload>(),
            reputationRepository: context.read<QrReputationRepository>(),
            externalBrowser: context.read<UrlLauncherExternalBrowser>(),
            clock: context.read<Clock>(),
          ),
        ),
        ChangeNotifierProvider<LogbookViewModel>(
          create: (context) => LogbookViewModel(
            clock: context.read<Clock>(),
            analyzer: context.read<SentinelAnalysisPort>(),
            redactor: context.read<TextRedactionPort>(),
          ),
        ),
      ],
      child: MaterialApp.router(
        title: 'QHAWIX',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF0B6477),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFF5F8FA),
          inputDecorationTheme: const InputDecorationTheme(
            border: OutlineInputBorder(),
          ),
          visualDensity: VisualDensity.standard,
        ),
        routerConfig: qrShieldRouter,
      ),
    );
  }
}
