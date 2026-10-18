/** Minusculas, sin tildes, sin signos, espacios simples. */
export function normalize(input: string): string {
  return input
    .normalize("NFD")
    .replace(/[̀-ͯ]/g, "")
    .toLowerCase()
    .replace(/[^\p{L}\p{N}\s]/gu, " ")
    .replace(/\s+/g, " ")
    .trim();
}

/** Quita caracteres de control y recorta por el final. Todo texto de una llamada es dato no confiable. */
export function sanitize(input: string, maxChars = 4000): string {
  const clean = input.replace(/[\u0000-\u0008\u000b\u000c\u000e-\u001f\u007f]/g, " ");
  return clean.length > maxChars ? clean.slice(clean.length - maxChars) : clean;
}
