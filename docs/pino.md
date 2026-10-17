# Qhawix — Brief de la idea completa

Oct 17, 2026 · @jorge

Qhawix es una app móvil de telefonía de red cerrada: como la propia app recibe la llamada, puede leer metadata y audio en vivo y avisar a quien contesta si es estafa, suplantación o voz sintética, antes de que entregue un código o dinero.

## El problema

Las estafas por llamada funcionan porque la víctima decide en segundos y bajo presión, y las defensas actuales ven muy poco de la conversación.

- Los filtros de spam miran solo el número. No detectan un número limpio, prestado o suplantado, ni una voz clonada con IA.
- Lo que pasa dentro de la llamada (pedir el código SMS, falsa urgencia, "tenemos a su hijo") es invisible para el sistema operativo: Android no entrega el audio de llamadas celulares a apps normales.
- Las modalidades cambian rápido: falso banco con código OTP, secuestro virtual, acceso remoto, familiar en emergencia, repartidor o cita falsa, y ahora voz sintética.
- El momento crítico ocurre sin soporte técnico: quien contesta suele ser una persona sola, a veces mayor, que no tiene a quién consultar durante esa llamada.

## La idea

Qhawix cambia dónde ocurre la llamada: en vez de dejarla en la red celular, la lleva a una red cerrada de usuarios registrados con su número. Como la app es el teléfono, tiene acceso legítimo a metadata y audio, y puede ayudar a quien recibe mientras la llamada sigue en curso.

Quien recibe una llamada dentro de la red ve tres cosas:

1. **Quién llama**: el nombre con el que esa persona se registró, verificado por OTP, con la antigüedad de su cuenta.
2. **Un semáforo previo** (verde, ámbar o rojo) con las razones en lenguaje claro, antes de contestar.
3. **Un veredicto en vivo** durante la llamada, con un consejo concreto, por ejemplo: "Cuelga. Es muy probable que sea una estafa. No des códigos ni dinero; llama tú al número oficial".

**Para quién:** personas expuestas a estafas telefónicas (adultos mayores, familias, pequeños negocios) y su círculo de confianza, que puede recibir alertas.

**De dónde viene:** es la evolución de EchoTrap. EchoTrap filtraba llamadas con un asistente de voz (Vapi) que contestaba por el usuario. Qhawix elimina esa dependencia: el núcleo no depende de ningún proveedor de telefonía, y Vapi queda como adaptador opcional.

## Por qué una app de telefonía

La ventaja es de acceso: solo dentro de la red Qhawix la app ve el audio y la metadata completos. Fuera de ella, el sistema operativo limita lo que cualquier app puede hacer.

| Escenario | Qué ve la app | Qué ofrece Qhawix |
| --- | --- | --- |
| Llamada dentro de la red (ambos con Qhawix) | Audio y metadata completos: la app es el terminal | Análisis en vivo, veredicto, evidencia y alerta |
| Llamada celular normal entrante en Android | Número y estado de verificación del operador, en una ventana de unos 5 s; sin audio | `POST /v1/screen`: permitir, etiquetar como sospechosa o silenciar |
| Marcar a alguien que no está en la red | El directorio responde "no registrado" | La app abre el marcador del sistema (fallback) |
| Llamada celular normal en iOS | Sin verificar | Por definir; no se promete |

Lo que esto significa para el producto: la red cerrada no es una limitación sino el diferenciador. Cada persona que se registra aumenta la zona donde el análisis es posible, y el registro por número hace que migrar sea tan simple como "marcar a un contacto".

Para las llamadas propias, Android ofrece Core-Telecom (permiso `MANAGE_OWN_CALLS`, servicio en primer plano de tipo `phoneCall` y notificación `CallStyle` en menos de 5 s). Lo que no ofrece, a ninguna app normal, es el audio de una llamada celular.

## Cómo funciona una llamada

1. **Registro.** El usuario se registra con su número (E.164) y un código OTP; recibe un token firmado. Solo usuarios verificados pueden llamar y recibir.
2. **Marcar.** La app consulta el directorio. Si el número está en la red muestra el nombre; si no, cede al marcador del sistema.
3. **Invitación.** El servidor valida ambos usuarios, calcula el puntaje previo y avisa al receptor con nombre, antigüedad de cuenta, semáforo y razones. Ambos ven un aviso de que la llamada puede ser analizada.
4. **Aceptar.** La llamada se establece entre las dos apps (WebRTC); el servidor solo retransmite la señalización. Si el receptor tiene el escudo activado, empieza el análisis.
5. **Análisis.** El dispositivo del receptor envía una copia del audio del llamante (o el texto de su propio reconocimiento de voz) por WebSocket. Cada ventana de unos 4 s: se descarta el silencio, se transcribe y se puntúa la voz sintética en paralelo; las reglas de estafa actúan de inmediato y el LLM clasifica como máximo cada 2,5 s.
6. **Veredicto.** Se envía solo al receptor y solo puede subir de nivel durante la llamada. Cuando llega a rojo, se puede avisar por Telegram o webhook, sin números telefónicos.
7. **Cierre.** Se guarda una evidencia sin audio ni número del llamante. El número se reporta automáticamente a la reputación solo si las reglas y el LLM coinciden.

Si cualquier proveedor externo falla o tarda, la llamada continúa: el veredicto lleva una lista `degraded` que dice qué parte del análisis está apagada.

## El motor de detección

El veredicto combina cinco fuentes. Cada una aporta puntos y, algunas, un piso de nivel que ninguna otra puede bajar.

| Fuente | Qué mira | Efecto en el puntaje |
| --- | --- | --- |
| Antes de contestar | Formato del número, prefijo extranjero, VoIP, tarifa premium, atestación fallida, hora nocturna, números vecinos (spoofing), velocidad de llamadas, primera vez visto | Entre +3 y +25 por señal |
| Reputación de la red | Reportes de usuarios (vida media de 7 días, tope de 40; solos no llegan a rojo), cuenta nueva (menos de 24 h), abanico (4 o más destinatarios distintos en 10 min), cuenta verificada en red, menciones web | +10 a +20 por riesgo; −10 si es verificada |
| Contenido de la conversación | Reglas duras en español (banco, código OTP, urgencia, secuestro, acceso remoto, familiar en emergencia) más clasificador LLM | Estafa: +60 y piso rojo. Sospechoso: +25 y piso ámbar |
| Voz sintética | Puntaje de un detector, promediado en ventanas; requiere al menos 2 | 0,65 o más: +10. 0,85 o más: +20 y piso ámbar. Nunca rojo por sí sola |
| Palabra clave familiar | El llamante dice la frase pactada | −15, sin bajar el piso que puso el contenido |

| Nivel | Puntaje | Qué le dice la app |
| --- | --- | --- |
| Verde | menos de 30 | Sin señales de riesgo por ahora; recuerda no compartir códigos |
| Ámbar | 30 a 59 | Precaución y qué verificar |
| Rojo | 60 o más | "Cuelga": no des códigos, claves ni dinero; llama tú al número oficial |

**Principios de diseño:** las reglas son rápidas, gratis y auditables, por eso van primero; el LLM aporta matiz pero nunca baja lo que las reglas detectaron; el nivel solo sube durante la llamada para que nadie pueda "limpiar" el semáforo con una frase amable; la voz sintética es una señal, no un veredicto.

Los pesos son hipótesis sin calibrar con datos reales. Se presentan como reglas explicables, no como precisión medida.

## Qué ya está construido y qué falta

El backend base está hecho y probado con simulaciones; la app móvil todavía no. **\[V\]** = verificado en pruebas o ejecución; **\[N\]** = no verificado contra el servicio real.

| Pieza | Estado |
| --- | --- |
| Backend modular (Node 22, 9 módulos: auth, directorio, reputación, inteligencia web, screening, llamadas, evidencia, simulación, alertas) | Hecho. 64 pruebas en verde y tipos limpios **\[V\]** |
| Protocolo HTTP y WebSocket para la app (`docs/PROTOCOL.md`) | Documentado **\[V\]** |
| Motor de riesgo, reglas en español y fusión de veredicto | Hecho **\[V\]**; pesos sin calibrar |
| Simulador con 6 escenarios sintéticos (banco, secuestro virtual, acceso remoto, familiar, repartidor, dentista) y demo de punta a punta sin claves | Hecho **\[V\]** |
| Adaptadores: Gemini, Deepgram, Tavily, Exa, Apify, IPQS, detector de voz HTTP, Telegram, webhook | Hechos y probados con `fetch` simulado; contra proveedores reales **\[N\]** |
| Detector de voz sintética real (TruthScan) | Adaptador genérico listo; falta el contrato real (URL, formato, autenticación, escala) **\[N\]** |
| OTP real por SMS o webhook | Pendiente; sin esto, producción responde 503 al registrar **\[N\]** |
| Push (FCM) para despertar al receptor con la app cerrada | Pendiente **\[N\]** |
| App móvil de Qhawix | No iniciada: el repo `bennndev/qhawix` solo tiene plantillas de configuración; el stack con Ben está por confirmar |

El repo de código y la guía del proyecto están en el archivo `qhawix-backend.zip` y en el Project de Claude (`QHAWIX_BACKEND_GUIA.md`).

## Herramientas del evento

Ninguna es obligatoria: sin claves el backend funciona con reglas y metadata. Cada una entra como adaptador intercambiable.

| Herramienta | Rol en Qhawix | Estado y condición |
| --- | --- | --- |
| Tavily y Exa | Búsqueda web con dos usos: señal débil por número (hasta +15 si hay páginas que lo mencionan junto a palabras de estafa) y "playbook" de modalidades recientes como contexto del clasificador | Implementado y apagado por defecto. La consulta por número exige el interruptor del servidor y el consentimiento del usuario. Contenido web tratado como no confiable **\[N\]** con claves reales |
| Apify | Ayudante para ejecutar un actor de Apify y leer sus resultados | Implementado sin actor por defecto; hay que elegir uno y revisar términos de uso antes de usarlo |
| IALABS | Posible LLM o servicio de IA | Por identificar. Si su API es compatible con OpenAI, entra con el adaptador `openai-compat` |
| Qatom | Plataforma de comercio entre agentes | Solo idea de pitch: publicar el puntaje de riesgo (`/v1/score`) como servicio que otros agentes puedan contratar y pagar. Sin código |
| Gemini | Clasificador de estafa y, opcionalmente, transcripción | Recomendado como primer proveedor por costo; modelo a confirmar con `npm run preflight -- --live` **\[N\]** |
| TruthScan | Detección de voz sintética | Pendiente de conectar; falta el contrato real |
| n8n o Zavu | Envío del OTP y alertas por webhook | Pendiente de elegir |

## Privacidad, ética y límites

El producto escucha llamadas, así que la confianza es parte del producto. Las reglas por defecto son estas:

- **Audio:** nunca se guarda. Se procesa por ventanas y se descarta.
- **Transcripción:** solo se guarda si el servidor lo permite y el usuario lo activa. Por defecto queda solo una huella criptográfica de las líneas.
- **Consentimiento visible:** ambos extremos reciben un aviso de que la llamada puede ser analizada; el receptor puede apagar el escudo.
- **Solo para quien recibe:** el llamante nunca ve veredictos, transcripción ni evidencia, y solo el receptor puede enviar audio para análisis.
- **Evidencia:** sin audio y sin el número del llamante (solo un hash), visible solo para el receptor.
- **Terceros:** ningún número sale a buscadores sin dos permisos (servidor y usuario). Las alertas externas no llevan números. La reputación por número consultada a IPQS usa solo señales de riesgo, nunca el titular.
- **Identidad:** jamás se identifica al dueño de un número. El directorio devuelve únicamente el nombre con el que cada persona se registró, con límite de 30 consultas por minuto para impedir barridos.
- **Palabra clave familiar:** se guarda solo como hash y nunca se devuelve.

**Límites honestos:** existen falsos positivos y falsos negativos; un puntaje alto no prueba que alguien sea estafador. Un audio malo puede parecer sintético. El marco legal sobre analizar o grabar llamadas varía por país y no se ha revisado con asesoría legal **\[N\]**.

## Rúbrica de Hack the Andes y plan de demo

Hack the Andes (Lima, 17 y 18 de octubre de 2026) evalúa Tracción 30, Técnico 40 y Pitch 30. Los evaluadores abren los enlaces en su propia computadora, así que la demo debe verse sin instalar nada.

| Criterio | Qué mostrar | Evidencia disponible hoy |
| --- | --- | --- |
| Técnico (40) | Arquitectura modular donde cada función es un módulo; degradación elegante si un proveedor cae; privacidad por diseño; detección explicable en capas | 64 pruebas, tipos limpios, demo de punta a punta, documentación de protocolo y decisiones |
| Pitch (30) | Una historia de víctima en 20 segundos, el semáforo pasando de verde a rojo en vivo, y el consejo en pantalla | Simulador con el escenario "banco pide código": verde al inicio, rojo con el primer mensaje de falso banco con urgencia |
| Tracción (30) | Personas reales dentro de la red y llamadas reales entre ellas | Todavía ninguna. Propuesta: registrar a miembros del equipo, jurados y asistentes con números reales durante el evento, y mostrar el contador de usuarios y llamadas analizadas |

**Guión de demo propuesto (3 minutos):**

1. Historia: una persona recibe la llamada de un falso banco. Hoy no tiene cómo saberlo.
2. Dos teléfonos con Qhawix: una llamada normal entra con semáforo verde y el nombre verificado.
3. Segunda llamada con el escenario de estafa: el semáforo pasa de verde a rojo en cuanto el llamante dice ser del banco y mete urgencia, y el pedido del código lo confirma; aparece "Cuelga, llama tú al número oficial".
4. Qué pasó por dentro: señales, evidencia sin audio, alerta al círculo de confianza.
5. Cierre: red cerrada que crece, y el puntaje ofrecido como servicio a otros agentes (idea Qatom).

**Hueco a cubrir:** hoy el backend se demuestra por consola y por API. Para jurados que abren un enlace hace falta una pantalla visual (p. ej. una página web o la propia app) que muestre el semáforo y la transcripción en vivo usando `/v1/simulate`.

## Riesgos y frases seguras para el pitch

**Riesgos, de mayor a menor:**

1. **La app móvil no existe todavía.** Es el mayor riesgo de tiempo: sin ella no hay llamadas reales ni tracción. Mitigación: definir hoy el stack con Ben y priorizar el camino mínimo (registro, marcar, aceptar, ver el semáforo).
2. **Efecto de red.** Una red cerrada solo protege donde hay usuarios. Mitigación: la pantalla de `/v1/screen` da algo de valor fuera de la red, y el onboarding se reduce a "llamar a un contacto".
3. **Proveedores sin verificar.** Todo se probó con simulaciones. Mitigación: `npm run preflight -- --live` con claves reales, antes de la demo.
4. **Falsos positivos.** Un número legítimo marcado en rojo daña la confianza. Mitigación: reportes que no llegan a rojo solos, voz sintética que nunca da rojo sola, lenguaje de "posible" estafa.
5. **Marco legal y plataformas.** Analizar llamadas exige consentimiento visible y puede variar por país; iOS limita más que Android.

| Se puede decir | No se debe decir |
| --- | --- |
| "Detecta patrones de estafa en vivo y avisa a quien recibe la llamada" | "Bloquea el X % de las estafas" (no hay medición real) |
| "Dentro de nuestra red tenemos acceso a metadata y audio porque la app es el teléfono" | "Escucha cualquier llamada de tu celular" (Android no lo permite) |
| "La voz sintética es una señal adicional" | "Detecta cualquier deepfake" |
| "No guardamos audio; el análisis es solo para quien recibe" | "Es 100 % privado" sin matices |
| "Los pesos son reglas explicables que calibraremos con datos" | Cifras de precisión sin datos reales |

## Siguientes pasos y preguntas abiertas

**Orden recomendado (de mayor a menor impacto en la rúbrica):**

- [ ] Acordar con Ben el stack móvil y el camino mínimo: registro, marcar, aceptar y ver el semáforo
- [ ] Poner en `.env` las claves de Gemini, Tavily y Exa, y correr `npm run preflight -- --live`
- [ ] Desplegar el backend (con `TOKEN_SECRET`, `HASH_PEPPER` y `ADMIN_API_KEY` reales) para que la app y los evaluadores lo alcancen
- [ ] Construir una pantalla de demo visible por enlace que use `/v1/simulate` (semáforo y transcripción en vivo)
- [ ] Conectar el detector de voz sintética real cuando tengamos su contrato
- [ ] Elegir el canal del OTP (n8n, Zavu o SMS) y configurar `OTP_WEBHOOK_URL`
- [ ] Registrar usuarios reales durante el evento y medir llamadas analizadas para la tracción
- [ ] Preparar el guion de pitch con las frases seguras de la sección anterior
- [ ] Después del evento: push (FCM), audio en servidor (LiveKit), círculo familiar y calibración de pesos

**Preguntas abiertas:**

- ¿Cómo es hoy la llamada a TruthScan: URL, formato de audio, autenticación y dónde viene el puntaje en la respuesta?
- ¿Qué es IALABS y qué tipo de API ofrece?
- ¿Qué rol tiene MiniMax en el proyecto?
- ¿Qué stack móvil usará Ben y quién construye cada pantalla?
- ¿Qué canal usaremos para el OTP en la demo?

Materiales de apoyo: la guía del proyecto (`AGENTS.md`), `docs/PROTOCOL.md`, `docs/ARCHITECTURE.md`, `docs/ADDING_A_MODULE.md`, `docs/DECISIONS.md`, `docs/PRIVACY.md` y `docs/TASKS.md`, dentro de `qhawix-backend.zip`.
