/** Normaliza un identificador de llamada (E.164, "sip:5199...@dominio", etc.) a "+<digitos>". Vacio si no hay digitos. */
export function toE164(raw: string | undefined | null): string {
  if (!raw) return "";
  const base = raw.replace(/^sips?:/i, "").split("@")[0].split(";")[0];
  const digits = base.replace(/[^0-9]/g, "");
  return digits ? "+" + digits : "";
}
