# EchoTrap

EchoTrap es una pantalla de llamada dentro de QHAWIX. El inicio de sesión se pide al abrir la aplicación y la sesión se mantiene entre aperturas.

## Cómo funciona

- Dos cuentas QHAWIX se llaman por el número guardado en sus perfiles. LiveKit transporta la voz en vivo. El receptor puede ver la llamada entrante mientras QHAWIX está abierta.
- Al contestar o iniciar, ambas personas aceptan el aviso de análisis. La app del receptor toma la pista de voz remota en tramos de cuatro segundos y envía esos tramos a `transcribe` con sesión autenticada.
- Deepgram es el transcriptor principal. Si no está configurado o no responde, `transcribe` usa Gemini de respaldo. Gemini y las reglas evalúan el texto para mostrar precaución o riesgo alto. El servicio no guarda audio ni texto de estas llamadas; conserva el estado de llamada y las alertas elevadas.
- Después de reunir diez segundos, `voice-origin` puede enviar una sola muestra a TruthScan para estimar si detecta señales de audio sintético. Esa estimación no identifica a quien habla ni confirma una estafa.
- Si la conversación presenta señales de riesgo, `call-intelligence` puede usar Exa para buscar fuentes oficiales a partir de la entidad mencionada. El buscador no recibe el audio, el número de teléfono ni la transcripción completa.
- Los contactos se leen solo después de conceder el permiso Android. La agenda permanece en el teléfono; solo el número seleccionado se usa para encontrar una cuenta QHAWIX.

## Límites de Android

EchoTrap analiza llamadas de QHAWIX mediante la pista de audio de LiveKit. No escucha ni bloquea llamadas normales del operador, WhatsApp u otras aplicaciones; Android no entrega a esta app el audio de esas llamadas. Tampoco hay un agente telefónico que responda por la persona. Estas funciones requerirían una línea y un proveedor de telefonía.

Una falta de transcripción, resultado de voz o fuente pública se muestra como no disponible. Un resultado verde o una búsqueda vacía no confirma que una llamada sea segura.

## Configuración del servidor

El APK recibe únicamente la URL de Supabase y su clave pública al compilar. Las claves de LiveKit, Deepgram, Gemini, Exa y TruthScan permanecen en Supabase; nunca deben incluirse en Flutter ni en Git.

Funciones usadas por esta pantalla: `call-control`, `transcribe`, `call-intelligence` y `voice-origin`. Supabase tiene `transcribe` v5 activa; Deepgram es opcional y, si falta, la función usa Gemini. En llamadas QHAWIX el audio y el texto se procesan para el análisis, no se guardan en sus tablas; se conservan solo alertas elevadas. Las claves de Deepgram, Exa y TruthScan compartidas en el chat deben rotarse antes de habilitar esos proveedores.

## Prueba local

Para probar en el Xiaomi, compila con `flutter build apk --release --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_PUBLISHABLE_KEY=...` e instala `ui/build/app/outputs/flutter-apk/app-release.apk`. Crea una cuenta distinta en cada teléfono y guarda números únicos en formato internacional (`+51...`). Mantén QHAWIX abierta, inicia una llamada desde un teléfono y contesta en el otro. Usa frases inventadas; comprueba el audio, la transcripción y los cambios de riesgo. La detección de riesgo y la estimación de voz sintética aún requieren calibración con llamadas reales consentidas.
