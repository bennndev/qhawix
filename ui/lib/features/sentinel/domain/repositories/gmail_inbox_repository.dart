import '../models/gmail_email.dart';

abstract interface class GmailInboxRepository {
  bool get isConfigured;

  Future<List<GmailEmail>> fetchRecentInbox({required int limit});

  Future<void> disconnect();
}
