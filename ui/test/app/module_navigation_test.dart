import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:qhawix/app/module_activation_store.dart';
import 'package:qhawix/app/module_catalog.dart';
import 'package:qhawix/app/module_navigation.dart';

void main() {
  testWidgets('leaving EchoTrap returns to the Inicio menu', (tester) async {
    final router = GoRouter(
      initialLocation: '/inicio',
      routes: [
        GoRoute(
          path: '/inicio',
          builder: (context, state) => Scaffold(
            body: TextButton(
              onPressed: () =>
                  openModule(context, ModuleCatalog.byId(AppModuleId.echoTrap)),
              child: const Text('Abrir EchoTrap'),
            ),
          ),
        ),
        GoRoute(
          path: '/m/echotrap',
          builder: (context, state) => Scaffold(
            appBar: AppBar(
              leading: BackButton(onPressed: () => context.pop()),
              title: const Text('EchoTrap'),
            ),
          ),
        ),
      ],
    );
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => ModuleActivationStore(),
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.tap(find.text('Abrir EchoTrap'));
    await tester.pumpAndSettle();
    expect(find.text('EchoTrap'), findsOneWidget);
    expect(router.canPop(), isTrue);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Abrir EchoTrap'), findsOneWidget);
  });
}
