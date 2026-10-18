enum EchoTrapTextRisk { noSignal, caution, highRisk }

class EchoTrapTextAssessment {
  const EchoTrapTextAssessment({required this.risk, required this.message});

  final EchoTrapTextRisk risk;
  final String message;
}

/// Flags risky requests in recognized speech; it does not identify the caller
/// or prove that a crime occurred.
EchoTrapTextAssessment assessEchoTrapText(String transcript) {
  final text = transcript.toLowerCase();
  final requestForSensitiveData = RegExp(
    r'\b(dime|dicta|indica|envía|envie|compart(e|a)|proporciona|ingresa|confirma|transfiere|deposita|gira|instala)\b.{0,60}\b(clave|contraseña|código|token|otp|dinero|transferencia|cuenta|anydesk|teamviewer)\b|\b(clave|contraseña|código|token|otp|dinero|transferencia|cuenta)\b.{0,60}\b(dime|dicta|indica|envía|envie|compart(e|a)|proporciona|ingresa|confirma|transfiere|deposita|gira)\b|\b(instala|descarga|conéctate|conectate)\b.{0,50}\b(anydesk|teamviewer|aplicación remota)\b',
  );
  if (requestForSensitiveData.hasMatch(text)) {
    return const EchoTrapTextAssessment(
      risk: EchoTrapTextRisk.highRisk,
      message:
          'Alerta roja: detectamos una solicitud de datos, dinero o acceso remoto. No los compartas; verifica por un canal oficial.',
    );
  }

  final sensitiveTopic = RegExp(
    r'\b(bcp|interbank|bbva|scotiabank|banco|policía|fiscalía|sunat|premio|deuda|préstamo|token|contraseña|código)\b',
  );
  if (sensitiveTopic.hasMatch(text)) {
    return const EchoTrapTextAssessment(
      risk: EchoTrapTextRisk.caution,
      message:
          'Precaución: menciona una entidad o asunto sensible. La voz y el número no prueban identidad.',
    );
  }

  return const EchoTrapTextAssessment(
    risk: EchoTrapTextRisk.noSignal,
    message:
        'No se halló una señal en este fragmento. Esto no significa que la llamada sea segura.',
  );
}
