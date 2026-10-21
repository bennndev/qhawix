# Escudo QR: notas personales por sitio (Atomic Memory)

Estado: código listo, sin verificar en dispositivo ni contra Atomic Memory real.

## Qué hace

En la revisión de un enlace, la persona puede guardar una nota breve sobre el
dominio exacto (por ejemplo, cómo lo verificó) y verla la próxima vez que
revise ese mismo dominio. Puede corregirla o borrarla.

## Límites

- La nota es contexto personal. No cambia el resultado de reputación, la
  política de apertura ni el bloqueo de amenazas conocidas. La tarjeta se
  muestra debajo de esas decisiones.
- No sale nada del dispositivo hasta que la persona toca «Ver mi nota»,
  «Guardar nota» o «Borrar nota». Solo se envían el dominio ASCII exacto y el
  texto de la nota; nunca la URL completa.
- Apagada por defecto: requiere `QR_SITE_NOTES_ENABLED=true` en la app,
  sesión de Supabase y `ATOMICMEMORY_API_KEY` en los secretos de la función.
- Un dominio parecido (otro host, Unicode o punycode distinto) no recibe la
  nota de otro.

## Diseño

- `api/supabase/functions/qr-site-notes`: valida estrictamente, resuelve el
  usuario con `/auth/v1/user`, deriva el sujeto `qhawix:user:<uuid>` en el
  servidor y aplica la cuota diaria durable `qr_site_note_consume_quota`
  (120/día).
- Una nota por dominio. Cada nota lleva `metadata.externalId` =
  `qhawix-site-note-v1-<sha256(dominio)>` y se lee con la consulta exacta
  documentada `GET /v1/memories/by-external-id/{externalId}?user_id=…`. No se
  usa búsqueda semántica, así que una nota no desaparece cuando la persona
  acumula notas de otros sitios (hay una prueba con 25 sitios más).
- Corregir: se escribe la nueva versión con el mismo `externalId`, se borra la
  anterior por su id y se confirma que la consulta exacta devuelve la nueva.
  Si la anterior no se puede borrar, se revierte la nueva y la nota anterior
  queda como única (`correction_not_applied`).
- Borrar: cuenta solo si cada `DELETE /v1/memories/{id}` responde 200 con
  `{ "success": true }` y la consulta exacta termina en 404.
- El texto se redacta en el servidor (códigos, números largos, correos) antes
  de guardarse. A Atomic Memory solo llegan el dominio normalizado y la nota;
  nunca la URL completa ni el contenido escaneado.
- `test_fixtures.ts` imita Auth, la cuota y Atomic Memory solo para pruebas.

## Cambio propuesto en este PR

Guardar notas en un proveedor externo amplía lo que `AGENTS.md` describe como
datos del servidor (cuenta, contactos, eventos de alerta). Este PR lo propone
como función opcional, desactivada por defecto y con consentimiento explícito
por acción, para revisarlo en el propio PR. No requiere despliegue ni acción
previa del propietario para revisar el código; habilitarla en una build sigue
siendo decisión del propietario.

## Pendiente

- Verificar contra una instancia real de Atomic Memory y en un dispositivo.
