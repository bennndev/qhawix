# ADR: QR Shield — urlscan.io como proveedor

- Fecha: 2026-10-18.
- Estado: proveedor elegido por el propietario; implementación local. Despliegue y migración remotos requieren aprobación del proyecto destino.
- Stack: Flutter/Dart, provider, gateway Supabase Edge Functions sobre Deno. Sin dependencias nuevas.

## Decisión y alcance

La app envía la URL HTTP/HTTPS exacta, sin fragmento, al gateway después de un consentimiento específico. El gateway usa exclusivamente `https://urlscan.io/api/v1/scan/` y `/api/v1/result/{uuid}/`, con la cabecera `api-key`. Solicita `visibility: private` expresamente y espera un resultado terminado. Nunca cambia a escaneos públicos o no listados ante un error. Los enlaces de resultado devueltos por el proveedor no se siguen: la ruta se construye con un UUID validado y el host fijo.

QHAWIX no descarga el destino ni solicita los endpoints de DOM, capturas o archivos. Del JSON del análisis solo conserva y devuelve los campos mínimos del veredicto; el resto de los metadatos se descarta. urlscan sí visita el destino en su navegador remoto y puede seguir redirecciones. El consentimiento explica esta acción y la visibilidad privada. `redirectResolution: not_performed` indica que QHAWIX no implementa un resolvedor propio.

El contrato del gateway pasa a versión 2 y el consentimiento a `qr-urlscan-private-consent-v2`. La cobertura solicitada es únicamente `URLSCAN_VERDICT`: no equivale a una comprobación exhaustiva de malware ni de todas las amenazas. Un resultado negativo exige un análisis de la URL exacta, privado, reciente, con página accesible y veredicto explícito sin señales contradictorias. Datos faltantes, página inaccesible, errores, cuota agotada o análisis inconcluso producen **no verificable**.

Los hallazgos se normalizan a `URLSCAN_MALICIOUS` o `URLSCAN_PHISHING`; no se atribuyen categorías de otro proveedor. La vigencia de una coincidencia es una política local de cinco minutos, no un TTL declarado por urlscan. Un resultado sin señales tiene una ventana local máxima de 60 segundos desde el inicio del análisis. Nada se abre automáticamente, tampoco por una preferencia previa del historial. La URL se revalida antes de abrirse con confirmación.

La caché conserva solo claves HMAC y metadatos de coincidencias. Se separa por proveedor y versión. La migración invalida la caché anterior y reinicia sus contadores de cuotas; los incidentes del teléfono se conservan como evidencia del proveedor anterior, sin atribuirlos a urlscan.

## Clave y entorno

1. Crear `api/supabase/functions/.env` a partir de `.env.example`.
2. Configurar `URLSCAN_API_KEY` y `QR_CACHE_HMAC_SECRET` (al menos 32 bytes). El archivo está ignorado por Git. Supabase inyecta sus propias variables de conexión y servicio al ejecutar las funciones.
3. En producción, configurar los secretos de la Edge Function en el proyecto elegido. Un `.env` local no configura el entorno remoto.
4. Aplicar la nueva migración y desplegar la función en el mismo entorno antes de usar la app con el contrato v2. No mezclar una app v2 con el gateway anterior.
5. En `ui/env/local.json`, configurar únicamente las variables públicas `SUPABASE_URL` y `SUPABASE_ANON_KEY`. No poner la clave de urlscan en `ui/`.

Para desarrollo, desde `api/`: `npx supabase functions serve qr-reputation --env-file supabase/functions/.env`.

## Cuotas y condiciones

La clave proporcionada fue aceptada mediante una consulta de solo lectura a `/user/quotas/` el 2026-10-18. La cuenta informó 5 escaneos privados/minuto y 50/hora y día. Los valores iniciales de la migración respetan esas cuotas y añaden un tope local mensual conservador de 1500. Son configuración versionada de esa cuenta, no una promesa de cuota universal ni de gratuidad. urlscan también impone límites por acción y puede responder 429. No se activan compras ni suscripciones desde la integración.

Los resultados son una señal adicional de prevención; no verifican que el QR pertenezca al negocio esperado ni garantizan seguridad. Los dominios oficiales de prueba de otros proveedores no obligan a urlscan a emitir el mismo veredicto.

## Validación

- `deno test --allow-env=URLSCAN_API_KEY,QR_CACHE_HMAC_SECRET,SUPABASE_URL,SUPABASE_SERVICE_ROLE_KEY api/supabase/functions/qr-reputation/` para el proveedor y el contrato del gateway con respuestas controladas, sin cargar claves reales ni visitar amenazas.
- Desde `ui/`: `dart analyze` y `flutter test`.
- Con el backend local disponible: ejecutar las pruebas pgTAP de `api/supabase/tests/`.
- La consulta de cuotas valida la credencial, pero no demuestra por sí sola un escaneo completo ni el despliegue remoto.

### Resultados locales del 2026-10-21

- Rama de trabajo: `feature/qr-shield-urlscan`.
- Deno: comprobación de tipos y lint correctos; 16 pruebas aprobadas.
- Flutter: `dart analyze` sin incidencias; 61 pruebas aprobadas.
- Postgres: las tres migraciones se aplicaron en orden en una base temporal aislada, sin red ni puertos publicados, usando `supabase/postgres:17.11.0.004`. Las 17 comprobaciones pgTAP de configuración, permisos, caché y cuotas fueron aprobadas. El contenedor temporal se retiró al finalizar.
- Android: APK de depuración compilada con `--dart-define-from-file=env/local.json`, incluida la actualización Kotlin del historial. Artefacto: `ui/build/app/outputs/flutter-apk/app-debug.apk`. La compilación mostró avisos de soporte futuro de AGP/Kotlin; no se cambiaron sus versiones.
- El entorno de Java requirió una alternativa de comunicación local por TCP durante esta compilación de Windows. Se ajustó únicamente el proceso de compilación, sin modificar el proyecto ni la configuración global del equipo.
- La clave del proveedor permanece en el `.env` del backend ignorado por Git. El archivo de Flutter contiene solo la URL y clave pública de Supabase, y también está ignorado.

La solicitud privada de prueba de `https://example.com` fue aceptada por urlscan el 2026-10-18, pero la recuperación del resultado agotó el tiempo disponible. Por ello, no se da por validado un escaneo real completo. Falta aplicar la migración, configurar los secretos y desplegar el gateway en el proyecto Supabase autorizado; después debe comprobarse el flujo completo desde el teléfono. Estas operaciones remotas no se han ejecutado.

## Fuentes

- https://urlscan.io/docs/api/
- https://urlscan.io/docs/result/
- https://urlscan.io/docs/search/
- https://urlscan.io/terms/
- https://supabase.com/docs/guides/functions/secrets
