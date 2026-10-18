# Configurar Web Risk Lookup para Escudo QR

La aplicación llama a la Edge Function `qr-reputation`; esa función consulta Google Web Risk Lookup. La clave de Google y la clave de servicio de Supabase permanecen en el backend. La app solo recibe la URL después de que la persona autoriza la consulta.

## 1. Preparar Google Cloud

1. Selecciona o crea un proyecto de Google Cloud para QHAWIX.
2. Habilita **Web Risk API** y configura facturación para el proyecto.
3. Crea una API key y restríngela a Web Risk API. No la pongas en el APK, en Git ni en la configuración Flutter.
4. Usa únicamente `uris.search` (Lookup). La app consulta las categorías Malware, Social Engineering y Unwanted Software; no usa Update API ni descarga listas.

Google publica 100.000 llamadas Lookup gratuitas por mes y un precio de USD 0,50 por cada 1.000 llamadas posteriores. La cuenta debe tener facturación configurada; el límite durable de QHAWIX es 2 consultas por minuto, 3.000 por día y 90.000 por mes. Ese límite controla las llamadas de QHAWIX, no el consumo de otros proyectos de la cuenta de Google. Revisa la cuota y el gasto compartido en Google Cloud antes de habilitar un piloto.

## 2. Preparar Supabase

Desde la raíz del repositorio, con Supabase CLI instalado:

```powershell
cd api
supabase login
supabase link --project-ref <PROJECT_REF>
supabase db push
supabase functions deploy qr-reputation
```

La migración crea el límite durable y la caché de positivos en el esquema privado. La clave de caché es HMAC de la URL, categorías y versión de normalización; nunca guarda la URL legible. Solo conserva coincidencias hasta el `expireTime` indicado por Google. Las respuestas sin coincidencias no se guardan en caché.

En Supabase Dashboard, abre **Edge Functions → Secrets** y agrega:

| Nombre | Valor |
| --- | --- |
| `WEBRISK_API_KEY` | La API key restringida de Google |
| `QR_CACHE_HMAC_SECRET` | Un secreto aleatorio de al menos 32 bytes |

Rota `QR_CACHE_HMAC_SECRET` diariamente según el procedimiento de operaciones; al cambiarlo, las entradas previas dejan de coincidir y se consultará de nuevo a Google. No uses la API key de Google como secreto HMAC.

Supabase inyecta `SUPABASE_URL` y `SUPABASE_SERVICE_ROLE_KEY` en el entorno de Edge Functions. El endpoint ejecuta sus funciones SQL de cuota y caché con esa clave desde el servidor; no la copies a Flutter. Para consultar los nombres disponibles, revisa la [documentación de secretos de Supabase](https://supabase.com/docs/guides/functions/secrets).

La configuración de la función desactiva la verificación JWT porque QR Shield es un cliente móvil público. El `anon`/publishable key solo identifica el proyecto y no autentica personas. La cuota global persistente protege el gasto, pero no identifica cada dispositivo.

## 3. Desarrollo local

1. Copia `api/supabase/functions/.env.example` a `api/supabase/functions/.env` y completa ambos secretos. El `.env` real está excluido de Git.
2. En `ui/env/local.json`, configura el `SUPABASE_URL` del proyecto local y su `SUPABASE_ANON_KEY` (o publishable key). No agregues allí la API key de Google ni la service-role key.
3. Inicia el backend y sirve la función:

```powershell
cd api
supabase start
supabase functions serve
```

4. Ejecuta Flutter con el archivo local:

```powershell
cd ui
flutter run --dart-define-from-file=env/local.json
```

Para el emulador Android, configura `SUPABASE_URL` con el host del emulador que alcanza al Supabase local; `127.0.0.1` desde Android apunta al propio emulador.

## 4. Revisar el comportamiento

- Sin secretos o sin migración, la consulta queda como no verificable; nunca se interpreta como una URL sin amenazas.
- Un match vigente bloquea la apertura desde QHAWIX. Un no-match caduca localmente a los 60 segundos y no demuestra que el QR pertenezca al negocio esperado.
- La función no visita ni sigue la URL del QR. Solo envía esa URL a `webrisk.googleapis.com` tras el consentimiento de la app.
- `GET /functions/v1/qr-reputation/health` muestra la versión del servicio y `GET /functions/v1/qr-reputation/v1/capabilities` indica si la configuración requerida está presente.
- La URL completa, incluidos ruta y query, pasa por Supabase y luego a Web Risk, sin el fragmento. QHAWIX no la guarda en sus tablas ni en sus logs propios; revisa las condiciones de privacidad y retención de ambos proveedores antes del piloto.

## Referencias

- [Google Web Risk Lookup](https://docs.cloud.google.com/web-risk/docs/lookup-api)
- [Tarifas de Web Risk](https://cloud.google.com/web-risk/pricing)
- [Buenas prácticas para API keys de Google Cloud](https://docs.cloud.google.com/docs/authentication/api-keys-best-practices)
- [Desplegar Edge Functions de Supabase](https://supabase.com/docs/guides/functions/deploy)
- [Secretos de Edge Functions de Supabase](https://supabase.com/docs/guides/functions/secrets)
