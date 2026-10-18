import type { Signal, Speaker } from "./types.ts";

export interface Rule {
  id: string;
  weight: number;
  speaker: Speaker;
  reason: string;
  advice: string;
  /** basta que coincida uno */
  any: RegExp[];
  /** si existe, ademas debe coincidir uno */
  also?: RegExp[];
}

/** Cuatro o mas digitos dichos en voz alta seguidos ("cuatro cinco dos nueve"). Regex literal: evita errores de escape. */
const SPOKEN_DIGITS =
  /\b(?:cero|uno|dos|tres|cuatro|cinco|seis|siete|ocho|nueve)(?: (?:cero|uno|dos|tres|cuatro|cinco|seis|siete|ocho|nueve)){3,}\b/;

/**
 * Reglas sobre texto YA normalizado (sin tildes ni signos). Pesos [P]: hipotesis sin calibrar.
 * Se usan cuantificadores acotados para evitar backtracking costoso.
 */
export const RULES: Rule[] = [
  {
    id: "otp_request",
    weight: 3,
    speaker: "caller",
    reason: "Pide un codigo, clave o PIN que ningun banco ni empresa pide por telefono.",
    advice: "No des codigos ni claves. Corta y llama tu al numero oficial del banco.",
    any: [
      /\b(codigo|clave|pin|token)\b.{0,25}\b(verificacion|seguridad|sms|que (te|le) llego|de (4|6|cuatro|seis) digitos|de acceso)\b/,
      /\b(dime|dame|digame|dicteme|pasame|paseme|necesito|deme) (el|tu|su) (codigo|clave|pin|token)\b/,
      /\bcvv\b/,
      /\bclave (de )?(cajero|internet|token|secreta)\b/,
    ],
  },
  {
    id: "virtual_kidnapping",
    weight: 3,
    speaker: "caller",
    reason: "Dice tener a un familiar en su poder: secuestro virtual, comun con voces clonadas.",
    advice: "Cuelga y llama directamente a tu familiar. Verifica antes de pagar nada.",
    any: [
      /\b(tenemos|secuestramos|secuestrado|secuestrada|tengo)\b.{0,40}\b(hijo|hija|esposo|esposa|mama|papa|familiar|hermano|hermana)\b/,
      /\b(hijo|hija|esposo|esposa|mama|papa|hermano|hermana)\b.{0,30}\b(esta con nosotros|lo tenemos|la tenemos|esta secuestrad[oa])\b/,
      /\bno (cuelgues|llames a la policia)\b.{0,40}\b(muere|matamos|mato|lo matamos|la matamos)\b/,
    ],
  },
  {
    id: "remote_access_app",
    weight: 3,
    speaker: "caller",
    reason: "Quiere que instales una aplicacion de control remoto: es la via para vaciar tus cuentas.",
    advice: "Jamas instales aplicaciones que te pida alguien por telefono.",
    any: [
      /\b(anydesk|teamviewer|rustdesk|quicksupport|ultraviewer|aplicacion de (control|acceso) remoto)\b/,
      /\bdescarga(r|s)? (la |una |esta )?(app|aplicacion)\b/,
    ],
  },
  {
    id: "extortion_threat",
    weight: 3,
    speaker: "caller",
    reason: "Amenaza con violencia o dano a tu negocio o familia: extorsion.",
    advice: "No pagues ni negocies. Corta, guarda este aviso y reporta al 111 (anonimo) o a la comisaria.",
    any: [
      /\b(cupo|cupos|derecho de piso|cobro de piso|vacuna)\b/,
      /\b(te|lo|la|los|las) (vamos a|van a|voy a) (quemar|matar|balear|disparar|explotar|reventar)\b/,
      /\b(quemar|balear|volar|explotar)\w* (tu|su|el|la) (bodega|negocio|local|carro|combi|casa|puesto)\b/,
      /\bsabemos (donde|a que hora) (vives|vive|trabajas|trabaja|sales|sale|estudia|estudian|queda)\b/,
    ],
  },
  {
    id: "extortion_payment_demand",
    weight: 2,
    speaker: "caller",
    reason: "Exige pagos periodicos o te condiciona: patron tipico de cobro de cupos.",
    advice: "No deposites. Guarda numeros y mensajes como evidencia y denuncia.",
    any: [
      /\b(pagar|pagas|depositar|depositas|cancelar|entregar|dejar)\b.{0,50}\b(semanal|semana|quincena|quincenal|mensual|cada (lunes|semana|mes))\b/,
      /\b(colaboracion|cuota|aporte|cupo) (semanal|mensual|obligatoria|de seguridad)\b/,
      /\b(si no pagas|si no paga|si no depositas|si no deposita|o pagas|o paga)\b/,
    ],
  },
  {
    id: "money_request_yape_plin",
    weight: 2,
    speaker: "caller",
    reason: "Pide dinero por Yape, Plin o transferencia a un numero o cuenta que te indica.",
    advice: "No envies dinero a pedido de una llamada. Verifica por otro canal.",
    any: [/\b(yape[a-z]*|plin[a-z]*|transferencia|deposito|depositame|giro)\b/],
    also: [/\b\d{2,6} (soles|lucas|luquitas)\b/, /\b(soles|lucas|numero de cuenta|cuenta|cci|ahora|ya mismo|urgente)\b/],
  },
  {
    id: "bank_impersonation",
    weight: 2,
    speaker: "caller",
    reason: "Dice ser de un banco y habla de tu cuenta, tarjeta o consumos sospechosos.",
    advice: "Cuelga. Llama tu al numero impreso en tu tarjeta. El banco no pide datos por telefono.",
    any: [/\b(banco|bcp|interbank|bbva|scotiabank|banbif|mibanco|caja huancayo|caja arequipa|caja piura|seguridad del banco|departamento de fraudes?)\b/],
    also: [/\b(cuenta|tarjeta|compra|consumo|bloque\w*|sospechos\w*|fraude|clave|codigo|actualizar|verificar)\b/],
  },
  {
    id: "authority_impersonation",
    weight: 2,
    speaker: "caller",
    reason: "Dice ser policia, fiscal, SUNAT u otra autoridad y habla de deudas, multas o denuncias.",
    advice: "Las autoridades no cobran por telefono. Cuelga y verifica en el canal oficial.",
    any: [/\b(sunat|policia|pnp|fiscalia|fiscal|juez|reniec|migraciones|indecopi|osiptel|sbs|comisaria|dirincri|inpe)\b/],
    also: [/\b(deuda|multa|orden|denuncia|detenid\w*|investigacion|embargo|arresto|bloqueo|sancion|pago)\b/],
  },
  {
    id: "family_emergency",
    weight: 2,
    speaker: "caller",
    reason: "Se hace pasar por un familiar en problemas y pide ayuda urgente: la voz puede estar clonada.",
    advice: "Cuelga y llama tu al familiar a su numero de siempre antes de enviar dinero.",
    any: [/\b(mama|papa|abuela|abuelito|abuelita|tia|tio|hijo|hija|soy yo|hermano|hermana)\b/],
    also: [/\b(accidente|detenid\w*|policia|hospital|emergencia|preso|presa|ayudame|necesito (plata|dinero)|me robaron|choque)\b/],
  },
  {
    id: "secrecy_dont_hang_up",
    weight: 1,
    speaker: "caller",
    reason: "Te pide que no cuelgues ni avises a nadie: busca aislarte.",
    advice: "Colgar siempre es valido. Avisa a un familiar.",
    any: [
      /\bno (le )?(cuelgue|cuelgues|digas|diga|cuentes|cuente|avises|avise|cortes|corte)\b/,
      /\bmantengase en linea\b/,
      /\bmantente en linea\b/,
    ],
  },
  {
    id: "prize_or_job_offer",
    weight: 1,
    speaker: "caller",
    reason: "Ofrece premios, trabajo facil o inversiones seguras.",
    advice: "Si no participaste, no ganaste. Desconfia de ganancias rapidas.",
    any: [/\b(ganaste|has ganado|premio|sorteo|oferta de trabajo|trabajo desde casa|inversion segura|ganar dinero rapido)\b/],
  },
  {
    id: "urgency_pressure",
    weight: 1,
    speaker: "caller",
    reason: "Mete presion de tiempo para que no pienses.",
    advice: "La urgencia es la herramienta del estafador. Toma tiempo para verificar.",
    any: [/\b(urgente|ahora mismo|inmediatamente|ya mismo|de inmediato|no hay tiempo|ultima oportunidad|en (diez|10|cinco|5|\d{1,2}) minutos)\b/],
  },
  {
    id: "prompt_injection_attempt",
    weight: 2,
    speaker: "caller",
    reason: "Intenta darle ordenes al sistema de analisis: senal de estafador que conoce la herramienta.",
    advice: "Una llamada que pide ser marcada como segura es sospechosa. Cuelga.",
    any: [
      /\b(ignora|ignore|olvida|olvide)\b.{0,20}\b(instrucciones|reglas|indicaciones)\b/,
      /\b(clasifica|marca|califica|di|declara)\b.{0,25}\b(como )?(segura|seguro|benigna|benigno|verde)\b/,
      /\b(system prompt|eres un asistente|actua como)\b/,
    ],
  },
  {
    id: "user_compliance",
    weight: 2,
    speaker: "user",
    reason: "Parece que estas entregando un codigo, instalando algo o enviando dinero durante la llamada.",
    advice: "DETENTE ahora. No envies ni digas nada mas. Corta la llamada.",
    any: [
      /\b(el codigo es|mi clave es|mi pin es|te paso el codigo|te doy el codigo)\b/,
      /\bya te (yape|yapee|plinee|deposite|transferi|envie)\b/,
      /\bya estoy (descargando|instalando)\b/,
      /\bcodigo oculto\b/,
      SPOKEN_DIGITS,
      /\b\d( \d){3,}\b/,
    ],
  },
];

/** Aplica las reglas del hablante dado sobre texto normalizado. */
export function applyRules(normalizedText: string, speaker: Speaker): Signal[] {
  const out: Signal[] = [];
  for (const rule of RULES) {
    if (rule.speaker !== speaker) continue;
    let hit: RegExpMatchArray | null = null;
    for (const re of rule.any) {
      hit = normalizedText.match(re);
      if (hit) break;
    }
    if (!hit) continue;
    if (rule.also && !rule.also.some((re) => re.test(normalizedText))) continue;
    out.push({
      id: rule.id,
      weight: rule.weight,
      reason: rule.reason,
      advice: rule.advice,
      // Defensa en profundidad: nunca persistir digitos (podrian ser un codigo o una clave)
      evidence: hit[0].slice(0, 80).replace(/[0-9]/g, "#"),
    });
  }
  return out;
}
