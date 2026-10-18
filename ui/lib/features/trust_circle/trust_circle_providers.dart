import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'data/local_trust_circle_repository.dart';
import 'data/native_contact_picker.dart';
import 'domain/clock.dart';
import 'domain/contact_picker_port.dart';
import 'domain/trust_circle_repository.dart';
import 'viewmodel/family_keyword_view_model.dart';
import 'viewmodel/trust_circle_view_model.dart';

/// Providers for the Red de Confianza module (repositories and view models).
///
/// The default repository persists on the device. Pass [repository] (usually
/// the in-memory mock) and [contactPicker] from tests.
List<SingleChildWidget> trustCircleProviders({
  TrustCircleRepository? repository,
  Clock? clock,
  ContactPickerPort? contactPicker,
}) {
  final source = clock ?? const SystemClock();
  final repo = repository ?? LocalTrustCircleRepository(clock: source);
  final picker = contactPicker ?? NativeContactPicker();
  return [
    Provider<Clock>.value(value: source),
    Provider<TrustCircleRepository>.value(value: repo),
    Provider<ContactPickerPort>.value(value: picker),
    ChangeNotifierProvider<TrustCircleViewModel>(
      lazy: false,
      create: (_) =>
          TrustCircleViewModel(repository: repo, clock: source)..load(),
    ),
    ChangeNotifierProvider<FamilyKeywordViewModel>(
      lazy: false,
      create: (_) => FamilyKeywordViewModel(repository: repo)..load(),
    ),
  ];
}
