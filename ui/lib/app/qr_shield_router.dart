import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../features/guardian_pay/view/guardian_review_screen.dart';
import '../features/guardian_pay/viewmodel/guardian_review_view_model.dart';
import '../features/logbook/view/case_timeline_screen.dart';
import '../features/logbook/view/case_overview_screen.dart';
import '../features/logbook/view/logbook_screen.dart';
import '../features/logbook/viewmodel/logbook_view_model.dart';
import '../features/privacy/view/privacy_screen.dart';
import '../features/qr_shield/view/qr_review_screen.dart';
import '../features/qr_shield/view/qr_scanner_screen.dart';
import '../features/qr_shield/view/qr_shield_home_screen.dart';
import '../features/sentinel/domain/ports/sentinel_analysis_port.dart';
import '../features/sentinel/domain/ports/text_redaction_port.dart';
import '../features/sentinel/domain/repositories/gmail_inbox_repository.dart';
import '../features/sentinel/view/gmail_scan_screen.dart';
import '../features/sentinel/view/sentinel_input_screen.dart';
import '../features/sentinel/viewmodel/gmail_scan_view_model.dart';
import 'view/app_home_screen.dart';

final GoRouter qrShieldRouter = GoRouter(
  initialLocation: '/',
  errorBuilder: (context, _) => Scaffold(
    appBar: AppBar(title: const Text('QHAWIX')),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Esta pantalla ya no está disponible.'),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => context.go('/'),
              child: const Text('Volver al inicio'),
            ),
          ],
        ),
      ),
    ),
  ),
  routes: [
    GoRoute(path: '/', builder: (context, state) => const AppHomeScreen()),
    GoRoute(
      path: '/sentinel/gmail',
      builder: (context, state) => ChangeNotifierProvider(
        create: (context) => GmailScanViewModel(
          repository: context.read<GmailInboxRepository>(),
          analyzer: context.read<SentinelAnalysisPort>(),
          redactor: context.read<TextRedactionPort>(),
        ),
        child: const GmailScanScreen(),
      ),
    ),
    GoRoute(
      path: '/evidence/new',
      builder: (context, state) => SentinelInputScreen(
        caseId: state.uri.queryParameters['caseId'],
        onAnalyze: ({required text, required channel, caseId}) {
          final logbook = context.read<LogbookViewModel>();
          if (caseId == null) {
            return logbook.analyzeEvidence(text: text, channel: channel);
          }
          return logbook.addEvidenceToCase(
            caseId: caseId,
            text: text,
            channel: channel,
          )
              ? caseId
              : null;
        },
        errorMessage: () => context.read<LogbookViewModel>().errorMessage,
      ),
    ),
    GoRoute(
      path: '/cases/:caseId',
      builder: (context, state) => CaseOverviewScreen(
        caseId: state.pathParameters['caseId']!,
      ),
    ),
    GoRoute(
      path: '/cases/:caseId/timeline',
      builder: (context, state) => CaseTimelineScreen(
        caseId: state.pathParameters['caseId']!,
      ),
    ),
    GoRoute(path: '/logbook', builder: (context, state) => const LogbookScreen()),
    GoRoute(
      path: '/guardian',
      builder: (context, state) => ChangeNotifierProvider(
        create: (context) => GuardianReviewViewModel(
          analyzer: context.read<SentinelAnalysisPort>(),
          redactor: context.read<TextRedactionPort>(),
        ),
        child: const GuardianReviewScreen(),
      ),
    ),
    GoRoute(path: '/help', builder: (context, state) => const PrivacyScreen()),
    GoRoute(path: '/privacy', builder: (context, state) => const PrivacyScreen()),
    GoRoute(
      path: '/qr',
      builder: (context, state) => const QrShieldHomeScreen(),
    ),
    GoRoute(
      path: '/qr/scan',
      builder: (context, state) => const QrScannerScreen(),
    ),
    GoRoute(
      path: '/qr/result/:revision',
      builder: (context, state) => QrReviewScreen(
        expectedRevision: int.tryParse(state.pathParameters['revision'] ?? ''),
      ),
    ),
  ],
);
