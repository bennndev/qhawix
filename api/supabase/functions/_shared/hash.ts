import { env } from "./env.ts";

/** SHA-256 hex con pepper. El numero del llamante solo se guarda asi. */
export async function hashNumber(e164: string): Promise<string> {
  const data = new TextEncoder().encode(env("HASH_PEPPER") + "|" + e164.trim());
  const digest = await crypto.subtle.digest("SHA-256", data);
  return [...new Uint8Array(digest)].map((b) => b.toString(16).padStart(2, "0")).join("");
}
