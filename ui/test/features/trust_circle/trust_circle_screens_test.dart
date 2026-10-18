import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qhawix/core/widgets/guardian_mascot/guardian_mascot.dart';
import 'package:qhawix/core/widgets/mock_data_banner.dart';
import 'package:qhawix/core/widgets/toggle_row.dart';
import 'package:qhawix/features/trust_circle/domain/alert_preferences.dart';
import 'package:qhawix/features/trust_circle/domain/check_in.dart';
import 'package:qhawix/features/trust_circle/domain/trust_contact.dart';
import 'package:qhawix/features/trust_circle/view/add_contact_screen.dart';
import 'package:qhawix/features/trust_circle/view/alert_preferences_screen.dart';
import 'package:qhawix/features/trust_circle/view/check_in_screen.dart';
import 'package:qhawix/features/trust_circle/view/contact_detail_screen.dart';
import 'package:qhawix/features/trust_circle/view/family_keyword_screen.dart';
import 'package:qhawix/features/trust_circle/view/refuge_requests_screen.dart';
import 'package:qhawix/features/trust_circle/view/refuge_verification_screen.dart';
import 'package:qhawix/features/trust_circle/view/sos_screen.dart';
import 'package:qhawix/features/trust_circle/view/trust_circle_screen.dart';

import 'test_support.dart';

const _tall = Size(360, 6000);

final _addButton = find.widgetWithText(FilledButton, 'Agregar contacto');

final _remoteRefugeRow = find.ancestor(
  of: find.text('Puede pedir mi Refugio'),
  matching: find.byType(ToggleRow),
);

final _screens = <String, Widget Function()>{
  'overview': () => const TrustCircleScreen(),
  'add contact': () => const AddContactScreen(),
  'contact detail': () => const ContactDetailScreen(contactId: 'c1'),
  'alert preferences': () => const AlertPreferencesScreen(),
  'SOS': () => const SosScreen(),
  'check-in': () => const CheckInScreen(),
  'refuge requests': () => const RefugeRequestsScreen(),
  'refuge verification': () => const RefugeVerificationScreen(requestId: 'r1'),
  'family keyword': () => const FamilyKeywordScreen(),
};

Future<void> _tapText(WidgetTester tester, String text) async {
  final finder = find.text(text);
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  group('every screen', () {
    for (final entry in _screens.entries) {
      group(entry.key, () {
        testWidgets('shows the example-data banner and no mascot', (
          tester,
        ) async {
          await pumpModule(tester, entry.value());
          expect(find.byType(MockDataBanner), findsOneWidget);
          expect(find.text(MockDataBanner.label), findsOneWidget);
          expect(find.byType(GuardianMascot), findsNothing);
        });

        testWidgets('does not overflow at 200% text scale', (tester) async {
          await pumpModule(tester, entry.value(), textScale: 2, size: _tall);
          expect(tester.takeException(), isNull);
        });

        testWidgets('interactive targets are at least 48 dp tall', (
          tester,
        ) async {
          await pumpModule(tester, entry.value(), size: _tall);
          final targets = <Finder>[
            find.byType(InkWell),
            find.byWidgetPredicate((w) => w is ButtonStyleButton),
          ];
          for (final finder in targets) {
            for (final element in finder.evaluate()) {
              final box = element.renderObject! as RenderBox;
              expect(
                box.size.height,
                greaterThanOrEqualTo(48),
                reason: '${element.widget.runtimeType} is smaller than 48 dp',
              );
            }
          }
        });

        testWidgets('never claims that something was delivered', (
          tester,
        ) async {
          await pumpModule(tester, entry.value(), size: _tall);
          expect(find.textContaining(claimsDelivery), findsNothing);
        });
      });
    }
  });

  group('overview', () {
    testWidgets('lists contacts with their kind and state as text', (
      tester,
    ) async {
      await pumpModule(tester, const TrustCircleScreen(), size: _tall);
      expect(find.text('Ana Ejemplo'), findsOneWidget);
      expect(find.text('Mamá (ejemplo)'), findsOneWidget);
      expect(find.text('Activo'), findsNWidgets(3));
      expect(find.text('En pausa'), findsOneWidget);
      expect(find.text('Con la app'), findsNWidgets(2));
      expect(find.text('Sin la app'), findsNWidgets(2));
      expect(find.text('3 de 4 activos'), findsOneWidget);
    });

    testWidgets('has no waiting-for-acceptance wording for contacts', (
      tester,
    ) async {
      await pumpModule(tester, const TrustCircleScreen(), size: _tall);
      expect(find.text('Invitación pendiente'), findsNothing);
      expect(find.textContaining('acepte'), findsNothing);
      expect(find.textContaining('acepta'), findsNothing);
      expect(find.text('Invitación a instalar pendiente'), findsOneWidget);
    });

    testWidgets('shows the request waiting and the quick actions', (
      tester,
    ) async {
      await pumpModule(tester, const TrustCircleScreen(), size: _tall);
      expect(find.text('1 solicitud de Refugio'), findsOneWidget);
      for (final label in [
        'SOS',
        'Llegada segura',
        'Palabra clave familiar',
        'Preferencias de alertas',
      ]) {
        expect(find.text(label), findsOneWidget);
      }
    });

    testWidgets('states that QHAWIX does not guarantee a response', (
      tester,
    ) async {
      await pumpModule(tester, const TrustCircleScreen(), size: _tall);
      expect(find.textContaining('no garantiza'), findsOneWidget);
    });

    testWidgets('opens each destination from its row', (tester) async {
      await pumpModule(tester, const TrustCircleScreen(), size: _tall);
      await _tapText(tester, 'SOS');
      expect(find.text('Pedir ayuda a tu red'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await _tapText(tester, 'Agregar contacto');
      expect(find.text('Agrega a alguien de confianza'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await _tapText(tester, 'Ana Ejemplo');
      expect(find.text('Permisos'), findsOneWidget);
    });
  });

  group('add contact', () {
    testWidgets(
      'needs no app and no invitation, and asks for typed data only',
      (tester) async {
        await pumpModule(tester, const AddContactScreen(), size: _tall);
        expect(find.text('Consentimiento mutuo'), findsNothing);
        expect(find.textContaining('No necesita tener la app'), findsOneWidget);
        expect(find.byType(TextField), findsNWidgets(2));
        expect(find.textContaining('Avísale que la agregaste'), findsOneWidget);
      },
    );

    testWidgets('asks for the missing data and adds nobody', (tester) async {
      await pumpModule(tester, const AddContactScreen(), size: _tall);
      await tester.ensureVisible(_addButton);
      await tester.tap(_addButton);
      await tester.pumpAndSettle();
      expect(find.text('Escribe el nombre de la persona.'), findsOneWidget);
      expect(
        find.text('Escribe el número con código de país.'),
        findsOneWidget,
      );
      expect(viewModelOf(tester).contacts, hasLength(4));
    });

    testWidgets(
      'adds the contact active and without the app, sending nothing',
      (tester) async {
        await pumpModule(tester, const AddContactScreen(), size: _tall);
        await tester.enterText(find.byType(TextField).first, 'Eli Ejemplo');
        await tester.enterText(find.byType(TextField).last, '+51 000 000 009');
        await tester.ensureVisible(_addButton);
        await tester.tap(_addButton);
        await tester.pumpAndSettle();
        expect(find.text('Contacto agregado'), findsOneWidget);
        expect(find.text('Eli Ejemplo'), findsOneWidget);
        expect(find.text('Activo'), findsOneWidget);
        expect(find.text('Sin la app'), findsOneWidget);
        expect(
          find.textContaining('No se envió ningún mensaje'),
          findsOneWidget,
        );
        expect(find.text('Invitación pendiente'), findsNothing);
        expect(find.text('Invitación a instalar pendiente'), findsNothing);
        expect(find.textContaining(claimsDelivery), findsNothing);
        final added = viewModelOf(tester).contacts.last;
        expect(added.status, ContactStatus.active);
        expect(added.kind, ContactKind.phoneOnly);
        expect(added.installInvitePending, isFalse);
      },
    );
  });

  group('contact detail', () {
    testWidgets('changes a permission', (tester) async {
      await pumpModule(
        tester,
        const ContactDetailScreen(contactId: 'c2'),
        size: _tall,
      );
      final vm = viewModelOf(tester);
      expect(vm.contactById('c2')!.permissions.maySeeTemporaryLocation, isTrue);
      await _tapText(tester, 'Incluir mi ubicación en los mensajes de SOS');
      expect(
        vm.contactById('c2')!.permissions.maySeeTemporaryLocation,
        isFalse,
      );
      expect(
        find.textContaining('Ejemplo: el cambio se guardó solo'),
        findsOneWidget,
      );
    });

    testWidgets('an app contact keeps push first and picks the fallback', (
      tester,
    ) async {
      await pumpModule(
        tester,
        const ContactDetailScreen(contactId: 'c1'),
        size: _tall,
      );
      expect(find.textContaining('1.º Notificación push'), findsOneWidget);
      await _tapText(tester, 'WhatsApp');
      expect(
        viewModelOf(tester).contactById('c1')!.channel,
        AlertChannel.whatsapp,
      );
    });

    testWidgets(
      'an app contact can ask for Refuge and is not offered the invite',
      (tester) async {
        await pumpModule(
          tester,
          const ContactDetailScreen(contactId: 'c1'),
          size: _tall,
        );
        final row = tester.widget<ToggleRow>(_remoteRefugeRow);
        expect(row.onChanged, isNotNull);
        expect(row.value, isTrue);
        expect(find.text('Invitar a instalar QHAWIX'), findsNothing);
      },
    );

    testWidgets('a phone-only contact offers SMS and WhatsApp only', (
      tester,
    ) async {
      await pumpModule(
        tester,
        const ContactDetailScreen(contactId: 'c2'),
        size: _tall,
      );
      expect(find.text('Sin la app'), findsOneWidget);
      expect(find.textContaining('1.º'), findsNothing);
      expect(
        find.textContaining('Sin la app, los avisos van por SMS'),
        findsOneWidget,
      );
      expect(find.text('SMS'), findsOneWidget);
      expect(find.text('WhatsApp'), findsOneWidget);
      expect(find.textContaining('push'), findsNothing);
      await _tapText(tester, 'SMS');
      expect(viewModelOf(tester).contactById('c2')!.channel, AlertChannel.sms);
    });

    testWidgets(
      'remote Refuge is off and disabled with its reason and the invite',
      (tester) async {
        await pumpModule(
          tester,
          const ContactDetailScreen(contactId: 'c2'),
          size: _tall,
        );
        final row = tester.widget<ToggleRow>(_remoteRefugeRow);
        expect(row.value, isFalse);
        expect(row.onChanged, isNull);
        expect(
          find.text('Necesita la app: sin ella no puede pedirlo.'),
          findsOneWidget,
        );
        expect(find.text('Invitar a instalar QHAWIX'), findsOneWidget);
      },
    );

    testWidgets('the optional invite stays honest and then shows as pending', (
      tester,
    ) async {
      await pumpModule(
        tester,
        const ContactDetailScreen(contactId: 'c2'),
        size: _tall,
      );
      await _tapText(tester, 'Invitar a instalar QHAWIX');
      expect(
        find.text('Ejemplo: no se envió ninguna invitación.'),
        findsOneWidget,
      );
      expect(find.textContaining(claimsDelivery), findsNothing);
      expect(find.text('Invitación a instalar pendiente'), findsOneWidget);
      expect(find.text('Invitar a instalar QHAWIX'), findsNothing);
      final contact = viewModelOf(tester).contactById('c2')!;
      expect(contact.installInvitePending, isTrue);
      expect(contact.kind, ContactKind.phoneOnly);
    });

    testWidgets('pauses and resumes', (tester) async {
      await pumpModule(
        tester,
        const ContactDetailScreen(contactId: 'c1'),
        size: _tall,
      );
      await _tapText(tester, 'Pausar contacto');
      expect(find.text('Reanudar contacto'), findsOneWidget);
      expect(
        viewModelOf(tester).contactById('c1')!.status,
        ContactStatus.paused,
      );
    });

    testWidgets(
      'asks for confirmation before removing, stating the consequences',
      (tester) async {
        await pumpModule(tester, const TrustCircleScreen(), size: _tall);
        await _tapText(tester, 'Ana Ejemplo');
        await _tapText(tester, 'Quitar de mi red');
        expect(find.text('Quitar a Ana Ejemplo'), findsOneWidget);
        expect(find.textContaining('No se puede deshacer'), findsOneWidget);
        expect(viewModelOf(tester).contactById('c1'), isNotNull);

        await _tapText(tester, 'Cancelar');
        expect(find.text('Quitar a Ana Ejemplo'), findsNothing);
        expect(viewModelOf(tester).contactById('c1'), isNotNull);

        await _tapText(tester, 'Quitar de mi red');
        await tester.tap(find.widgetWithText(FilledButton, 'Quitar de mi red'));
        await tester.pumpAndSettle();
        expect(viewModelOf(tester).contactById('c1'), isNull);
        expect(find.textContaining('No se avisó a nadie'), findsOneWidget);
      },
    );
  });

  group('alert preferences', () {
    testWidgets('states the delivery limit and lists the three events', (
      tester,
    ) async {
      await pumpModule(tester, const AlertPreferencesScreen(), size: _tall);
      expect(
        find.textContaining('depende de que tu contacto tenga la app'),
        findsOneWidget,
      );
      for (final title in [
        'Voz clonada detectada',
        'Pago retenido',
        'Refugio activado',
      ]) {
        expect(find.text(title), findsOneWidget);
      }
    });

    testWidgets('toggles who hears about an event', (tester) async {
      await pumpModule(tester, const AlertPreferencesScreen(), size: _tall);
      final vm = viewModelOf(tester);
      expect(vm.alertPreferences.recipientsOf(AlertEventKind.paymentHold), {
        'c1',
      });
      await tester.ensureVisible(find.text('Mamá (ejemplo)').at(1));
      await tester.tap(find.text('Mamá (ejemplo)').at(1));
      await tester.pumpAndSettle();
      expect(vm.alertPreferences.recipientsOf(AlertEventKind.paymentHold), {
        'c1',
        'c2',
      });
    });

    testWidgets('lets a phone-only contact be a recipient and says how', (
      tester,
    ) async {
      await pumpModule(tester, const AlertPreferencesScreen(), size: _tall);
      expect(find.text('Mamá (ejemplo)'), findsNWidgets(3));
      expect(
        find.text(
          'Sin la app: SMS o WhatsApp que envías tú desde tu teléfono.',
        ),
        findsNWidgets(6),
      );
    });

    testWidgets('changes the fallback channel', (tester) async {
      await pumpModule(tester, const AlertPreferencesScreen(), size: _tall);
      await _tapText(tester, 'WhatsApp');
      expect(
        viewModelOf(tester).alertPreferences.fallbackChannel,
        AlertChannelChoice.whatsapp,
      );
    });
  });

  group('SOS', () {
    testWidgets('cannot be sent without explicit consent', (tester) async {
      await pumpModule(tester, const SosScreen(), size: _tall);
      final send = find.widgetWithText(FilledButton, 'Enviar SOS');
      expect(tester.widget<FilledButton>(send).onPressed, isNull);
      await _tapText(
        tester,
        'Acepto compartir mi ubicación durante 30 minutos',
      );
      expect(tester.widget<FilledButton>(send).onPressed, isNotNull);
    });

    testWidgets('shows a visible cancel and the honest limit', (tester) async {
      await pumpModule(tester, const SosScreen(), size: _tall);
      expect(find.text('Cancelar'), findsOneWidget);
      expect(
        find.textContaining('no garantiza una respuesta de emergencia'),
        findsOneWidget,
      );
    });

    testWidgets('says per recipient what needs the app', (tester) async {
      await pumpModule(tester, const SosScreen(), size: _tall);
      expect(find.text('Mamá (ejemplo)'), findsOneWidget);
      expect(
        find.textContaining('La ubicación en vivo requiere la app.'),
        findsNWidgets(2),
      );
      expect(
        find.text('Con la app: notificación y ubicación temporal en vivo.'),
        findsOneWidget,
      );
      expect(find.textContaining('lo envías tú'), findsOneWidget);
    });

    testWidgets('the duration is part of the consent line', (tester) async {
      await pumpModule(tester, const SosScreen(), size: _tall);
      await _tapText(tester, '2 horas');
      expect(
        find.text('Acepto compartir mi ubicación durante 2 horas'),
        findsOneWidget,
      );
    });

    testWidgets('answers that no notice was sent', (tester) async {
      await pumpModule(tester, const SosScreen(), size: _tall);
      await _tapText(
        tester,
        'Acepto compartir mi ubicación durante 30 minutos',
      );
      await _tapText(tester, 'Enviar SOS');
      expect(
        find.textContaining('Ejemplo: no se envió ningún aviso'),
        findsOneWidget,
      );
      expect(find.textContaining(claimsDelivery), findsNothing);
      expect(find.text('Cancelar'), findsNothing);
    });

    testWidgets('cancel leaves without sending', (tester) async {
      await pumpModule(
        tester,
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push<void>(
                MaterialPageRoute<void>(builder: (_) => const SosScreen()),
              ),
              child: const Text('abrir'),
            ),
          ),
        ),
        size: _tall,
      );
      await _tapText(tester, 'abrir');
      await _tapText(tester, 'Cancelar');
      expect(find.text('abrir'), findsOneWidget);
    });
  });

  group('check-in', () {
    testWidgets('schedules a window and shows it waiting', (tester) async {
      await pumpModule(tester, const CheckInScreen(), size: _tall);
      expect(find.text('Sin ventana activa'), findsWidgets);
      await _tapText(tester, 'Iniciar ventana');
      expect(find.text('Esperando confirmación'), findsWidgets);
      expect(find.text('Confirmar que llegué'), findsOneWidget);
    });

    testWidgets('turns overdue when the window ends and says what happens', (
      tester,
    ) async {
      final clock = await pumpModule(
        tester,
        const CheckInScreen(),
        size: _tall,
      );
      await _tapText(tester, 'Iniciar ventana');
      clock.time = clock.time.add(const Duration(hours: 2));
      await tester.pump(const Duration(hours: 2));
      expect(find.text('Ventana vencida'), findsWidgets);
      expect(find.textContaining('no se avisó a nadie'), findsOneWidget);
      expect(find.textContaining('Qué pasa si vence'), findsOneWidget);
    });

    testWidgets('says who needs the app to be warned when it is overdue', (
      tester,
    ) async {
      await pumpModule(tester, const CheckInScreen(), size: _tall);
      expect(
        find.textContaining('sin la app, el servidor no le avisa solo'),
        findsNWidgets(2),
      );
      expect(find.textContaining('Mamá (ejemplo): sin la app'), findsOneWidget);
    });

    testWidgets('confirming marks the arrival', (tester) async {
      await pumpModule(tester, const CheckInScreen(), size: _tall);
      await _tapText(tester, 'Iniciar ventana');
      await _tapText(tester, 'Confirmar que llegué');
      expect(find.text('Llegada confirmada'), findsWidgets);
      expect(viewModelOf(tester).checkInStatus, CheckInStatus.confirmed);
    });
  });

  group('remote Refuge requests', () {
    testWidgets('lists the request and always offers to deny', (tester) async {
      await pumpModule(tester, const RefugeRequestsScreen(), size: _tall);
      expect(find.text('Ana Ejemplo pide activar tu Refugio'), findsOneWidget);
      expect(find.text('Rechazar solicitud'), findsOneWidget);
    });

    testWidgets('denying answers honestly and clears the request', (
      tester,
    ) async {
      await pumpModule(tester, const RefugeRequestsScreen(), size: _tall);
      await _tapText(tester, 'Rechazar solicitud');
      expect(
        find.textContaining('solicitud rechazada en la demostración'),
        findsOneWidget,
      );
      expect(find.text('Sin solicitudes pendientes'), findsOneWidget);
    });

    testWidgets('approving goes through the verification placeholder', (
      tester,
    ) async {
      await pumpModule(tester, const RefugeRequestsScreen(), size: _tall);
      await _tapText(tester, 'Verificar y aprobar');
      expect(
        find.textContaining('La verificación se agregará aquí'),
        findsOneWidget,
      );
      expect(viewModelOf(tester).pendingRequests, hasLength(1));
      expect(find.text('Rechazar solicitud'), findsOneWidget);
      await _tapText(tester, 'Aprobar (ejemplo)');
      expect(
        find.textContaining('no se activó ningún Refugio'),
        findsOneWidget,
      );
      expect(viewModelOf(tester).pendingRequests, isEmpty);
    });
  });

  group('family keyword', () {
    testWidgets('offers to create it when none exists', (tester) async {
      await pumpModule(tester, const FamilyKeywordScreen(), size: _tall);
      expect(find.text('Crear la palabra'), findsOneWidget);
      expect(find.text('Mostrar'), findsNothing);
    });

    testWidgets('stays hidden until the person taps Mostrar', (tester) async {
      await pumpModule(tester, const FamilyKeywordScreen(), size: _tall);
      await tester.enterText(find.byType(TextField), 'cóndor azul');
      await _tapText(tester, 'Crear palabra clave');
      expect(find.textContaining('No se compartió con nadie'), findsOneWidget);
      expect(find.text('cóndor azul'), findsNothing);
      expect(find.text('••••••••'), findsOneWidget);
      await _tapText(tester, 'Mostrar');
      expect(find.text('cóndor azul'), findsOneWidget);
      await _tapText(tester, 'Ocultar');
      expect(find.text('cóndor azul'), findsNothing);
    });

    testWidgets('rejects a too short keyword', (tester) async {
      await pumpModule(tester, const FamilyKeywordScreen(), size: _tall);
      await tester.enterText(find.byType(TextField), 'ab');
      await _tapText(tester, 'Crear palabra clave');
      expect(
        find.text('La palabra debe tener al menos 4 caracteres.'),
        findsOneWidget,
      );
      expect(find.text('Mostrar'), findsNothing);
    });

    testWidgets('gives the hang-up-and-call-back guidance', (tester) async {
      await pumpModule(tester, const FamilyKeywordScreen(), size: _tall);
      expect(
        find.textContaining('cuelga y vuelve a llamar por otro canal'),
        findsOneWidget,
      );
    });

    testWidgets('hides again when the app goes to the background', (
      tester,
    ) async {
      await pumpModule(tester, const FamilyKeywordScreen(), size: _tall);
      await tester.enterText(find.byType(TextField), 'cóndor azul');
      await _tapText(tester, 'Crear palabra clave');
      await _tapText(tester, 'Mostrar');
      for (final state in [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(state);
      }
      await tester.pumpAndSettle();
      expect(find.text('cóndor azul'), findsNothing);
    });
  });
}
