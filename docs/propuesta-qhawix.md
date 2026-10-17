# Qhawix: propuesta de MVP verificable para Hack the Andes

**Decisión recomendada:** unir la evidencia de comunicaciones de EchoTrap con un **Guardian contextual ligado a la acción**: antes de una transferencia ficticia, explicar la presión detectada, vincular la revisión al destinatario y monto concretos, pausar cuando corresponda y facilitar una devolución de llamada independiente. Next.js y Convex son la base reutilizable. El detector de voz sintética será opcional; no condicionará el análisis del contenido ni la demostración.

**Estado: propuesta, no implementación aprobada.** Corte de evidencia: 17 de octubre de 2026. Qhawix es un nombre de trabajo. Guardian aporta conceptos de contexto, identidad, respuesta y protección ante coacción. La demo pública Vigía es interactiva, pero declara simulaciones y no demuestra integraciones bancarias ni la arquitectura histórica implementada. Faltan la revisión del Figma y aclaraciones del organizador sobre categorías, reutilización y zona horaria. Esta propuesta no autoriza modificaciones de EchoTrap, publicación, compras ni acceso a credenciales.

## 1. Lectura rápida

1. Confirmar elegibilidad de la reutilización y categoría antes de comprometer la entrega.
2. Validar el flujo completo: importar comunicación → identificar evidencia → evaluar la acción concreta con Guardian → pausar la transferencia ficticia → verificar por devolución de llamada independiente y registrar la decisión.
3. Reutilizar interfaz, persistencia y separación por adaptadores; corregir conceptualmente la dependencia entre riesgo acústico y análisis de contenido.
4. Demostrar una inferencia real de contenido, los estados de error y la diferencia entre resultados observados y simulación declarada. No usar un botón oculto para forzar el resultado.
5. Añadir detección acústica únicamente si se confirma acceso, costo y comportamiento con las muestras de la demo. No entrenar un modelo ni construir un SDK para esta entrega.

## 2. Qué sabemos y qué no

| Etiqueta | Significado | Ejemplo aplicable |
|---|---|---|
| Verificado en documentos | Afirmación localizada en una fuente entregada | La rúbrica exige despliegue público, código y demo funcional |
| Observado en demo pública | Comportamiento visible en navegador; no prueba el backend | Vigía genera un resultado explícitamente simulado y lo muestra en historial |
| Observado en código | Inspección estática; no demuestra ejecución | Existe un adaptador TruthScan con carga y consulta asíncronas |
| Declaración del proveedor | Función o tarifa publicada; sin prueba propia | TruthScan publicita precisión superior al 99 % |
| Propuesta | Decisión recomendada y pendiente de aprobación | Pausar una transferencia ficticia mediante reglas explícitas |
| Desconocido | Falta acceso, evidencia o prueba | Disponibilidad real del modelo Gemini configurado |

La investigación combinó documentos, lectura estática del repositorio externo y documentación primaria. Los investigadores utilizaron GPT-6.1 Sol, habilitado por el usuario; no se realizó una revisión con otra familia de modelos. No se instalaron dependencias ni se ejecutaron builds, pruebas del producto o llamadas de inferencia. La herramienta de investigación no pudo acceder a [la URL pública de EchoTrap](https://echo-trap-web.vercel.app/): esto no demuestra caída ni equivalencia con el código local. El detalle y las limitaciones se conservan en el [dossier de evidencia](../.research/qhawix-feasibility/FINDINGS.md).

## 3. Problema, usuario inicial y resultado esperado

### Problema delimitado

Una persona recibe un mensaje o audio que combina urgencia, amenaza, identidad aparente y una solicitud de acción económica. Reconocer una voz conocida no prueba identidad; reconocer voz humana tampoco descarta una estafa. La decisión crítica es detenerse y verificar por otro canal antes de ejecutar una acción, no obtener una etiqueta universal de «verdadero/falso».

Como contexto, INEI reporta para 2025 extorsión, incluidos intentos, de **1,3 por cada 100 personas urbanas de 15 años o más**, frente a 0,9 en 2024; estafa pasa de 3,8 a **2,0 por cada 100**. No son cifras exclusivamente telefónicas, de clonación de voz ni del mercado de Qhawix. La tabla se comprobó mediante extracción textual, no inspección visual disponible. Por tanto, tampoco sustenta que toda modalidad de fraude esté creciendo. Fuente: [INEI, Victimización 2025, p. 8](https://www.inei.gob.pe/media/MenuRecursivo/publicaciones_digitales/Est/Lib2076/libro.pdf), consultada el 17-10-2026.

### Hipótesis de entrada al mercado

**Segmento inicial propuesto:** personas adultas que administran pequeños comercios urbanos peruanos y reciben solicitudes de pago por mensajería. Es una hipótesis por validar, no una conclusión del INEI. El caso permite observar una comunicación antes de una transferencia y evaluar una intervención sin integrar bancos reales. No se afirma adopción, disposición de pago ni representatividad nacional.

**Trabajo del usuario:** «Quiero comprender por qué esta comunicación merece cautela y verificarla sin entregar dinero ni información sensible». La recomendación coincide con la orientación de la SBS de terminar contactos sospechosos y acudir a canales oficiales: [fraudes digitales y telefónicos](https://www.sbs.gob.pe/usuarios/aprende-con-la-sbs/fraudes-digitales-y-telefonicos), consultado el 17-10-2026.

### Objetivos y límites del impacto

- Entregar evidencia legible y una siguiente acción segura, incluso si el audio es auténtico o el detector está fuera de servicio.
- Mostrar una intervención auditable en una operación propia simulada, sin apropiarse de controles de otra aplicación.
- Medir comprensión, falsas alertas, abstención y costo antes de afirmar utilidad preventiva.
- Explorar posteriormente otros países hispanohablantes adaptando idioma, canales oficiales, consentimiento y modelos de amenaza; no asumir portabilidad de precisión o normativa.

La alineación potencial con ODS 16.1/16.3 es temática, no evidencia de reducción de violencia o mejora del acceso a justicia: [Naciones Unidas, ODS 16](https://sdgs.un.org/goals/goal16), consultado el 17-10-2026.

## 4. Diferenciación: hipótesis defendible, no exclusividad

| Alternativa | Qué ya ofrece | Consecuencia para Qhawix |
|---|---|---|
| Google Phone | Advertencias conversacionales en dispositivos y regiones compatibles | «Alertar sobre estafas» no es una novedad suficiente |
| Truecaller | Identificación, funciones familiares y AI Call Scanner según condiciones | La detección de voz sintética no constituye por sí sola una ventaja exclusiva |
| Apple | Filtrado de llamadas desconocidas y grabación/transcripción compatibles | No competir prometiendo capacidades del sistema inaccesibles a terceros |
| Qhawix, propuesto | Evidencia de manipulación contextualizada y pausa en flujo propio | Validar que explicación e intervención mejoran una decisión concreta |

Fuentes oficiales consultadas el 17-10-2026: [Google Scam Detection](https://support.google.com/phoneapp/answer/15654065?hl=en), [Truecaller AI Call Scanner](https://support.truecaller.com/support/solutions/articles/81000413994-ai-call-scanner-faqs), [Apple: filtrar y bloquear llamadas](https://support.apple.com/guide/iphone/screen-and-block-calls-iphe4b3f7823/26/ios/26). Sus condiciones no equivalen a cobertura mundial ni disponibilidad confirmada en el equipo de demo.

La tesis diferenciadora es **comunicación → evidencia → política contextual Guardian → acción protegida → recuperación trazable**, con contexto peruano y degradación honesta. No es todavía una barrera competitiva: faltan entrevistas, evaluación local, socios y datos autorizados. Un premio nacional anterior, comunicado por el usuario, es reconocimiento histórico pendiente de respaldo; no es tracción del hackathon ni prueba de eficacia.

### 4.1. Guardian no es solo una alerta: tres preguntas distintas

La fusión propuesta separa **«¿sigue siendo el mismo usuario?»**, **«¿es auténtico el número o la institución que llama?»** y **«¿es segura esta acción solicitada?»**. Ninguna respuesta sustituye a las otras: el titular legítimo puede transferir bajo coacción, una institución auténtica puede llamar desde un número desconocido y una llamada con número aparentemente oficial puede solicitar una acción peligrosa.

| Estado independiente | Qué podría aportar | Qué no demuestra |
|---|---|---|
| Procedencia del número | Coincidencia con directorio o veredicto nativo del operador, si existe | Identidad del agente, propósito o seguridad de la llamada |
| Confirmación institucional | Recontacto iniciado por la persona mediante canal obtenido independientemente | Autorización ilimitada para futuras operaciones |
| Riesgo del contenido/solicitud | Evidencia de OTP solicitado, secreto, amenaza, transferencia o cambio de cuenta | Delito probado ni culpabilidad del interlocutor |
| Desviación conductual | Diferencia incierta respecto de una referencia personal opcional | Identidad única, emoción, coacción o consentimiento libre |

Mostrar estos cuatro estados por separado, con `desconocido` o `no disponible` cuando falte evidencia. No colapsarlos en un semáforo de «llamada segura» ni en un 92/100 presentado como probabilidad calibrada. El análisis de manipulación de EchoTrap y la observación de interacción del usuario son señales distintas; no denominarlas indistintamente «biometría».

### 4.2. Diferenciadores evaluados y prioridad

| Hipótesis | Aporte específico de Guardian | Prioridad y tradeoff |
|---|---|---|
| Política ligada a la acción | Contexto declarado y evidencia condicionan una transferencia ficticia; la revisión corresponde a monto, destinatario y propósito concretos | P0: integración verificable; no controla otras billeteras |
| Devolución de llamada independiente | Permite resolver incertidumbre institucional sin confiar en el número entrante | P0: útil incluso sin ML; exige fuentes vigentes y evita contactos aportados por el llamante |
| Línea de tiempo del incidente | Une evidencia, regla aplicada, revisión, decisión y orientación de recuperación | P0 mínimo: trazabilidad, no decoración; persistencia y borrado deben comprobarse |
| Referencia conductual y copo visual | Puede explicar variación dentro de una misma persona con consentimiento | P1 experimental: solo si no desplaza P0; añade privacidad, sesgo y fricción |
| Confirmación de intención firmada por una institución | Podría vincular un propósito a una entidad participante | Hoja de ruta: requiere claves, acuerdos e integración; un fixture no acredita participación bancaria/policial |
| SDK o verificación telefónica nativa | Acercaría señales al flujo financiero o a metadatos del sistema | Hoja de ruta: acuerdos, permisos y evaluación; no concede audio ni API nacional |

**Ventaja que debe probarse:** que esta continuidad ayude más que una advertencia genérica o una simple pausa con devolución de llamada. Evaluar comprensión, falsas pausas, tiempo de resolución y accesibilidad; descartar señales que no mejoren esa base simple. Más tarjetas, sensores o un porcentaje llamativo no constituyen diferenciación por sí mismos.

### 4.3. Copo de nieve/fractal: metáfora útil, identidad no demostrada

Un copo puede visualizar dimensiones normalizadas de una **referencia dentro del mismo usuario**, con leyenda, datos insuficientes y una comparación temporal explícita. Es un recurso de explicación, no una huella única: personas diferentes pueden producir formas parecidas, la misma persona cambia por contexto/dispositivo y el gráfico no incorpora por sí mismo garantías criptográficas.

NIST trata la comparación biométrica como probabilística; W3C advierte sobre el rastreo mediante fingerprinting. Touchalytics estudia patrones táctiles bajo condiciones específicas y no sustenta autenticación autónoma universal a largo plazo. Hay investigación sobre evasión de modelos de ratón y variación entre dispositivos, no resultados de Qhawix. Fuentes consultadas el 17-10-2026: [NIST SP 800-63B-4](https://pages.nist.gov/800-63-4/sp800-63b.html), [W3C: fingerprinting](https://www.w3.org/TR/fingerprinting-guidance/), [Touchalytics](https://arxiv.org/abs/1207.6231), [evasión adversarial](https://arxiv.org/abs/1905.11831) y [preprint entre dispositivos](https://arxiv.org/abs/2608.16334). Este último es un preprint, no una validación independiente del producto.

Si sobra tiempo tras P0, un acompañante experimental pequeño puede recoger, durante una actividad neutra y consentida, agregados de tiempos de interacción y movimiento del puntero, preferentemente procesados localmente. No recoger teclas, contraseñas, OTP ni contenido sensible; no extraer identidad desde la forma del copo. Explicar inscripción, muestra insuficiente/inicio en frío, cambio de dispositivo, deriva, reinicio, retención y eliminación; ofrecer teclado/tecnologías asistivas y exclusión voluntaria sin penalización. No actualizar silenciosamente la referencia durante un incidente: prevenir contaminación de la línea base y exigir reconfiguración explícita. Hasta tener evaluación, la variación no debe bloquear por sí sola ni declarar precisión, estrés o identidad.

### 4.4. Llamadas legítimas de bancos o policía sin una falsa lista blanca

Un número no guardado **no significa estafa**. La interfaz debe permitir «no confirmado» sin acusación y conservar el contexto de una llamada legítima. Ante una solicitud sensible, recomendar finalizar el contacto y abrir la aplicación oficial o usar el número de una tarjeta, estado de cuenta o sitio institucional obtenido por separado; no devolver automáticamente al historial ni usar el enlace, QR o teléfono dictado por quien llama. Un directorio propio requiere fuente, fecha de revisión, alcance y alternativa cuando esté desactualizado. No inventar teléfonos ni tratar un anuncio de buscador como autoridad.

En un contacto policial, pedir por iniciativa propia la verificación mediante el canal institucional correspondiente, sin entregar códigos o dinero para «validar» la llamada. No exigir que el usuario permanezca en una situación peligrosa para completar el flujo: ante riesgo físico inmediato, priorizar ponerse a salvo y los canales locales de emergencia verificados. Qhawix no confirma expedientes, órdenes ni identidad de agentes y no sustituye la atención de emergencia.

La SBS recomienda recontactar por canales oficiales. Banco de la Nación advierte sobre suplantación del número; su aviso fue localizado, pero la lectura directa quedó bloqueada. Android ofrece a determinadas aplicaciones nativas un veredicto del operador: no es una API web ni prueba de intención. Incluso `PASSED`, o una coincidencia con número oficial, no vuelve segura una solicitud de OTP. Fuentes del 17-10-2026: [SBS](https://www.sbs.gob.pe/usuarios/aprende-con-la-sbs/fraudes-digitales-y-telefonicos), [aviso de Banco de la Nación, acceso limitado](https://www.gob.pe/institucion/bn/noticias/821482-una-llamada-de-tu-banco-podria-no-serlo-spoofing-telefonico-suplantacion-de-numero-telefonico), [Android: verificación de número](https://developer.android.com/develop/connectivity/telecom/dialer-app/prevent-spoofing) y [FTC: recontacto independiente](https://consumer.ftc.gov/consumer-alerts/2026/01/how-handle-unexpected-calls-claim-your-money-risk). No se ha demostrado una API nacional accesible que autentique llamadas de bancos o policía en Perú; no afirmar cobertura operativa STIR/SHAKEN sin validación local y normativa.

## 5. Qué se puede reutilizar realmente

| Evidencia local | Hallazgo | Implicación propuesta |
|---|---|---|
| EchoTrap `capture.ts:64–106,141–174` | Micrófono del navegador, segmentos de cinco segundos y descarte de duración menor de cuatro | Reutilizar importación/conversión; no presentarlo como captura de llamadas |
| `capture.ts:157–174` y `CallExperience.tsx:113–133` | Espera al procesamiento remoto antes de reiniciar grabación | Existen huecos de captura; no prometer escucha continua |
| `evaluarAudio.ts:56–60` y `detections.ts:121–127` | Contenido condicionado a resultado acústico amarillo/rojo | Analizar conducta independientemente del detector |
| `TruthScanDetectionAdapter.ts:55–144` | Presign, carga, detección y polling | Integración escrita, pero acceso y ejecución sin verificar |
| `contenido.ts:5–15,58–60` | Adaptador Gemini activo; otras alternativas no activas | Verificar modelo y grounding antes de depender del servicio |
| `activarHoneypot.ts:11–50` | Frase predefinida y TTS, reproducidos localmente | No existe toma autónoma de llamada; diferir honeypot |
| `alerts.ts:4–21` y `schema.ts:6–37` | Alertas en navegador y persistencia parcial | Contacto de confianza no equivale a mensaje enviado |

Localizadores del código observado (rutas relativas a la raíz del repositorio externo EchoTrap, que no se incluye aquí): captura (`apps/web/lib/audio/capture.ts`, EchoTrap), experiencia (`apps/web/components/CallExperience.tsx`, EchoTrap), evaluación (`packages/backend/convex/usecases/evaluarAudio.ts`, EchoTrap), detecciones (`packages/backend/convex/detections.ts`, EchoTrap), TruthScan (`packages/backend/convex/adapters/TruthScanDetectionAdapter.ts`, EchoTrap), contenido (`packages/backend/convex/contenido.ts`, EchoTrap), honeypot (`packages/backend/convex/usecases/activarHoneypot.ts`, EchoTrap), alertas (`packages/backend/convex/alerts.ts`, EchoTrap) y esquema (`packages/backend/convex/schema.ts`, EchoTrap). Son evidencias estáticas, no pruebas de servicio.

La evidencia de Guardian tiene dos niveles, no solo Figma: el [PDF Guardian, pp. 6–8 y 10](back-guardian.pdf) propone transferencia/dashboard/modo ultraseguro/PIN (p. 6), inteligencia contextual, identidad, respuesta, datos y explicación (p. 7), coacción, adaptación a zona/hora, saldos ocultos y baja fricción (p. 8); SDK y validación de modelos aparecen como hoja de ruta (p. 10). El [pitch bancario, secciones V.2 y XVI.P4](<Pitch Ciberseguridad Bancaria Perú (1).md>) reconoce score simulado y backend desconectado. Son conceptos y limitaciones históricos, no prueba de operación bancaria.

El 17-10-2026 se inspeccionaron en navegador seis rutas de [Vigía](https://vigia-secure-view.lovable.app/): inicio, llamadas, finanzas, asistente, historial y ajustes. La muestra de falso secuestro generó **92 simulado** y apareció en historial; llamadas se declara simulada, las billeteras son ficticias y el asistente usa reglas. Se observaron controles de configuración, no su persistencia, eliminación ni cumplimiento de privacidad. Esta demo interactiva amplía la evidencia visual, pero no demuestra que Guardian histórico, modelos sensoriales, biometría, interceptación o bloqueo bancario estén implementados. El [dossier Guardian/Vigía](../.research/guardian-differentiation/FINDINGS.md) conserva procedencia y límites. Las políticas descritas en esta propuesta son inferencias nuevas, no funcionalidades verificadas de Vigía.

## 6. Alcance y prioridades

| Prioridad | Resultado propuesto | Condición de aceptación |
|---|---|---|
| P0 | Importar transcripción o audio consentido; analizar conducta | Un caso con voz humana sospechosa se analiza sin detector acústico |
| P0 | Mostrar fragmentos de evidencia, límites y acción segura | Cada señal enlaza con texto o intervalo disponible; no inventa identidad |
| P0 | Política contextual Guardian ligada a transferencia ficticia y línea de tiempo mínima | Regla visible, monto/destinatario/propósito, evidencia, decisión y corrección de contexto; cambios invalidan revisión previa |
| P0 | Recontacto institucional por fuente independiente | No convierte número oficial en lista blanca; muestra procedencia/fecha y alternativa si falta confirmación |
| P0 | Despliegue público con controles de acceso y costo | Camino funcional real, errores seguros y aislamiento entre sesiones |
| P1 | Detector acústico verificado | Acceso, formato, precio y muestra probados; admite `unavailable`/`inconclusive` |
| P1 | Mejoras de la billetera y evidencia exportable | No desplazan el análisis, la seguridad ni la entrega obligatoria |
| P1 | Acompañante conductual opcional y copo explicativo | Solo después del recorrido P0; inscripción, incertidumbre, accesibilidad y exclusión voluntaria; sin autenticación ni precisión atribuida |
| P2 | Telefonía propia, móvil/SDK y otros países | Nuevas autorizaciones, validación y presupuesto |

La pausa mínima es parte de la fusión y **tiene prioridad sobre comprar o integrar otro detector**. No implica construir una billetera completa. Si el tiempo impide un control honesto, se elimina la afirmación de intervención y se presenta un asistente de análisis; no se sustituye por una pantalla que simule una capacidad no existente.

**Fuera de alcance:** congelar cuentas reales, recibir OTP o contraseñas, realizar pagos, verificar identidad biométrica, entrenar modelos sensoriales, autenticar universalmente al llamante, interceptar llamadas ajenas o WhatsApp, perseguir extorsionadores, honeypot autónomo y plataforma general de desinformación. El acompañante P1 solo compara agregados de interacción consentidos dentro del mismo usuario, no levanta esta frontera. El análisis no sustituye a autoridades, asesoría legal ni confirmación con la institución o persona legítima.

## 7. Flujo demostrable y explicable

1. La persona abre la web y acepta el procesamiento de una muestra autorizada. Se indica origen: transcripción aportada, STT o fixture declarado; ningún texto aportado se presenta como transcripción certificada.
2. Importa un audio o pega una transcripción. Para audio, se valida formato, duración y tamaño; se informa destino y retención antes de enviarlo a un tercero.
3. El análisis conductual identifica solicitudes, urgencia, secreto, amenaza o inconsistencias con el contexto declarado. Las señales son indicios, no prueba de delito; se separan las citas del contenido inferido.
4. El resultado contiene `behavioralRisk`, `evidence`, `safeNextAction`, `acousticStatus` y procedencia. Si existe score acústico, se muestran proveedor, tramo analizado y estado; nunca se renombra como probabilidad de estafa.
5. En una pantalla claramente marcada como **simulación con dinero ficticio**, la persona intenta una operación. Guardian consume la evidencia y contexto declarado: monto, destinatario, propósito y cambios recientes. Una política determinista puede pedir pausa y recontacto por una fuente independiente; no pide códigos reales ni contacta a terceros automáticamente.
6. La revisión queda ligada a esa operación y a una vigencia explícita propuesta; cambiar monto/destinatario/propósito o vencer el plazo exige revisarla de nuevo. Marcar «verificado por el usuario» no equivale a confirmación criptográfica del banco. La línea de tiempo vincula comunicación, evidencia, versión de regla, acción revisada y decisión; no es un log de audio permanente.
7. Se muestra un caso legítimo no confirmado y otro con proveedor caído. La caída acústica no detiene contenido ni produce un falso resultado seguro. Se permite borrar el caso y se explica qué eliminación externa no está confirmada.

La política propuesta es ordinal, no probabilística: una solicitud de pago aislada no basta para pausar; la combinación explícita de solicitud económica y amenaza o presión/secreto puede requerir revisión. La evidencia insuficiente produce abstención. Esta regla es un punto de partida transparente para evaluar, no un modelo calibrado ni una política bancaria aprobada. Una salida de IA jamás autoriza por sí misma una transferencia o sanción.

## 8. Arquitectura y frontera de datos propuestas

**Camino principal:** Next.js → acción autenticada de Convex → análisis conductual del texto → persistencia mínima → interfaz reactiva → política de pausa en simulación propia. Un adaptador STT convierte audio cuando sea necesario; otro adaptador acústico opcional se ejecuta en paralelo lógico, sin gobernar la cobertura del contenido.

| Componente | Responsabilidad | Frontera y control |
|---|---|---|
| Cliente web | Consentimiento, importación y lectura de evidencia | Sin claves permanentes; contenido importado no confiable |
| Convex | Autorización, estados de trabajo y coordinación | Comprobar propietario, límites y cuota antes de inferencia |
| Adaptador STT | Texto e intervalos cuando existan | Distinguir errores de reconocimiento de palabras aportadas |
| Adaptador conductual | Evidencia estructurada y explicación | Validar esquema; instrucciones del audio no gobiernan al agente |
| Adaptador acústico | Señal de síntesis y metadatos del análisis | Ausencia, truncamiento y error como estados de primera clase |
| Política contextual Guardian | Evidencia de EchoTrap + contexto + detalles de acción → pausa/revisión determinista | Vincular revisión y caducidad a la acción; sin acceso a bancos, contactos ni credenciales reales |
| Línea de tiempo mínima | Conectar evidencia, procedencia, regla, acción y decisión del incidente | Fechas, versión y alcance; persistencia/borrado deben probarse, no inferirse de tarjetas UI |
| Almacenamiento | Resultado y trazabilidad mínima | Separar consentimiento, propietario, fechas, expiración y borrado |

Estados propuestos: `queued`, `processing`, `completed`, `failed`, más estado por proveedor. Guardar lo imprescindible: fuente declarada, versión de política/modelo disponible, intervalos analizados, errores sanitizados y autorización. Audio crudo no se conserva por defecto; transcripciones y evidencia requieren plazo explícito. La política exacta de retención y la eliminación en proveedores son decisiones pendientes, no controles implementados.

### Plataforma: web primero, sin promesas de interceptación

Apple confirma que una aplicación no puede leer el audio de llamadas que no transporta; Android reserva `CAPTURE_AUDIO_OUTPUT` para componentes privilegiados. El rol de screening ofrece metadatos limitados, no audio. Flutter usa capacidades nativas y no elimina esta frontera. Fuentes consultadas el 17-10-2026: [Apple DTS](https://developer.apple.com/forums/thread/841340), [Android AudioSource](https://developer.android.com/reference/android/media/MediaRecorder.AudioSource), [Android CallScreeningService](https://developer.android.com/reference/android/telecom/CallScreeningService) y [Flutter platform channels](https://docs.flutter.dev/platform-integration/platform-channels).

| Alternativa | Ventaja | Costo o restricción | Decisión |
|---|---|---|---|
| Web responsive/PWA | Reutilización y enlace público inmediato | Importación o micrófono autorizado; no llamadas generales | Recomendada |
| Flutter/nativo | Integración de compartir y experiencia móvil | Reescritura, permisos y distribución; misma frontera de audio | Posterior |
| VoIP transportado por la app | Audio propio autorizado en vivo | Cambia cómo se recibe la llamada y exige integración | Experimento posterior |
| FastAPI adicional | Útil si surge lógica Python validada | Segundo runtime y operación sin necesidad actual | No predeterminado |

El micrófono del navegador no es una llamada; la captura de pantalla/pestaña exige selección y depende de la superficie: [Chrome, captura de medios](https://developer.chrome.com/docs/extensions/how-to/web-platform/screen-capture), consultado el 17-10-2026. Apple permite exportar explícitamente grabaciones guardadas en Notes, pero grabación, transcripción y resúmenes tienen requisitos diferentes; la lista actual de transcripción incluye español de México/Estados Unidos, no una garantía peruana. Debe probarse el teléfono concreto: [guía Apple](https://support.apple.com/en-ph/guide/iphone/iph57c6590e9/ios) y [disponibilidad](https://www.apple.com/ios/feature-availability/), consultadas el 17-10-2026.

Una PWA **sí permite construir componentes visuales personalizados** con tecnologías web; la restricción relevante no es el diseño de la interfaz. Aquí importan permisos del sistema, ejecución en segundo plano, integración telefónica y formatos/codecs del navegador, que requieren pruebas por dispositivo. Un SDK delgado también es técnicamente posible para integrar una API o componente en una aplicación anfitriona; no concede audio privilegiado ni autoridad bancaria. Se difiere por falta de una necesidad de integración validada y por el plazo, no porque sea imposible.

Convex reactivo no equivale a inferencia streaming. Para la demo se propone carga por trabajo, sin nuevo servidor WebSocket. La documentación actual de Vercel sí declara WebSockets en beta pública desde junio de 2026, con Fluid Compute; no debe repetirse que son universalmente imposibles. Tampoco conviene introducir esa beta como dependencia crítica sin validación: [Vercel WebSockets](https://vercel.com/kb/guide/do-vercel-serverless-functions-support-websocket-connections), consultado el 17-10-2026.

## 9. Stack exacto: conservar la base, comprobar compatibilidad

Versiones observadas en pnpm-lock.yaml:9–88 (`pnpm-lock.yaml`, EchoTrap), complementadas por package.json (`package.json`, EchoTrap). No son una certificación de soporte, seguridad, ejecución ni «última versión».

| Pieza | Base observada | Tratamiento propuesto |
|---|---|---|
| Framework | Next.js 15.5.24 | Conservar inicialmente; revisar soporte y avisos vigentes |
| Interfaz | React y React DOM 19.2.8 | Comprobar peer dependencies y build con el lock |
| Backend | Convex 1.45.0 | Reutilizar; comprobar entorno y despliegue autorizado |
| IA | `@google/genai` 2.19.0 | Modelo `gemini-3.6-flash` observado, disponibilidad desconocida |
| Validación | Zod 3.25.76 | Validar entradas y salidas sin atribuir seguridad automática |
| TypeScript | 5.9.3 | No migrar por novedad durante esta entrega |
| Ejecución auxiliar | tsx 4.23.12; concurrently 9.2.4 | Conservar si las pruebas de compatibilidad lo permiten |
| Iconografía | lucide 1.35.0; morphicons 1.7.1 | Nombres y versiones comprobados en el lock |
| Tipos de desarrollo | `@types/node` 22.20.1; `@types/react` 19.2.18; `@types/react-dom` 19.2.5 | No confundir tipos Node 22 con runtime Node fijado |
| Gestor | pnpm 11.24.0 | Declarado en raíz; instalación congelada pendiente |
| Runtime | Node no fijado en la base | Candidato Node.js 24.22.0 LTS; no instalado/probado aquí |

Node 24.22.0 LTS fue publicado el 14-10-2026: [release oficial](https://nodejs.org/en/blog/release/v24.22.0). Antes de fijarlo, ejecutar en un entorno autorizado instalación con lock congelado, comprobaciones de tipos/build y revisión de compatibilidad del gestor. Si surge una incompatibilidad o aviso aplicable, resolverla de forma acotada; no ocultarla detrás de un upgrade masivo. Esas comprobaciones están pendientes.

Solo como alternativa no adoptada se verificaron FastAPI **0.143.4** y Python **3.14.8**; FastAPI declara soporte Python 3.14 desde 0.118.3. No constituyen una instalación ensayada. TypeScript **7.0.2** está publicado, pero el cambio de API del compilador afecta herramientas; Flutter **3.47.0** tiene notas oficiales, sin confirmar aquí el último parche o combinación Dart. Fuentes: [FastAPI](https://fastapi.tiangolo.com/release-notes/), [Python](https://www.python.org/downloads/), [TypeScript 7](https://devblogs.microsoft.com/typescript/announcing-typescript-7-0/) y [Flutter](https://docs.flutter.dev/release/release-notes/release-notes-3.47.0), consultadas el 17-10-2026.

## 10. Proveedores, costos y condiciones de adquisición

Deepgram aparece en EchoTrap como **TTS**; no hay prueba de STT activo. Su documentación permite proponer Nova-3 para transcripción española `es`/`es-419`, por archivo o streaming; transcribir no detecta clonación. Las claves permanentes quedan en servidor; los JWT temporales para una posible conexión directa futura expiran por defecto a los 30 segundos y se validan al establecerla. Fuentes: [modelos/idiomas](https://developers.deepgram.com/docs/models-languages-overview/) y [autenticación temporal](https://developers.deepgram.com/guides/fundamentals/token-based-authentication), consultadas el 17-10-2026.

| Servicio | Tarifa publicada al corte | Aritmética ilustrativa | Incertidumbre |
|---|---|---|---|
| Deepgram Nova-3 prerecorded monolingual | USD 0,0043/min | 100 × 0,0043 = **USD 0,43** | Cuenta, extras y acceso sin comprobar |
| Deepgram prerecorded multilingüe | USD 0,0052/min | 100 × 0,0052 = **USD 0,52** | No confundir con tarifa streaming |
| Resemble Detect Flex audio | USD 0,035/s | 100 × 60 × 0,035 = **USD 210** | Entitlement y consumo no probados |
| TruthScan audio | Desconocida | No calculable sin tarifa confirmada | No extrapolar créditos de imágenes/PDF |

Fuentes de tarifas, declaraciones únicas de cada proveedor: [Deepgram](https://deepgram.com/pricing), [Resemble](https://www.resemble.ai/pricing) y [TruthScan](https://truthscan.com/es/pricing), consultadas el 17-10-2026. Deepgram anuncia USD 200 para nuevas cuentas; no es saldo confirmado ni autorización de gasto. Los ejemplos excluyen LLM, almacenamiento, transferencia, hosting, impuestos y otros extras. Las suscripciones de chat no equivalen a créditos de API.

TruthScan documenta flujo asíncrono, archivos de 1 KB a 100 MB y análisis por defecto de los primeros 60 segundos; debe mostrarse truncamiento. Su precisión publicitada superior al 99 % no fue validada independientemente para el caso peruano. Duración mínima útil, SLA, precio y acceso de audio siguen abiertos; no convertir «sin resultado» en «seguro». Fuentes: [API de audio](https://truthscan.com/es/truthscan-ai-audio-detection-api-documentation) y [página comercial](https://truthscan.com/es/ai-voice-detector), consultadas el 17-10-2026.

Resemble es una alternativa documentada, no una recomendación de compra ni evidencia de mejor calidad. Su streaming requiere backend y procesa ventanas de unos cuatro segundos; el mínimo facturable de dos segundos no garantiza suficiencia de una muestra: [API streaming](https://docs.resemble.ai/detect/streaming), consultada el 17-10-2026. Seis clips de cinco segundos a USD 0,035/s cuestan **USD 1,05**, no menos de USD 0,25; se descarta la aritmética antigua del [PDF EchoTrap, p. 12](<echotrap-next (1).pdf>).

## 11. Seguridad, privacidad y principales riesgos

| Riesgo | Control propuesto | Límite de la evidencia |
|---|---|---|
| Inferencia pública a costo de la cuenta | Autenticación, propiedad, cuota, rate limit y tope de gasto | Los handlers actuales no demuestran estos controles |
| Audio de otras personas | Consentimiento específico, muestras guionadas y datos mínimos | Permiso de micrófono no autoriza todo uso posterior |
| Exposición de transcripciones | Retención corta declarada, acceso aislado, borrado y logs redactados | Plazo y eliminación externa pendientes de acuerdo |
| Prompt injection o URLs inventadas | Tratar comunicación como datos; esquema y grounding verificable | Parser actual no comprueba fuentes contra metadata |
| Falsos positivos o falsos negativos | Separar conducta/acústica, abstenerse y explicar | No hay precisión ni reducción de fraude medidas |
| Caída/cuota del proveedor | Timeout, reintento acotado, idempotencia y estado explícito | La carrera local de 12 segundos no prueba SLA |
| Demostración engañosa | Etiquetas de simulación y camino real observado | Prohibido resultado forzado presentado como inferencia |
| Titular legítimo coaccionado | Restricciones sobre la acción y recontacto independiente | Patrón habitual no demuestra consentimiento libre; no afirmar detección de coacción |
| Saldos ocultos o botón de pánico | No activarlos como protección predeterminada; evaluar seguridad con especialistas | Pueden aumentar el peligro si quien coacciona detecta el cambio; sin despliegue en esta demo |
| Referencia conductual invasiva o contaminada | Agregados mínimos, consentimiento, exclusión voluntaria y reconfiguración explícita | Señales opcionales, accesibilidad y deriva; sin identificación única ni actualización silenciosa durante incidentes |

La lectura estática de calls.ts:11–30 (`packages/backend/convex/calls.ts`, EchoTrap), detections.ts:62–88 (`packages/backend/convex/detections.ts`, EchoTrap) y contenido.ts:42–96 (`packages/backend/convex/contenido.ts`, EchoTrap) no muestra controles suficientes de propiedad y tamaño en acciones públicas. Es un riesgo previo que debe resolverse antes de exponer inferencia pagada, no una vulnerabilidad explotada en esta investigación.

El marco peruano identificado incluye Ley 29733 y DS 016-2024-JUS, pero los textos oficiales intentados devolvieron 403/418. No se ha verificado cumplimiento artículo por artículo ni se afirma conformidad. Quedan revisión legal cualificada, responsabilidades, transferencias y subencargados, uso para entrenamiento, tratamiento de voz y derechos de eliminación. Referencias oficiales de acceso limitado: [reglamento](https://www.congreso.gob.pe/Docs/DGP/DIDP/files/ds_016-2024-jus.pdf) y [normativa ANPD](https://www.gob.pe/institucion/anpd/colecciones/3482-normativa-de-proteccion-de-datos-personales), intento del 17-10-2026. No cargar datos de víctimas reales para suplir esa revisión.

**Objeción más fuerte:** importar después de la conversación puede llegar demasiado tarde; además, advertencias genéricas ya existen. Qhawix solo puede prometer asistencia antes de una decisión todavía pendiente. La hipótesis se debilita si los usuarios no importan a tiempo o no entienden la acción recomendada. Los detectores también cambian de comportamiento con compresión, idioma y generadores nuevos; se requiere evaluación propia, no confianza en un número comercial.

Como contraevidencia técnica, [RADAR Challenge 2026](https://arxiv.org/abs/2605.09568) evalúa dificultades de detección bajo transformaciones y condiciones multilingües. No es una validación de TruthScan ni una estimación de su rendimiento local; fue consultado el 17-10-2026.

La importación es **triaje posterior a la comunicación**, no prevención automática en tiempo real. Algunas personas habrán pagado antes de importar; en ese caso el producto no puede atribuirse prevención del hecho ya ocurrido. La pausa propia solo demuestra una intervención cuando la acción económica aún está pendiente. Medir ese intervalo y la disposición a importar es una validación de valor central, no un detalle de interfaz.

## 12. Validación: criterios antes de declarar éxito

No hay un RED ejecutable significativo para estos documentos pasivos: se verifican estructura y trazabilidad. Para una futura implementación autorizada, un test determinista pertinente debería observar RED → GREEN → REFACTOR. No utilizar scripts que escriben producción como suite de regresión: test-prod.ts:8–25 (`packages/backend/scripts/test-prod.ts`, EchoTrap) modifica registros; su ejecución requiere autorización separada.

| Prueba propuesta | Resultado esperado | Medición que no debe inventarse |
|---|---|---|
| Humano/estafa; humano/benigno; sintético/estafa; sintético/benigno | Conducta independiente del resultado acústico | Matrices de confusión separadas y cobertura por cuadrante |
| Audio comprimido/ruidoso, sin voz e idioma no previsto | Incertidumbre visible, sin seguridad fabricada | Abstención, errores y falsos avisos por condición |
| Citas e intervalos | Toda evidencia corresponde al contenido realmente disponible | Fidelidad de fragmentos y correcciones de STT |
| Proveedor caído/cuota/timeout | Camino de conducta útil o error honesto; sin bloqueo indefinido | p50/p95 por etapa y costo observado |
| Archivo malformado/sobredimensionado y otra sesión | Rechazo antes de inferencia y acceso denegado | Casos de límites/propiedad y borrado documentados |
| Operación ficticia | Pausa explicable, sin afectar fondos o cuentas reales | Comprensión y finalización de la verificación segura |
| Banco/policía legítimos desde número desconocido | Estado no confirmado sin acusación; recontacto independiente para solicitudes sensibles | Falsas pausas, comprensión y tiempo hasta resolver |
| Número oficial suplantado; veredicto ausente o `PASSED` con solicitud de OTP | Procedencia no anula riesgo de solicitud; jamás pedir/recibir OTP | Separación de los cuatro estados y abstención |
| Titular autorizado bajo coacción con interacción habitual | No declarar seguridad por coincidencia conductual; priorizar seguridad física | Límites de detección y ausencia de promesas de protección física |
| Cambio de monto/destinatario/propósito o revisión vencida | Invalidar revisión previa y evaluar la nueva acción | Pruebas deterministas del vínculo y caducidad |
| Directorio institucional desactualizado | Mostrar fuente/fecha y no dar confirmación automática | Ruta alternativa independiente sin inventar contacto |
| Teclado/lector de pantalla, nuevo dispositivo, inicio en frío o deriva | Camino accesible sin acompañante ni penalización automática | Fricción, abstención y falsas desviaciones; no precisión poblacional |
| Contaminación de referencia o reproducción de patrón | No actualizar silenciosamente durante un incidente ni confiar en patrón como autorización | Reinicio explícito, consentimiento y resistencia aún no medida |

Para una prueba exploratoria se propone comenzar con tres muestras autorizadas por cuadrante, **12 en total**, y documentar etiquetas/procedencia. Es un conjunto de ingeniería pequeño, no una estimación estadística de precisión. Evitar que la persona que inventó las reglas sea la única que etiquete. Incorporar hablantes locales y condiciones difíciles después de consentimiento; no generalizar el resultado a la población.

Criterios de salida de la demo: enlace público accesible desde otro equipo; al menos un análisis real observado; recorrido benigno y humano sospechoso; evidencia fiel; caída acústica tolerada; evidencia → política Guardian → pausa propia → recontacto independiente → decisión en línea de tiempo; cambio de detalles invalida revisión; sin secretos en cliente; entrega de todos los enlaces obligatorios. Las pruebas Guardian anteriores son adicionales al conjunto acústico/contenido de 12 muestras y todavía no fueron ejecutadas. Se registrarán fallos y pruebas omitidas. La reducción de fraude, precisión, latencia y demanda permanecen sin medir.

## 13. Rúbrica y entrega: demostrar, no decorar

La [rúbrica Hack the Andes, p. 1](hack-the-andes-rubrica-sponsors.pdf) sitúa el evento el 17–18 de octubre de 2026 y fija el domingo 18 a las **09:00**; **America/Lima es una inferencia**, no zona impresa. Exige URL pública, código GitHub y funcionamiento en vivo; una presentación, localhost o video por sí solos no puntúan. Las [indicaciones entregadas](recursos-indicaciones.txt) añaden URL de presentación y descripción.

| Criterio | Peso | Evidencia de la propuesta |
|---|---|---|
| Complejidad técnica | 30 % | Adaptadores, estados, separación conducta/acústica y política propia |
| Funcionamiento completo | 25 % | Importación a decisión, caso benigno y error real |
| Calidad técnica | 20 % | Límites, autorización, trazabilidad y pruebas pertinentes |
| Problema e impacto | 15 % | Usuario inicial concreto, evidencia acotada y experimento honesto |
| Claridad | 10 % | Demostración entendible y límites declarados |

Cinco jurados puntúan de 1 a 5; se promedian ponderados y complejidad/funcionamiento desempatan. El bonus de tracción de 0,25/0,5 requiere uso externo real y evidencia según el nivel, no el premio anterior. No crear usuarios o actividad ficticios para aparentar tracción. Los créditos de sponsors anunciados no son activación comprobada ni requisito de integrarlos todos.

**Contradicción pendiente:** indicaciones mencionan Track 04 Seguridad; el pie de la rúbrica dice tres tracks. Tampoco se han verificado reglas de reutilización, tamaño de equipo u obligaciones de sponsors. Debe resolverlo el organizador. El [PDF EchoTrap anterior](<echotrap-next (1).pdf>) pertenece a The Next Craft/Track 02 del 29-08-2026: no gobierna esta entrega. Su propuesta de botón oculto en p. 14 queda excluida.

### Secuencia relativa propuesta, solo después de autorizar implementación

Usar **T = cierre confirmado** y recalcular horas disponibles al iniciar; no reservar trabajo que termine después de T. Si ya se atravesó un bloque, reducir alcance, no prometer recuperar tiempo mediante integraciones no probadas.

| Ventana orientativa | Resultado y decisión de corte |
|---|---|
| T−17 a T−15 h | Confirmar reglas, Figma, roles, acceso y base reproducible; bloquear supuestos inviables |
| T−15 a T−11 h | Contenido independiente, evidencia y casos humano/benigno; limitar entradas y propiedad |
| T−11 a T−8 h | Integrar evidencia, política Guardian, pausa ficticia ligada a acción, recontacto independiente y línea de tiempo; comprobar recorrido completo |
| T−8 a T−5 h | Despliegue seguro y prueba externa; si falla lo básico, eliminar P1 |
| T−5 a T−3 h | P1 solo si P0 ya está verificado: detector usable o pequeño acompañante opcional; eliminar ambos antes que debilitar integración; registrar límites/costos |
| T−3 a T−1 h | Regresión acotada, demo y materiales; preparar enlaces y declarar límites |
| T−1 h a T | Congelar alcance, comprobar entrega y ensayar sin inventar resultados |

### Guion de demo y pitch

En una presentación de aproximadamente tres minutos, adaptable al tiempo oficial: abrir con el problema y usuario; mostrar una voz humana con presión económica; señalar dos fragmentos concretos; intentar una operación ficticia y explicar la pausa; contrastar un caso benigno y el detector no disponible; cerrar con stack real, límites y siguiente experimento. Un fixture reproducido debe estar rotulado. Un video puede respaldar la explicación, no reemplazar el funcionamiento exigido.

Mensaje central propuesto: **«EchoTrap explica la comunicación; Guardian protege la decisión concreta y ayuda a verificar antes de actuar».** No afirmar aprobación bancaria, casos evitados, porcentajes de eficacia ni autenticación del interlocutor. Para un hackathon de dos días, un recorrido realmente integrado es más defendible que simular múltiples sensores o una billetera completa.

## 14. Entradas faltantes y siguiente decisión

| Entrada pendiente | Para qué cambia la decisión |
|---|---|
| Confirmación del organizador: tracks, reutilización y zona horaria | Elegibilidad y orden de entrega |
| Figma accesible de Guardian y objetivo de la fusión | Ajustar la intervención, sin atribuir pantallas no inspeccionadas |
| Equipo, roles, hardware y tiempo real restante | Reducir alcance a un recorrido defendible |
| Acceso de proveedores y presupuesto explícito | Elegir STT/detector sin comprometer pagos no autorizados |
| Evidencia del premio: entidad, fecha, categoría y resultado | Redactar reconocimiento histórico verificable |
| Usuarios voluntarios y permisos de muestras | Validación y tracción legítimas |

**Siguiente paso recomendado:** resolver primero con el organizador la elegibilidad de reutilizar los prototipos en la categoría indicada. Después revisar Figma y aprobar un alcance de implementación separado. Hasta entonces este documento es una recomendación respaldada, no una orden para modificar el producto.

## 15. Investigación reutilizable y bibliografía de control

El [prompt maestro](prompt-maestro-investigacion.md) permite repetir y refutar esta propuesta. Las fuentes materiales están enlazadas junto a cada afirmación; el [dossier](../.research/qhawix-feasibility/FINDINGS.md) conserva bibliografía primaria, fuentes locales, fecha de consulta y bloqueos de acceso. La inspección de INEI fue textual; la revisión normativa quedó incompleta; no se inspeccionó Figma ni se verificó el premio.

Están disponibles `research`, `research-routing` y `web-search`. Se instaló únicamente la entrada `using-superpowers`, desde el [commit upstream inspeccionado](https://github.com/obra/superpowers/tree/bb92a77741419a4ab5f06e711a283343f1ada0c3/skills/using-superpowers); no se instaló la suite de brainstorming/planes. Un router no equivale a todos sus módulos. Las clasificaciones de modelos incluidas en skills no son evidencia del rendimiento de esta investigación.

NotebookLM puede organizar fuentes como complemento opcional, y otra sesión de Codex/Claude puede revisar de forma independiente si el usuario lo autoriza. Ninguno fue ejecutado aquí para validar la propuesta. No subir audios privados, código reservado ni credenciales sin autorización; contrastar toda síntesis con los originales.
