import { createHmac } from "node:crypto";
import { validTwilioSignature, xml } from "./twilio.ts";

Deno.env.set("TWILIO_AUTH_TOKEN", "token_de_prueba_no_real");

function expectedSig(url: string, params: Record<string, string>): string {
  const data = Object.keys(params).sort().reduce((acc, k) => acc + k + params[k], url);
  return createHmac("sha1", "token_de_prueba_no_real").update(data).digest("base64");
}

function assert(cond: boolean, msg: string) {
  if (!cond) throw new Error(msg);
}

Deno.test("acepta una firma valida", async () => {
  const url = "https://ejemplo.supabase.co/functions/v1/twilio-voice";
  const params = { CallSid: "CA123", To: "+51999000111", From: "+51999000222" };
  assert(await validTwilioSignature(url, params, expectedSig(url, params)), "debia ser valida");
});

Deno.test("rechaza firma alterada, parametros alterados o ausente", async () => {
  const url = "https://ejemplo.supabase.co/functions/v1/twilio-voice";
  const params = { CallSid: "CA123", To: "+51999000111" };
  const sig = expectedSig(url, params);
  assert(!(await validTwilioSignature(url, { ...params, To: "+51999000999" }, sig)), "param alterado");
  assert(!(await validTwilioSignature(url, params, sig.slice(0, -2) + "xx")), "firma alterada");
  assert(!(await validTwilioSignature(url, params, null)), "sin firma");
  assert(!(await validTwilioSignature(url + "?phase=end", params, sig)), "url distinta");
});

Deno.test("xml escapa caracteres peligrosos", () => {
  assert(xml('<a href="x">&</a>') === "&lt;a href=&quot;x&quot;&gt;&amp;&lt;/a&gt;", "escape");
});
