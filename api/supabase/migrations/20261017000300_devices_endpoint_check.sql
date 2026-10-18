-- Anti-SSRF: el endpoint de Web Push lo entrega el navegador del usuario (no confiable).
-- Solo servicios push conocidos sobre https. La Edge Function vuelve a validar antes de enviar.
alter table public.devices
  add constraint devices_endpoint_allowed check (
    endpoint ~ '^https://(fcm\.googleapis\.com|android\.googleapis\.com|updates\.push\.services\.mozilla\.com|[a-z0-9-]+\.push\.services\.mozilla\.com|[a-z0-9.-]+\.push\.apple\.com|[a-z0-9.-]+\.notify\.windows\.com)/'
  );
