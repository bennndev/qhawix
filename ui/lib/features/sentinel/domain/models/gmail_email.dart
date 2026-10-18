class GmailEmail {
  const GmailEmail({
    required this.id,
    required this.sender,
    required this.subject,
    required this.body,
  });

  final String id;
  final String sender;
  final String subject;
  final String body;
}
