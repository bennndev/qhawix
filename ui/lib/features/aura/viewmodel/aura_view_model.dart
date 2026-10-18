import 'package:flutter/foundation.dart';

/// Local guidance, not a message analysis or an identity check.
enum AuraGuide {
  accessCode(
    'Me piden un código',
    'Cuida tus códigos',
    [
      'No compartas códigos de acceso, PIN ni contraseñas con quien te los pide.',
      'Interrumpe la conversación y verifica por un canal que ya conozcas, '
          'como la aplicación oficial de la institución.',
    ],
    'Base: Sentinel — señales de solicitud de OTP/PIN; '
        'Guardian Pago — verificación independiente (guía de QHAWIX).',
  ),
  paymentPressure(
    'Me presionan para pagar',
    'Verifica por otro canal',
    [
      'Toma una pausa antes de autorizar el pago.',
      'Comprueba la solicitud desde la aplicación oficial, el reverso de tu tarjeta '
          'o tu estado de cuenta. No uses el contacto que te dio quien solicita el pago.',
    ],
    'Base: Guardian Pago — verificación independiente (guía de QHAWIX).',
  );

  const AuraGuide(this.label, this.title, this.steps, this.basis);

  final String label;
  final String title;
  final List<String> steps;
  final String basis;
}

/// Only the person's selected local guide is kept, for this screen's lifetime.
class AuraViewModel extends ChangeNotifier {
  AuraGuide? _guide;

  AuraGuide? get guide => _guide;

  void select(AuraGuide? guide) {
    if (_guide == guide) return;
    _guide = guide;
    notifyListeners();
  }
}
