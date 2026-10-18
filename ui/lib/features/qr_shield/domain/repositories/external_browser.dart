abstract interface class ExternalBrowser {
  Future<bool> openHttpUrl(Uri url);
}
