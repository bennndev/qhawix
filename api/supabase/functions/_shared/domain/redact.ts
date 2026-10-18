/**
 * Cuatro o mas digitos separados por hasta 3 simbolos o espacios cualquiera (coma, barra, guion...).
 * Excepcion de montos: solo palabras completas y sin distinguir mayusculas.
 */
const DIGIT_RUN =
  /\d(?:[^\p{L}\p{N}]{0,3}\d){3,}(?!\p{N}|\s*(?:soles|sol|lucas|luquitas|dolares)(?![\p{L}\p{N}]))/giu;
const SPOKEN_RUN =
  /\b(?:cero|uno|dos|tres|cuatro|cinco|seis|siete|ocho|nueve)(?:\s+(?:cero|uno|dos|tres|cuatro|cinco|seis|siete|ocho|nueve)){3,}\b/gi;

/**
 * Oculta codigos, PIN y numeros largos ANTES de guardar o enviar a un proveedor.
 * Los montos ("1500 soles") se conservan: son evidencia de extorsion.
 * 4 a 8 digitos -> [codigo oculto]; mas largos -> [numero oculto].
 */
export function redactSensitive(text: string): string {
  return text
    .replace(DIGIT_RUN, (m) => (m.replace(/[^0-9]/g, "").length <= 8 ? "[codigo oculto]" : "[numero oculto]"))
    .replace(SPOKEN_RUN, "[codigo oculto]");
}
