// Developer-only demo: switches between the eight Guardian mascot states, toggles reduced
// motion and the light/dark theme. The mascot uses the theme's colour roles (its defaults).
// Not part of the product UI.
import 'package:flutter/material.dart';

import '../core/widgets/guardian_mascot/guardian_mascot.dart';

const Map<GuardianMascotState, String> _labels = {
  GuardianMascotState.idle: 'Reposo',
  GuardianMascotState.thinking: 'Pensando',
  GuardianMascotState.working: 'Trabajando',
  GuardianMascotState.success: 'Éxito',
  GuardianMascotState.listening: 'Escuchando',
  GuardianMascotState.scanning: 'Analizando',
  GuardianMascotState.alert: 'Atención',
  GuardianMascotState.stealth: 'Discreto',
};

class GuardianMascotDemoApp extends StatefulWidget {
  const GuardianMascotDemoApp({super.key});

  @override
  State<GuardianMascotDemoApp> createState() => _GuardianMascotDemoAppState();
}

class _GuardianMascotDemoAppState extends State<GuardianMascotDemoApp> {
  GuardianMascotState _state = GuardianMascotState.idle;
  bool _reduceMotion = false;
  bool _dark = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Guardian de Comportamiento',
      debugShowCheckedModeBanner: false,
      themeMode: _dark ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal)),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal, brightness: Brightness.dark),
      ),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: _reduceMotion),
        child: child!,
      ),
      home: Scaffold(
        appBar: AppBar(title: const Text('Guardian de Comportamiento')),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: GuardianMascot(
                  state: _state,
                  size: 280,
                  onStateEnd: (state) => setState(() => _state = state),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Estado: ${_labels[_state]}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final state in GuardianMascotState.values)
                    ChoiceChip(
                      label: Text(_labels[state]!),
                      selected: _state == state,
                      onSelected: (_) => setState(() => _state = state),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Reducir movimiento'),
                value: _reduceMotion,
                onChanged: (v) => setState(() => _reduceMotion = v),
              ),
              SwitchListTile(
                title: const Text('Tema oscuro'),
                value: _dark,
                onChanged: (v) => setState(() => _dark = v),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
