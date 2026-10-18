import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qhawix/core/theme/app_theme.dart';
import 'package:qhawix/core/widgets/initials_avatar.dart';
import 'package:qhawix/core/widgets/key_value_row.dart';
import 'package:qhawix/core/widgets/page_header.dart';
import 'package:qhawix/core/widgets/segmented_choice.dart';
import 'package:qhawix/core/widgets/status_chip.dart';
import 'package:qhawix/core/widgets/summary_panel.dart';
import 'package:qhawix/core/widgets/toggle_row.dart';

import 'test_app.dart';

/// The glyph the switch paints in its thumb for the given state.
IconData? _thumbIcon(WidgetTester tester, {required bool selected}) {
  final icon = tester.widget<Switch>(find.byType(Switch)).thumbIcon!.resolve({
    if (selected) WidgetState.selected,
  });
  return icon?.icon;
}

void main() {
  group('PageHeader', () {
    testWidgets('shows the title as a header and the subtitle', (tester) async {
      await tester.pumpWidget(
        qhawixApp(const PageHeader(title: 'Red', subtitle: 'Tu círculo')),
      );
      expect(find.text('Red'), findsOneWidget);
      expect(find.text('Tu círculo'), findsOneWidget);
      expect(
        tester.getSemantics(find.text('Red')),
        matchesSemantics(label: 'Red', isHeader: true),
      );
    });

    testWidgets('survives 200% text scale', (tester) async {
      usePhoneSurface(tester);
      await tester.pumpWidget(
        qhawixApp(
          const PageHeader(
            title: 'Una palabra que solo tu familia sabe',
            subtitle: 'Sirve para comprobar que quien llama es quien dice ser.',
          ),
          textScale: 2,
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('SummaryPanel', () {
    testWidgets('shows label, value and caption', (tester) async {
      await tester.pumpWidget(
        qhawixApp(
          const SummaryPanel(
            label: 'Estado del círculo',
            value: '2 de 4 activos',
            caption: '1 pendiente',
            icon: Icons.group_outlined,
          ),
        ),
      );
      expect(find.text('Estado del círculo'), findsOneWidget);
      expect(find.text('2 de 4 activos'), findsOneWidget);
      expect(find.text('1 pendiente'), findsOneWidget);
    });

    testWidgets('is a 48 dp button only when tapped', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        qhawixApp(
          SummaryPanel(label: 'Estado', value: 'Listo', onTap: () => taps++),
        ),
      );
      expect(
        tester.getSize(find.byType(InkWell)).height,
        greaterThanOrEqualTo(48),
      );
      await tester.tap(find.byType(InkWell));
      expect(taps, 1);
    });

    testWidgets('survives 200% text scale', (tester) async {
      usePhoneSurface(tester);
      await tester.pumpWidget(
        qhawixApp(
          const SummaryPanel(
            icon: Icons.group_outlined,
            label: 'Estado del círculo',
            value: '2 de 4 activos',
            caption: '1 con invitación pendiente · 1 en pausa',
          ),
          textScale: 2,
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('StatusChip', () {
    for (final tone in StatusTone.values) {
      testWidgets('${tone.name} carries icon and text', (tester) async {
        await tester.pumpWidget(
          qhawixApp(StatusChip(label: 'Estado', icon: Icons.check, tone: tone)),
        );
        expect(find.text('Estado'), findsOneWidget);
        expect(find.byIcon(Icons.check), findsOneWidget);
      });
    }

    testWidgets('renders in dark theme and wraps at 200% scale', (
      tester,
    ) async {
      usePhoneSurface(tester);
      await tester.pumpWidget(
        qhawixApp(
          const StatusChip(
            label: 'Esperando confirmación de llegada',
            icon: Icons.schedule,
            tone: StatusTone.caution,
          ),
          theme: AppTheme.dark(),
          textScale: 2,
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('KeyValueRow', () {
    testWidgets('shows both sides and a single semantic label', (tester) async {
      await tester.pumpWidget(
        qhawixApp(const KeyValueRow(label: 'Canal', value: 'SMS')),
      );
      expect(find.text('Canal'), findsOneWidget);
      expect(find.text('SMS'), findsOneWidget);
      expect(
        tester.getSemantics(find.byType(KeyValueRow)),
        matchesSemantics(label: 'Canal: SMS'),
      );
    });

    testWidgets('wraps long values at 200% scale', (tester) async {
      usePhoneSurface(tester);
      await tester.pumpWidget(
        qhawixApp(
          const KeyValueRow(
            label: 'Canal de respaldo',
            value: 'Mensaje de texto o WhatsApp según el contacto',
          ),
          textScale: 2,
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('ToggleRow', () {
    testWidgets('toggles when the row is tapped', (tester) async {
      var value = false;
      await tester.pumpWidget(
        qhawixApp(
          StatefulBuilder(
            builder: (context, setState) => ToggleRow(
              title: 'Recibir alertas',
              description: 'Voz clonada y pagos retenidos.',
              value: value,
              onChanged: (v) => setState(() => value = v),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Recibir alertas'));
      await tester.pump();
      expect(value, isTrue);
      expect(_thumbIcon(tester, selected: true), Icons.check);
    });

    testWidgets('the thumb shows a cross when off', (tester) async {
      await tester.pumpWidget(
        qhawixApp(
          ToggleRow(title: 'Recibir alertas', value: false, onChanged: (_) {}),
        ),
      );
      expect(_thumbIcon(tester, selected: false), Icons.close);
    });

    testWidgets('is at least 56 dp tall and exposes toggled semantics', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        qhawixApp(
          ToggleRow(
            title: 'Recibir alertas',
            description: 'Voz clonada.',
            value: true,
            onChanged: (_) {},
          ),
        ),
      );
      expect(
        tester.getSize(find.byType(InkWell)).height,
        greaterThanOrEqualTo(56),
      );
      expect(
        tester.getSemantics(find.byType(InkWell)),
        matchesSemantics(
          label: 'Recibir alertas. Voz clonada.',
          hasToggledState: true,
          isToggled: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('a null callback disables it', (tester) async {
      await tester.pumpWidget(
        qhawixApp(
          const ToggleRow(
            title: 'Recibir alertas',
            value: true,
            onChanged: null,
          ),
        ),
      );
      await tester.tap(find.text('Recibir alertas'));
      await tester.pump();
      expect(tester.widget<Switch>(find.byType(Switch)).onChanged, isNull);
    });

    testWidgets('survives 200% text scale', (tester) async {
      usePhoneSurface(tester);
      await tester.pumpWidget(
        qhawixApp(
          ToggleRow(
            title: 'Puede ver mi ubicación temporal',
            description: 'Solo durante un SOS y por el tiempo que elijas.',
            value: true,
            onChanged: (_) {},
          ),
          textScale: 2,
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('SegmentedChoice', () {
    Widget choice(ValueChanged<int> onChanged, {int? selected = 1}) =>
        SegmentedChoice<int>(
          semanticLabel: 'Duración',
          selected: selected,
          onChanged: onChanged,
          options: const [
            SegmentOption(value: 1, label: '15 minutos'),
            SegmentOption(value: 2, label: '30 minutos'),
            SegmentOption(value: 3, label: '1 hora'),
          ],
        );

    testWidgets('marks the selected option with a check', (tester) async {
      await tester.pumpWidget(qhawixApp(choice((_) {})));
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('reports the tapped value', (tester) async {
      int? picked;
      await tester.pumpWidget(qhawixApp(choice((v) => picked = v)));
      await tester.tap(find.text('1 hora'));
      expect(picked, 3);
    });

    testWidgets('every option is at least 48 dp', (tester) async {
      await tester.pumpWidget(qhawixApp(choice((_) {})));
      for (final element in find.byType(InkWell).evaluate()) {
        final size = (element.renderObject! as RenderBox).size;
        expect(size.height, greaterThanOrEqualTo(48));
        expect(size.width, greaterThanOrEqualTo(48));
      }
    });

    testWidgets('exposes selected and exclusive-group semantics', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(qhawixApp(choice((_) {})));
      expect(
        tester.getSemantics(find.text('15 minutos')),
        matchesSemantics(
          label: '15 minutos',
          isButton: true,
          isSelected: true,
          hasSelectedState: true,
          isInMutuallyExclusiveGroup: true,
          hasTapAction: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('ignores taps when disabled', (tester) async {
      await tester.pumpWidget(
        qhawixApp(
          const SegmentedChoice<int>(
            selected: 1,
            onChanged: null,
            options: [
              SegmentOption(value: 1, label: 'A'),
              SegmentOption(value: 2, label: 'B'),
            ],
          ),
        ),
      );
      await tester.tap(find.text('B'));
      expect(tester.takeException(), isNull);
    });

    testWidgets('wraps onto more lines at 200% scale', (tester) async {
      usePhoneSurface(tester);
      await tester.pumpWidget(qhawixApp(choice((_) {}), textScale: 2));
      expect(tester.takeException(), isNull);
    });
  });

  group('InitialsAvatar', () {
    test('takes the first letter of the first two words', () {
      expect(InitialsAvatar.initialsOf('Ana Ejemplo'), 'AE');
      expect(InitialsAvatar.initialsOf('  beto   de la  Cruz '), 'BD');
      expect(InitialsAvatar.initialsOf('Carla'), 'C');
      expect(InitialsAvatar.initialsOf('   '), '?');
      expect(InitialsAvatar.initialsOf('éric'), 'É');
    });

    testWidgets('is a 48 dp circle excluded from semantics', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        qhawixApp(const InitialsAvatar(name: 'Ana Ejemplo')),
      );
      expect(find.text('AE'), findsOneWidget);
      expect(
        tester.getSize(find.byType(InitialsAvatar)),
        const Size.square(48),
      );
      expect(find.bySemanticsLabel('AE'), findsNothing);
      handle.dispose();
    });

    testWidgets('keeps its size at 200% scale', (tester) async {
      await tester.pumpWidget(
        qhawixApp(const InitialsAvatar(name: 'Ana Ejemplo'), textScale: 2),
      );
      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byType(InitialsAvatar)),
        const Size.square(48),
      );
    });
  });
}
