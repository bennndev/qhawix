-- Limita el análisis de voz sintética a un intento de pago por llamada.
alter table public.qhawix_calls
  add column voice_origin_attempted_at timestamptz;
