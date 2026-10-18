import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qhawix/features/refuge/domain/safe_zone_error.dart';
import 'package:qhawix/features/refuge/domain/safe_zone_status.dart';
import 'package:qhawix/features/refuge/view/refuge_screen.dart';
import 'package:qhawix/features/refuge/view/safe_zone_onboarding_screen.dart';

import 'test_support.dart';

Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable: find.byType(Scrollable).first,
  );
}

Future<void> _tapText(WidgetTester tester, String text) async {
  final finder = find.text(text);
  await _scrollTo(tester, finder);
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _enter(WidgetTester tester, int index, String text) async {
  final field = find.byType(TextField).at(index);
  await tester.ensureVisible(field);
  await tester.enterText(field, text);
  await tester.pump();
}

/// Fills every step and stops on the review step.
Future<void> _goToReview(WidgetTester tester) async {
  await _tapText(tester, 'Empezar');
  await _enter(tester, 0, 'Luz');
  await _tapText(tester, 'Ana');
  await _tapText(tester, 'Siguiente');
  await _tapText(tester, 'Usar mi ubicación actual');
  if (find.text('Continuar').evaluate().isNotEmpty) {
    await _tapText(tester, 'Continuar');
  }
  await _tapText(tester, 'Siguiente');
  await _tapText(tester, 'Siguiente');
  await _enter(tester, 0, '1234');
  await _enter(tester, 1, '1234');
  await _tapText(tester, 'Guardar PIN');
  await _tapText(tester, 'Siguiente'); // permissions
  await _tapText(tester, 'Siguiente'); // auto-start
  await _tapText(tester, 'Ya lo activé en este teléfono');
  await _tapText(tester, 'Siguiente'); // review
}

FilledButton _filled(WidgetTester tester, String label) => tester.widget(
  find.ancestor(of: find.text(label), matching: find.byType(FilledButton)),
);

void _expectTouchTargets(WidgetTester tester) {
  for (final finder in [
    find.byType(ButtonStyleButton),
    find.byType(CheckboxListTile),
  ]) {
    for (var i = 0; i < finder.evaluate().length; i++) {
      final size = tester.getSize(finder.at(i));
      expect(size.height, greaterThanOrEqualTo(48), reason: '$finder #$i');
      expect(size.width, greaterThanOrEqualTo(48), reason: '$finder #$i');
    }
  }
}

FakeSafeZonePlatform _configuredPlatform({
  SafePermissions permissions = allGranted,
  bool monitoring = true,
  SafeZoneEvent? lastEvent,
  int? awaySinceMillis,
}) => FakeSafeZonePlatform(
  status: statusWith(
    monitoring: monitoring,
    permissions: permissions,
    sentToday: 1,
    lastEvent: lastEvent,
    awaySinceMillis: awaySinceMillis,
  ),
  config: sampleConfig(),
  pinSet: true,
);

void main() {
  group('onboarding wizard', () {
    testWidgets('first step explains the feature and the honest limits', (
      tester,
    ) async {
      await pumpRefuge(
        tester,
        const SafeZoneOnboardingScreen(),
        platform: FakeSafeZonePlatform(),
      );
      expect(find.text('Alertas de zona segura'), findsWidgets);
      expect(find.textContaining('varios minutos'), findsOneWidget);
      expect(find.textContaining('fabricante del teléfono'), findsOneWidget);
      expect(find.textContaining('saldo en el chip'), findsOneWidget);
      expect(find.textContaining('red del operador'), findsOneWidget);
      expect(find.textContaining('Paso 1 de 8'), findsOneWidget);
      expect(find.text('Atrás'), findsNothing);
    });

    testWidgets('progress advances and back returns', (tester) async {
      await pumpRefuge(
        tester,
        const SafeZoneOnboardingScreen(),
        platform: FakeSafeZonePlatform(),
      );
      await _tapText(tester, 'Empezar');
      expect(find.textContaining('Paso 2 de 8'), findsOneWidget);
      await _tapText(tester, 'Atrás');
      expect(find.textContaining('Paso 1 de 8'), findsOneWidget);
    });

    testWidgets('next is blocked until name and a recipient are chosen', (
      tester,
    ) async {
      await pumpRefuge(
        tester,
        const SafeZoneOnboardingScreen(),
        platform: FakeSafeZonePlatform(),
      );
      await _tapText(tester, 'Empezar');
      expect(_filled(tester, 'Siguiente').onPressed, isNull);
      await _enter(tester, 0, 'Luz');
      await _tapText(tester, 'Ana');
      expect(_filled(tester, 'Siguiente').onPressed, isNotNull);
    });

    testWidgets('"Usar mi ubicación actual" asks first, then shows the point', (
      tester,
    ) async {
      final platform = FakeSafeZonePlatform();
      await pumpRefuge(
        tester,
        const SafeZoneOnboardingScreen(),
        platform: platform,
      );
      await _tapText(tester, 'Empezar');
      await _enter(tester, 0, 'Luz');
      await _tapText(tester, 'Ana');
      await _tapText(tester, 'Siguiente');
      await _tapText(tester, 'Usar mi ubicación actual');
      expect(find.text('Ubicación precisa para Refugio'), findsOneWidget);
      expect(
        platform.calls.where((c) => c.startsWith('requestPermission')),
        isEmpty,
        reason: 'nothing is requested before its rationale',
      );
      await _tapText(tester, 'Continuar');
      expect(platform.calls, contains('requestPermission:fineLocation'));
      expect(platform.calls, contains('currentLocation'));
      expect(find.text('-12.04640'), findsOneWidget);
      expect(find.text('-77.04280'), findsOneWidget);
      expect(find.textContaining('no se envía a ningún'), findsOneWidget);
    });

    testWidgets('"Ahora no" postpones the permission and requests nothing', (
      tester,
    ) async {
      final platform = FakeSafeZonePlatform();
      await pumpRefuge(
        tester,
        const SafeZoneOnboardingScreen(),
        platform: platform,
      );
      await _tapText(tester, 'Empezar');
      await _enter(tester, 0, 'Luz');
      await _tapText(tester, 'Ana');
      await _tapText(tester, 'Siguiente');
      await _tapText(tester, 'Usar mi ubicación actual');
      await _tapText(tester, 'Ahora no');
      expect(platform.calls, isNot(contains('currentLocation')));
      expect(
        platform.calls.where((c) => c.startsWith('requestPermission')),
        isEmpty,
      );
    });

    testWidgets('manual coordinates are the alternative to the GPS', (
      tester,
    ) async {
      await pumpRefuge(
        tester,
        const SafeZoneOnboardingScreen(),
        platform: FakeSafeZonePlatform(),
      );
      await _tapText(tester, 'Empezar');
      await _enter(tester, 0, 'Luz');
      await _tapText(tester, 'Ana');
      await _tapText(tester, 'Siguiente');
      await _tapText(tester, 'Escribir coordenadas');
      await _enter(tester, 0, '-12,5');
      await _enter(tester, 1, '-77.1');
      await _tapText(tester, 'Usar estas coordenadas');
      expect(find.text('-12.50000'), findsOneWidget);
      expect(_filled(tester, 'Siguiente').onPressed, isNotNull);
    });

    testWidgets('parameters: window, mode explanations and GPS-error note', (
      tester,
    ) async {
      await pumpRefuge(
        tester,
        const SafeZoneOnboardingScreen(),
        platform: FakeSafeZonePlatform(
          status: statusWith(permissions: allGranted),
        ),
      );
      await _tapText(tester, 'Empezar');
      await _enter(tester, 0, 'Luz');
      await _tapText(tester, 'Ana');
      await _tapText(tester, 'Siguiente');
      await _tapText(tester, 'Usar mi ubicación actual');
      await _tapText(tester, 'Siguiente');
      expect(find.textContaining('Paso 4 de 8'), findsOneWidget);
      expect(find.text('100 m'), findsOneWidget);
      expect(
        find.textContaining('errores de decenas de metros'),
        findsOneWidget,
      );
      expect(find.text('22:00'), findsOneWidget);
      expect(find.text('06:00'), findsOneWidget);
      expect(find.textContaining('cruza la medianoche'), findsWidgets);
      expect(find.textContaining('Es lo más preciso'), findsOneWidget);
      expect(find.textContaining('Habrá más avisos'), findsOneWidget);
      await _tapText(tester, 'Lejos de casa a cualquier hora');
      expect(
        find.text('Desde'),
        findsNothing,
        reason: 'no window in this mode',
      );
    });

    testWidgets('sending: the preview shows the fixed automatic suffix', (
      tester,
    ) async {
      await pumpRefuge(
        tester,
        const SafeZoneOnboardingScreen(),
        platform: FakeSafeZonePlatform(),
      );
      await _tapText(tester, 'Empezar');
      await _enter(tester, 0, 'Luz');
      await _tapText(tester, 'Ana');
      await _tapText(tester, 'Siguiente');
      await _tapText(tester, 'Usar mi ubicación actual');
      await _tapText(tester, 'Continuar');
      await _tapText(tester, 'Siguiente');
      await _tapText(tester, 'Siguiente');
      expect(find.textContaining('Paso 5 de 8'), findsOneWidget);
      expect(find.text('Enviar directo'), findsOneWidget);
      expect(find.text('30 s'), findsOneWidget);
      expect(find.text('120 s'), findsOneWidget);
      expect(
        find.textContaining(
          'Mensaje automático de QHAWIX enviado desde el celular de Luz.',
          findRichText: true,
        ),
        findsWidgets,
      );
      expect(_filled(tester, 'Siguiente').onPressed, isNull, reason: 'PIN');
      await _tapText(tester, 'Enviar directo');
      expect(_filled(tester, 'Siguiente').onPressed, isNotNull);
    });

    testWidgets('permissions step lists them in order with live state', (
      tester,
    ) async {
      final platform = FakeSafeZonePlatform(
        status: statusWith(
          permissions: const SafePermissions(
            fineLocation: true,
            backgroundLocation: false,
            sendSms: false,
            notifications: false,
            batteryOptimizationIgnored: false,
          ),
        ),
      );
      await pumpRefuge(
        tester,
        const SafeZoneOnboardingScreen(),
        platform: platform,
        size: const Size(360, 1800),
      );
      await _goToReview(tester);
      await _tapText(tester, 'Ir a permisos');
      expect(find.textContaining('Paso 6 de 8'), findsOneWidget);
      final order = [
        'Ubicación precisa',
        'Ubicación todo el tiempo',
        'Enviar SMS',
        'Notificaciones',
        'Sin ahorro de batería',
      ];
      double lastY = -1;
      for (final name in order) {
        final finder = find.text(name);
        final y = tester.getTopLeft(finder).dy;
        expect(y, greaterThan(lastY), reason: name);
        lastY = y;
      }
      expect(find.text('Concedido'), findsOneWidget);
      expect(find.text('Falta'), findsNWidgets(4));
      await _tapText(tester, 'Revisar permisos pendientes');
      expect(
        find.text('Ubicación todo el tiempo para Refugio'),
        findsOneWidget,
      );
      expect(find.textContaining('Permitir todo el tiempo'), findsOneWidget);
      await _tapText(tester, 'Ahora no');
      expect(find.text('Enviar SMS para Refugio'), findsOneWidget);
      await _tapText(tester, 'Continuar');
      expect(platform.calls, contains('requestPermission:sendSms'));
      expect(
        platform.calls,
        isNot(contains('requestPermission:backgroundLocation')),
        reason: 'postponed',
      );
    });

    testWidgets(
      'review blocks "Iniciar monitoreo" without required permissions',
      (tester) async {
        final platform = FakeSafeZonePlatform();
        await pumpRefuge(
          tester,
          const SafeZoneOnboardingScreen(),
          platform: platform,
        );
        await _goToReview(tester);
        expect(find.textContaining('Paso 8 de 8'), findsOneWidget);
        expect(_filled(tester, 'Iniciar monitoreo').onPressed, isNull);
        expect(
          find.textContaining('faltan permisos obligatorios'),
          findsOneWidget,
        );
        expect(platform.calls, isNot(contains('startMonitoring')));
      },
    );

    testWidgets('review starts monitoring once the required ones are granted', (
      tester,
    ) async {
      final platform = FakeSafeZonePlatform(
        status: statusWith(permissions: allGranted),
      );
      var finished = 0;
      await pumpRefuge(
        tester,
        SafeZoneOnboardingScreen(onFinished: () => finished++),
        platform: platform,
      );
      await _goToReview(tester);
      expect(_filled(tester, 'Iniciar monitoreo').onPressed, isNotNull);
      await _tapText(tester, 'Iniciar monitoreo');
      expect(platform.calls, contains('startMonitoring'));
      expect(platform.saved.last.monitoringEnabled, isTrue);
      expect(finished, 1);
    });

    testWidgets('a real-SMS confirmation precedes the test message', (
      tester,
    ) async {
      final platform =
          FakeSafeZonePlatform(status: statusWith(permissions: allGranted))
            ..testResults = const [
              TestSendResult(phone: '+51900000001', outcome: SendOutcome.sent),
            ];
      await pumpRefuge(
        tester,
        const SafeZoneOnboardingScreen(),
        platform: platform,
      );
      await _goToReview(tester);
      await _tapText(tester, 'Enviar mensaje de prueba');
      expect(find.text('Enviar un SMS real'), findsOneWidget);
      expect(find.textContaining('puede costar saldo'), findsOneWidget);
      expect(platform.calls, isNot(contains('sendTestMessage')));
      await _tapText(tester, 'Cancelar');
      expect(platform.calls, isNot(contains('sendTestMessage')));
      await _tapText(tester, 'Enviar mensaje de prueba');
      await _tapText(tester, 'Enviar SMS real');
      expect(platform.calls, contains('sendTestMessage'));
      expect(find.text('Entregado a la red del operador'), findsOneWidget);
      expect(find.textContaining('no confirma que la persona'), findsOneWidget);
    });

    testWidgets('an unavailable device says so', (tester) async {
      final platform = FakeSafeZonePlatform()
        ..failWith = const UnavailableError();
      await pumpRefuge(
        tester,
        const SafeZoneOnboardingScreen(),
        platform: platform,
      );
      expect(find.text('No disponible en este dispositivo'), findsOneWidget);
    });

    testWidgets('every step fits at 200% text scale and keeps 48 dp targets', (
      tester,
    ) async {
      final platform = FakeSafeZonePlatform(
        status: statusWith(permissions: allGranted),
      );
      await pumpRefuge(
        tester,
        const SafeZoneOnboardingScreen(),
        platform: platform,
        textScale: 2,
      );
      Future<void> check() async {
        expect(tester.takeException(), isNull);
        _expectTouchTargets(tester);
      }

      await check();
      await _tapText(tester, 'Empezar');
      await check();
      await _enter(tester, 0, 'Luz');
      await _tapText(tester, 'Ana');
      await check();
      await _tapText(tester, 'Siguiente');
      await _tapText(tester, 'Usar mi ubicación actual');
      await check();
      await _tapText(tester, 'Siguiente');
      await check();
      await _tapText(tester, 'Siguiente');
      await check();
      await _enter(tester, 0, '1234');
      await _enter(tester, 1, '1234');
      await _tapText(tester, 'Guardar PIN');
      await _tapText(tester, 'Siguiente');
      await check();
      await _tapText(tester, 'Siguiente');
      await check();
      await _tapText(tester, 'Ya lo activé en este teléfono');
      await _tapText(tester, 'Siguiente');
      await check();
    });
  });

  group('hub (RefugeScreen)', () {
    testWidgets('unconfigured: the entry is the onboarding', (tester) async {
      await pumpRefuge(
        tester,
        const RefugeScreen(),
        platform: FakeSafeZonePlatform(),
      );
      expect(find.text('Empezar'), findsOneWidget);
      expect(find.textContaining('Paso 1 de 8'), findsOneWidget);
    });

    testWidgets('unavailable device', (tester) async {
      await pumpRefuge(
        tester,
        const RefugeScreen(),
        platform: FakeSafeZonePlatform()..failWith = const UnavailableError(),
      );
      expect(find.text('No disponible en este dispositivo'), findsOneWidget);
      expect(find.textContaining('solo corren en Android'), findsOneWidget);
    });

    testWidgets('shows monitoring, permission health, config and history', (
      tester,
    ) async {
      final now = DateTime(2026, 10, 17, 15);
      final platform = _configuredPlatform(
        lastEvent: SafeZoneEvent(
          type: SafeZoneEventType.smsSent,
          atMillis: now.toUtc().millisecondsSinceEpoch,
          test: false,
        ),
        awaySinceMillis: now
            .subtract(const Duration(minutes: 30))
            .toUtc()
            .millisecondsSinceEpoch,
      );
      await pumpRefuge(
        tester,
        const RefugeScreen(),
        platform: platform,
        clock: FixedClock(now),
      );
      expect(find.text('Activo'), findsOneWidget);
      expect(
        find.textContaining('Fuera de casa desde hoy 14:30'),
        findsOneWidget,
      );
      expect(find.text('1 de 2'), findsOneWidget);
      expect(find.text('Concedido'), findsNWidgets(5));
      await _scrollTo(tester, find.text('Configuración'));
      expect(find.text('300 m'), findsOneWidget);
      expect(
        find.text('de 22:00 a 06:00 (cruza la medianoche)'),
        findsOneWidget,
      );
      await _scrollTo(tester, find.text('Últimos eventos'));
      expect(
        find.text(
          'SMS entregado a la red del operador (no confirma que lo '
          'recibieran)',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('hoy 15:00'), findsOneWidget);
      expect(find.textContaining('red del operador'), findsWidgets);
    });

    testWidgets('a missing permission offers its fix, with its rationale', (
      tester,
    ) async {
      final platform = _configuredPlatform(
        permissions: const SafePermissions(
          fineLocation: true,
          backgroundLocation: true,
          sendSms: false,
          notifications: true,
          batteryOptimizationIgnored: false,
        ),
      );
      await pumpRefuge(tester, const RefugeScreen(), platform: platform);
      expect(find.text('Falta'), findsOneWidget);
      expect(find.text('Recomendado'), findsOneWidget);
      await _tapText(tester, 'Conceder SMS');
      expect(find.text('Enviar SMS para Refugio'), findsOneWidget);
      expect(platform.calls, isNot(contains('requestPermission:sendSms')));
      await _tapText(tester, 'Continuar');
      expect(platform.calls, contains('requestPermission:sendSms'));
      expect(find.text('Falta'), findsNothing);
    });

    testWidgets('the real-SMS confirmation appears before a test send', (
      tester,
    ) async {
      final platform = _configuredPlatform();
      await pumpRefuge(tester, const RefugeScreen(), platform: platform);
      await _tapText(tester, 'Enviar mensaje de prueba');
      expect(find.text('Enviar un SMS real'), findsOneWidget);
      expect(find.textContaining('SMS real a 1 persona'), findsOneWidget);
      expect(platform.calls, isNot(contains('sendTestMessage')));
      await _tapText(tester, 'Cancelar');
      expect(platform.calls, isNot(contains('sendTestMessage')));
      await _tapText(tester, 'Enviar mensaje de prueba');
      await _tapText(tester, 'Enviar SMS real');
      expect(platform.calls, contains('sendTestMessage'));
    });

    testWidgets('the full-process test also confirms a real SMS first', (
      tester,
    ) async {
      final platform = _configuredPlatform();
      await pumpRefuge(tester, const RefugeScreen(), platform: platform);
      await _tapText(tester, 'Probar el proceso completo');
      expect(find.text('Probar el proceso completo'), findsWidgets);
      expect(find.textContaining('SMS real'), findsWidgets);
      expect(platform.calls, isNot(contains('runEndToEndTest')));
      await _tapText(tester, 'Iniciar prueba con SMS real');
      expect(platform.calls, contains('runEndToEndTest'));
    });

    testWidgets('stopping asks for a destructive confirmation', (tester) async {
      final platform = _configuredPlatform();
      await pumpRefuge(tester, const RefugeScreen(), platform: platform);
      await _tapText(tester, 'Detener monitoreo');
      expect(find.text('Detener el monitoreo'), findsOneWidget);
      expect(platform.calls, isNot(contains('stopMonitoring')));
      await _tapText(tester, 'Cancelar');
      expect(platform.calls, isNot(contains('stopMonitoring')));
      await _tapText(tester, 'Detener monitoreo');
      await tester.tap(
        find.descendant(
          of: find.byType(Dialog),
          matching: find.text('Detener monitoreo'),
        ),
      );
      await tester.pumpAndSettle();
      expect(platform.calls, contains('stopMonitoring'));
      await _scrollTo(tester, find.text('Reanudar monitoreo'));
      expect(find.text('Reanudar monitoreo'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Detenido'),
        -300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Detenido'), findsOneWidget);
    });

    testWidgets('an edit action opens the wizard at that step', (tester) async {
      await pumpRefuge(
        tester,
        const RefugeScreen(),
        platform: _configuredPlatform(),
      );
      await _tapText(tester, 'Editar casa');
      expect(find.textContaining('Paso 3 de 8'), findsOneWidget);
      expect(find.text('Cancelar'), findsOneWidget);
      await _tapText(tester, 'Cancelar');
      expect(find.text('Configuración'), findsOneWidget);
    });

    testWidgets('returning to the app re-reads the status', (tester) async {
      final platform = _configuredPlatform(
        permissions: const SafePermissions(
          fineLocation: true,
          backgroundLocation: false,
          sendSms: true,
          notifications: true,
          batteryOptimizationIgnored: true,
        ),
      );
      await pumpRefuge(tester, const RefugeScreen(), platform: platform);
      expect(find.text('Falta'), findsOneWidget);
      platform.status = statusWith(monitoring: true, permissions: allGranted);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.text('Falta'), findsNothing);
    });

    testWidgets('a live event shows up in the history', (tester) async {
      final platform = _configuredPlatform();
      await pumpRefuge(tester, const RefugeScreen(), platform: platform);
      platform.emit(
        SafeZoneEvent(
          type: SafeZoneEventType.countdownStarted,
          atMillis: DateTime(2026, 10, 17, 15).toUtc().millisecondsSinceEpoch,
          test: true,
        ),
      );
      await tester.pumpAndSettle();
      await _scrollTo(tester, find.text('Empezó la cuenta regresiva'));
      expect(find.textContaining('prueba'), findsWidgets);
    });

    testWidgets('fits at 200% text scale with 48 dp targets', (tester) async {
      await pumpRefuge(
        tester,
        const RefugeScreen(),
        platform: _configuredPlatform(
          permissions: const SafePermissions.none(),
          lastEvent: const SafeZoneEvent(
            type: SafeZoneEventType.suppressedDailyLimit,
            atMillis: 1760713200000,
            test: false,
          ),
        ),
        textScale: 2,
      );
      expect(tester.takeException(), isNull);
      _expectTouchTargets(tester);
      await _scrollTo(tester, find.text('Detener monitoreo'));
      expect(tester.takeException(), isNull);
      _expectTouchTargets(tester);
    });
  });
}
