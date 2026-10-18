import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/qhawix_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabaseKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: String.fromEnvironment('SUPABASE_ANON_KEY'),
  );
  if (supabaseUrl.isNotEmpty && supabaseKey.isNotEmpty) {
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        publishableKey: supabaseKey,
      );
    } catch (_) {
      // The app shows a clear access error if the supplied setup is invalid.
    }
  }
  const previewRequested = bool.fromEnvironment('ECHOTRAP_PREVIEW');
  final previewBuild = kDebugMode && previewRequested;
  runApp(QhawixApp(requireAuthentication: !previewBuild));
}
