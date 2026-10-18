# ADR-001: Google Web Risk Lookup para Escudo QR

- Estado: aceptada para la integración, condicionada a las puertas de acceso, facturación, privacidad y términos del proveedor.
- Fecha: 2026-10-18
- Módulo: Escudo QR

## Contexto

Escudo QR necesita consultar reputación sin poner una credencial de proveedor en el APK. El backend del proyecto usa Supabase Edge Functions y Postgres con RLS. La especificación maestra recomienda Web Risk Lookup si se comprueban acceso, términos, privacidad y control de gasto.

## Decisión

Usar únicamente **Google Web Risk Lookup (`uris.search`)** como proveedor de reputación. La función recibe una URL elegible y consentida, consulta las categorías Malware, Social Engineering y Unwanted Software, y devuelve una respuesta filtrada. No se visitan destinos ni se siguen redirecciones. La clave de Google vive como secreto de la Edge Function.

Una coincidencia positiva se conserva en caché HMAC hasta el `expireTime` del proveedor; los no-match no se almacenan y caducan localmente después de 60 segundos. El backend impone límites globales durables de 2/minuto, 3.000/día y 90.000/mes. Los errores o la falta de configuración se representan como no verificables.

## Consecuencias

- Google recibe la URL completa (ruta y query), excepto fragmento, solo después del consentimiento; la URL no se persiste legible en QHAWIX.
- El uso puede generar cargos después de la cuota publicada o por consumo compartido de la cuenta. El límite de QHAWIX no controla otros proyectos de Google Cloud.
- La función es pública para clientes móviles; su anon/publishable key no autentica a una persona. El límite global durable protege el gasto, pero no impone cupos por usuario.
- La configuración real requiere proyecto, API habilitada, facturación, secreto de Google, migración aplicada y despliegue de la función.

## Reconsiderar si

La cuenta no obtiene acceso, los términos/privacidad no son aceptables, la cuota o presupuesto no alcanza, o el proveedor deja de cubrir las categorías necesarias. En ese caso, la app conserva análisis local y presenta la reputación como no verificable; no cambia a Apify automáticamente.
