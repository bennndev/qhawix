import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'data/mock/mock_trust_circle_repository.dart';
import 'domain/clock.dart';
import 'domain/trust_circle_repository.dart';
import 'viewmodel/family_keyword_view_model.dart';
import 'viewmodel/trust_circle_view_model.dart';

/// Providers for the Red de Confianza module (repositories and view models).
///
/// Until a real gateway-backed repository exists, the default repository is
/// the in-memory mock, so every screen shows the example-data banner.
/// [repository] and [clock] let tests inject their own.
List<SingleChildWidget> trustCircleProviders({
  TrustCircleRepository? repository,
  Clock? clock,
}) {
  final source = clock ?? const SystemClock();
  final repo = repository ?? MockTrustCircleRepository(clock: source);
  return [
    Provider<Clock>.value(value: source),
    Provider<TrustCircleRepository>.value(value: repo),
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
