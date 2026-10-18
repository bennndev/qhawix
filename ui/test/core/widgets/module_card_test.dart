import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qhawix/core/widgets/module_card.dart';

import 'test_app.dart';

void main() {
  testWidgets('module icon is centered in a fixed leading column', (
    tester,
  ) async {
    usePhoneSurface(tester);
    await tester.pumpWidget(
      qhawixApp(
        const ModuleCard(
          icon: Icons.mail_outline,
          name: 'Sentinel',
          purpose: 'Analiza mensajes y comprobantes.',
          onTap: _doNothing,
        ),
      ),
    );

    final icon = find.byIcon(Icons.mail_outline);
    final column = find
        .ancestor(of: icon, matching: find.byType(SizedBox))
        .first;
    expect(tester.getSize(column), const Size(48, 48));
    expect(tester.getCenter(icon).dy, tester.getCenter(column).dy);
  });
}

void _doNothing() {}
