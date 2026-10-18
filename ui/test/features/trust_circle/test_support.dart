import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:qhawix/core/theme/app_theme.dart';
import 'package:qhawix/features/trust_circle/data/mock/mock_trust_circle_repository.dart';
import 'package:qhawix/features/trust_circle/domain/clock.dart';
import 'package:qhawix/features/trust_circle/domain/contact_picker_port.dart';
import 'package:qhawix/features/trust_circle/domain/trust_circle_repository.dart';
import 'package:qhawix/features/trust_circle/trust_circle_providers.dart';
import 'package:qhawix/features/trust_circle/viewmodel/trust_circle_view_model.dart';

/// A clock the test moves by hand.
class FixedClock implements Clock {
  FixedClock([DateTime? start])
    : time = start ?? DateTime.utc(2026, 10, 17, 15);

  DateTime time;

  @override
  DateTime now() => time;
}

/// Contact picker that returns a fixed contact (or null) for widget tests.
class FakeContactPicker implements ContactPickerPort {
  FakeContactPicker({this.result});

  PickedPhoneContact? result;
  int calls = 0;

  @override
  Future<PickedPhoneContact?> pickPhoneContact() async {
    calls++;
    return result;
  }
}

/// Pumps [screen] inside the module providers, the project theme and an
/// optional text scale. Returns the clock so a test can move time.
///
/// Defaults to the in-memory mock repository (tests only). Production wires
/// [LocalTrustCircleRepository] via [trustCircleProviders].
Future<FixedClock> pumpModule(
  WidgetTester tester,
  Widget screen, {
  double textScale = 1,
  Size size = const Size(360, 800),
  FixedClock? clock,
  TrustCircleRepository? repository,
  ContactPickerPort? contactPicker,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final fixed = clock ?? FixedClock();
  final repo = repository ?? MockTrustCircleRepository(clock: fixed);
  await tester.pumpWidget(
    MultiProvider(
      providers: trustCircleProviders(
        clock: fixed,
        repository: repo,
        contactPicker: contactPicker ?? FakeContactPicker(),
      ),
      child: MaterialApp(
        theme: AppTheme.light(),
        builder: (context, home) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: home!,
        ),
        home: screen,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return fixed;
}

/// The module view model of the pumped screen.
TrustCircleViewModel viewModelOf(WidgetTester tester) =>
    Provider.of<TrustCircleViewModel>(
      tester.element(find.byType(Scaffold).first),
      listen: false,
    );

/// Words that would claim something real happened.
final claimsDelivery = RegExp(
  r'enviad[oa]|entregad[oa]|notificad[oa]|alerta enviada',
  caseSensitive: false,
);
