import 'package:flutter_test/flutter_test.dart';
import 'package:qhawix/features/sentinel/domain/models/gmail_email.dart';
import 'package:qhawix/features/sentinel/domain/models/sentinel_analysis.dart';
import 'package:qhawix/features/sentinel/domain/repositories/gmail_inbox_repository.dart';
import 'package:qhawix/features/sentinel/domain/services/sentinel_analyzer.dart';
import 'package:qhawix/features/sentinel/domain/services/text_redactor.dart';
import 'package:qhawix/features/sentinel/viewmodel/gmail_scan_view_model.dart';

void main() {
  test('does not request Gmail before consent', () async {
    final repository = _FakeGmailInboxRepository();
    final viewModel = _viewModel(repository);

    await viewModel.scan();

    expect(repository.fetchCount, 0);
    expect(viewModel.errorMessage, contains('consentimiento'));
    viewModel.dispose();
  });

  test(
    'analyzes only the latest email and redacts its sensitive details',
    () async {
      final repository = _FakeGmailInboxRepository(
        emails: const [
          GmailEmail(
            id: 'message-1',
            sender: 'alerta@example.com',
            subject: 'Confirma tu cuenta',
            body: 'Tu código de verificación es 834271. '
                'Transfiere el dinero ahora mismo a esta cuenta.',
          ),
          GmailEmail(
            id: 'message-2',
            sender: 'boletin@example.com',
            subject: 'Boletín semanal',
            body: 'Resumen de noticias de esta semana.',
          ),
        ],
      );
      final viewModel = _viewModel(repository);
      viewModel.setConsent(true);

      await viewModel.scan();

      expect(repository.fetchCount, 1);
      expect(repository.requestedLimit, 1);
      expect(viewModel.results, hasLength(1));
      expect(viewModel.results.single.subject, 'Confirma tu cuenta');
      expect(viewModel.results.single.risk, RequestRisk.high);
      expect(viewModel.results.single.ruleIds, contains('R-03'));
      expect(viewModel.results.single.sender, '[CORREO]');
      expect(viewModel.results.single.preview, isNot(contains('834271')));
      viewModel.dispose();
    },
  );
}

GmailScanViewModel _viewModel(_FakeGmailInboxRepository repository) =>
    GmailScanViewModel(
      repository: repository,
      analyzer: const SentinelAnalyzer(),
      redactor: const TextRedactor(),
    );

class _FakeGmailInboxRepository implements GmailInboxRepository {
  _FakeGmailInboxRepository({this.emails = const []});

  final List<GmailEmail> emails;
  int fetchCount = 0;
  int? requestedLimit;

  @override
  bool get isConfigured => true;

  @override
  Future<List<GmailEmail>> fetchRecentInbox({required int limit}) async {
    fetchCount++;
    requestedLimit = limit;
    return emails;
  }

  @override
  Future<void> disconnect() async {}
}
