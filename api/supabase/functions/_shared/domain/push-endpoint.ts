const ALLOWED_HOSTS: RegExp[] = [
  /^fcm\.googleapis\.com$/,
  /^android\.googleapis\.com$/,
  /^updates\.push\.services\.mozilla\.com$/,
  /^[a-z0-9-]+\.push\.services\.mozilla\.com$/,
  /^[a-z0-9.-]+\.push\.apple\.com$/,
  /^[a-z0-9.-]+\.notify\.windows\.com$/,
];

/**
 * Anti-SSRF: solo servicios de Web Push conocidos, sobre https y puerto 443, sin credenciales en la URL.
 * El endpoint lo entrega el navegador del usuario, asi que se trata como no confiable.
 */
export function isAllowedPushEndpoint(raw: string): boolean {
  let u: URL;
  try {
    u = new URL(raw);
  } catch {
    return false;
  }
  if (u.protocol !== "https:" || u.username !== "" || u.password !== "") return false;
  if (u.port !== "" && u.port !== "443") return false;
  return ALLOWED_HOSTS.some((re) => re.test(u.hostname));
}
