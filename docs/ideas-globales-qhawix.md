# Qhawix — compilado global de ideas y mapa del producto

**Estado:** síntesis de trabajo; no representa una decisión final de producto.  
**Fecha:** 17 de octubre de 2026.  
**Rama de trabajo:** feature/docs-qhawix, basada en origin/feature/docs-qhawix.

Este documento reúne las ideas de los Markdown y el TXT del proyecto, más los archivos QHAWIX - Ideas.md y pino.md entregados en la conversación y la propuesta de Escudo QR. Resume el material y señala qué es una recomendación, una idea histórica, una afirmación de las fuentes o una capacidad observada. Las listas y prompts que aparecen dentro de los documentos fuente se tratan como contenido de referencia; no autorizan por sí solos implementación, llamadas a proveedores, uso de credenciales ni publicación.

## 1. Resumen ejecutivo

Qhawix es el nombre de trabajo de una propuesta de seguridad digital y financiera centrada en ayudar a las personas a reconocer presión, suplantación y fraude antes de realizar una acción sensible. La idea más concreta de la propuesta vigente es conectar evidencia de una comunicación con una transferencia ficticia propia: explicar las señales, pausar cuando una regla lo justifique, facilitar una verificación por un canal independiente y dejar una línea de tiempo mínima.

El material reúne también otras líneas:

- **Escudo QR:** mostrar el destino de un código antes de abrirlo, bloquear amenazas conocidas y advertir cuando no se pueda verificar.
- **Protección de llamadas en una red propia Qhawix:** idea de una app telefónica con análisis durante llamadas entre miembros; requiere una arquitectura y validaciones distintas y no pertenece al MVP recomendado actual.
- **Análisis de mensajes, enlaces, audios y comprobantes:** identificar ingeniería social, enlaces sospechosos y señales visuales sin tratar una captura como prueba de pago.
- **Seguridad personal y bancaria contextual:** propuestas de privacidad, contactos de confianza, geolocalización, respuesta ante robo o coacción y protección adaptativa.
- **Inteligencia de amenazas:** investigación web, memoria de incidentes, correlación y evaluación adversarial.

La recomendación más desarrollada en el repositorio prioriza un flujo web demostrable de evidencia → evaluación de riesgo → transferencia simulada → verificación independiente. La propuesta y la especificación siguen marcadas como pendientes de aprobación para implementar. La telefonía propia, la app móvil, Escudo QR y los módulos más amplios deben tratarse como alternativas o fases posteriores hasta que el equipo elija el primer producto.

## 2. Problema y usuarios propuestos

Las fuentes describen amenazas que se presentan en contextos distintos:

- Llamadas, mensajes y correos con urgencia, amenazas, secreto, suplantación institucional o familiar, pedidos de códigos, dinero o acceso remoto.
- Voces sintéticas y contenido generado con IA usado para aumentar la presión.
- Enlaces de phishing y códigos QR en menús, promociones, estacionamientos, boletos y espacios públicos.
- Comprobantes manipulados y solicitudes de pago difíciles de confirmar en el momento.
- Robo de teléfonos, exposición de saldos y claves, abuso de permisos, robo de sesiones y observación de pantalla.
- Extorsión a comercios o transportistas, coacción, seguimiento y riesgo durante desplazamientos.
- Desinformación y noticias falsas, incluida en la descripción del track del material del evento.

La propuesta vigente plantea como usuario inicial a personas adultas que administran pequeños comercios urbanos peruanos y reciben solicitudes de pago por mensajería. Es una hipótesis por validar. Las ideas anteriores también abarcan familias, adultos mayores, usuarios de billeteras digitales y personas que escanean códigos QR en espacios públicos.

El resultado que se busca es que la persona entienda por qué una situación merece cautela y cómo verificarla antes de entregar dinero, códigos o datos. Qhawix no debe presentar una señal como prueba de delito ni prometer que evitará todas las estafas.

## 3. Mapa de ideas 

### 3.1 Evidencia de comunicaciones y SENTINEL

La línea SENTINEL propone recibir texto, enlaces, audios o capturas compartidas por la persona, identificar qué análisis corresponden, correlacionar evidencias y devolver una explicación con procedencia y una siguiente acción segura.

Análisis propuestos:

- Clasificación de mensajes y detección de urgencia, secreto, amenaza, suplantación o solicitud de códigos, transferencias y acceso remoto.
- Normalización y análisis de URL, reputación de dominios y redirecciones.
- Transcripción de audio aportado voluntariamente y análisis del contenido; una voz humana no demuestra que la llamada sea legítima.
- Detección acústica de voz sintética como señal complementaria, no como veredicto autónomo.
- OCR o análisis visual de capturas y comprobantes; la imagen no confirma por sí sola que se realizó un pago.
- Investigación de indicadores en fuentes públicas autorizadas y comparación con incidentes previos.

La idea original propone agentes especializados para recepción, URL, mensajes, imágenes, investigación, correlación, memoria, riesgo, respuesta, políticas y evaluación adversarial. No es necesario desplegar un agente independiente por tarea. La propuesta más reciente prefiere un camino base de reglas y contenido, con modelos como señales complementarias validadas y sin autoridad para decidir o ejecutar acciones.

### 3.2 Guardian: protección ligada a la acción

Guardian no se limita a mostrar una alerta. La idea central es relacionar la evidencia de una comunicación con una acción concreta y propia:

1. La persona registra una comunicación sospechosa mediante texto pegado o un archivo de texto; el audio, si se admite, requiere consentimiento y aviso de procesamiento.
2. El sistema extrae señales con citas del contenido y redacta códigos, tarjetas y datos sensibles antes de guardar o enviar texto a un proveedor.
3. La persona prepara una transferencia **ficticia**, con monto, moneda, destinatario y propósito.
4. Un motor determinista decide permitir, advertir o retener para revisión. El vínculo entre la revisión y la transferencia se invalida si cambian monto, destinatario o propósito.
5. Ante una retención, Qhawix recomienda terminar el contacto y verificar mediante una fuente independiente —por ejemplo, la aplicación oficial o el número de una tarjeta—, nunca usando el número, enlace o QR que aportó quien solicita el pago.
6. La persona declara el resultado de la verificación; Qhawix no afirma que sea una confirmación criptográfica de la institución.
7. Una línea de tiempo mínima conserva evidencia redactada, reglas aplicadas y decisión, con opción de borrar el caso.

Los cuatro estados se mantienen separados:

| Estado | Qué expresa | Qué no demuestra |
| --- | --- | --- |
| Procedencia del número | Si coincide con un directorio curado o si se desconoce | Quién habla, su intención o que la solicitud sea segura |
| Confirmación institucional | Resultado declarado por la persona tras intentar un contacto independiente | Identidad autenticada de un agente o autorización ilimitada |
| Riesgo de la solicitud | Señales de dinero, códigos, amenaza, secreto o cambio de destinatario | Delito probado o culpabilidad |
| Desviación conductual | Comparación opcional con una referencia de la misma persona | Identidad única, estrés, coacción o consentimiento libre |

Un número desconocido no convierte una llamada en fraude y una coincidencia con un directorio no la convierte en segura. Una institución legítima que pide un código o dinero también requiere cautela. Las reglas son ordinales y sus umbrales siguen siendo supuestos; no se deben mostrar porcentajes de fraude sin calibración.

### 3.3 Escudo QR

Propuesta recibida en la conversación, todavía no incorporada al alcance aprobado:

- Leer un QR con la cámara o desde una imagen compartida.
- Mostrar claramente el contenido y el destino antes de navegar.
- En enlaces, revisar dominio, reputación y redirecciones cuando sea posible.
- Bloquear dentro de Qhawix una amenaza conocida y explicar las señales.
- Advertir si el enlace es desconocido, la consulta falla o no hay conexión, para que la persona decida.
- Recomendar verificar el código con el negocio o entrar manualmente por su canal oficial.

La ausencia de reportes no demuestra seguridad; una página falsa nueva puede no estar registrada. Qhawix tampoco puede confirmar solo por el contenido del QR que el código fue colocado por el restaurante o comercio esperado. Revisar el destino no equivale a analizar cualquier archivo que el sitio pueda descargar. Escudo QR podría compartir la capa de URL y evidencia de SENTINEL, pero debe priorizarse frente al MVP Guardian.

### 3.4 Protección de llamadas Qhawix

pino.md describe una aplicación telefónica de red cerrada. Usuarios registrados con número verificado podrían llamarse dentro de Qhawix; la app sería el terminal y analizaría señales de audio y metadatos con aviso visible. Antes de contestar, se propone mostrar nombre registrado, antigüedad de cuenta, semáforo y motivos. Durante la llamada, reglas de contenido, transcripción y un detector acústico podrían actualizar la advertencia. El receptor recibiría el veredicto y un consejo concreto, como colgar y llamar al canal oficial.

La misma nota describe una alternativa limitada para llamadas celulares en Android: revisar metadatos del número, sin acceso al audio celular. Para números fuera de la red, abrir el marcador del sistema. El soporte de iOS queda sin definir.

Esta idea no debe confundirse con el MVP actual: la propuesta vigente excluye interceptar llamadas en vivo, llamadas ajenas o WhatsApp y clasifica telefonía propia, móvil y SDK como una línea posterior. El flujo de llamadas requeriría revisar consentimiento de ambas personas, APIs de plataforma, red, privacidad y requisitos legales antes de implementarse. Los pesos y umbrales de llamada de pino.md son hipótesis sin calibrar y no deben mezclarse con las reglas Guardian ya documentadas.

### 3.5 Seguridad bancaria contextual del prototipo

El prototipo “Banco Seguro IA” y los pitches antiguos plantean una experiencia bancaria con AURA (asistente visual persistente, incluida una activación por triple toque), panel de seguridad, alertas, límites por monto, modo nocturno, protección de fondos altos, ocultamiento de saldos, contactos de confianza, geolocalización, detección de anomalías, voz/gestos, cuentas señuelo y una vista de “doble resultado”. También aparecen ideas de cuentas seguras y transferencias automáticas ante ciertas condiciones.

Son ideas de interfaz y conceptos históricos. El documento de implementación existente reporta que la exportación es una UI local en memoria: el PIN, huella, voz, cámara, ubicación, bloqueos bancarios, mensajes y puntajes no demuestran esas capacidades reales. Las activaciones por ubicación, las cuentas seguras y las transferencias automáticas tampoco están implementadas ni validadas. La pantalla de éxito falso y la operación “señuelo” pueden confundir a una persona en riesgo; no forman parte del MVP propuesto. La propuesta vigente también excluye controlar bancos o billeteras reales, recibir OTP, ejecutar pagos, realizar autenticación biométrica o afirmar monitoreo invisible.

Las ideas relacionadas con Yape sugieren tres posibilidades distintas: ofrecer Qhawix como servicio o medio de monetización; mostrar orientación preventiva a la persona mientras usa una billetera; y verificar movimientos únicamente mediante una integración oficial y autorizada. Son propuestas, no integraciones existentes. No se presupone que exista una API pública ni que Qhawix pueda autorizar, detener o revertir pagos.

Ideas que podrían evaluarse más adelante, con límites y consentimiento:

- Recomendaciones de privacidad y ocultamiento de información dentro de pantallas de Qhawix.
- Guías para revocar sesiones y proteger cuentas después del robo de un teléfono.
- Temporizador de llegada, confirmación de bienestar y ubicación temporal con autorización.
- Contactos de confianza con vista previa, envío no automático y mínima exposición de datos.
- Una referencia conductual opcional, local y del mismo usuario; puede añadir una advertencia, pero nunca autenticar ni autorizar.

La observación de personas por cámara, bloqueo de transferencias ajenas, “cuenta segura”, falsos resultados de pago y protección automática invisible no se deben presentar como capacidades disponibles.

### 3.6 Inteligencia colectiva y módulos de expansión

TRUSTGRAPH propone relacionar dominios, URLs, campañas, mensajes, reportes, incidentes y fuentes. Cada elemento debe marcarse como confirmado, reportado o inferido; se necesitan controles contra reportes falsos y abuso.

Shield plantea niveles configurables de protección habitual, precaución y emergencia. PHANTOM se enfoca en privacidad frente a exposición o coacción dentro de Qhawix. Guardian puede extenderse a seguridad física. Sentinel Lab propone escenarios sintéticos, pruebas de prompt injection y comparación contra una línea base.

Otros temas del catálogo global: revisión limitada de permisos y aplicaciones sospechosas, seguridad frente a shoulder surfing, extorsión, deepfakes, fraude con billeteras y campañas de desinformación. Qhawix no debe prometer inspección irrestricta de otras apps, detección infalible de agresiones o deepfakes, ni intervención con autoridades.

## 4. Prioridades y alcance sugerido

La prioridad más respaldada por los documentos actuales es un flujo completo y comprobable, sin abrir todas las líneas al mismo tiempo.

### P0 — MVP recomendado en la propuesta vigente

- Aplicación web con ingreso de texto o transcripción. El traspaso técnico detallado mantiene el flujo actual en texto; la propuesta permite considerar audio aportado con consentimiento, pero su alcance, procesamiento, límites y ruta técnica siguen pendientes de decisión.
- Análisis conductual independiente del detector acústico, con fragmentos de evidencia, procedencia, incertidumbre y una acción segura.
- Transferencia ficticia con política Guardian determinista, ligada a monto, destinatario y propósito.
- Retención comprensible, devolución de llamada independiente declarada por el usuario y línea de tiempo mínima.
- Caso benigno, caso sospechoso, evidencia insuficiente y proveedor caído.
- Despliegue público seguro; distinguir datos simulados de análisis real.

### P1 — Solo después de completar P0

- Detector acústico si se verifican acceso, formato, costo y desempeño con muestras pertinentes.
- Acompañante conductual opcional, accesible y sin efecto de autorización.
- Mejoras del simulador y exportación de evidencia.
- Escudo QR como flujo independiente o como otra entrada al análisis de URL, previa decisión del equipo.

### P2 — Líneas futuras

- Red propia de llamadas Qhawix, versión móvil o SDK bancario.
- TRUSTGRAPH y memoria persistente; automatización n8n; MCP propio para incidentes o inteligencia.
- Guardian físico, Shield, PHANTOM y Sentinel Lab ampliado.
- Integraciones con billeteras, bancos, operadores o servicios de mensajería solo mediante permisos e interfaces oficiales.

Si no se puede demostrar una intervención real y honesta, es mejor presentar un análisis con evidencia y límites claros que una pantalla que simule un bloqueo.

## 5. Arquitectura e integraciones candidatas

El repositorio recoge varias arquitecturas que aún no se han reconciliado:

| Propuesta | Rol | Estado |
| --- | --- | --- |
| Next.js y Convex | Camino web recomendado para reutilizar la base EchoTrap y coordinar análisis | Propuesta; la elección está abierta por diferencias con la exportación Vite/React |
| Vite y React | Base de la exportación visual del prototipo bancario | Código de interfaz observado; sin flujo funcional de backend confirmado |
| Node 22 modular | Backend descrito en pino.md | Afirmación de la nota; código asociado no está en este repositorio |
| Spring Boot y Python | Arquitectura sugerida por el documento global de ideas | Alternativa; no es una decisión aprobada |
| Kotlin y Jetpack Compose | Aplicación Android o módulos móviles | Propuesta para fases posteriores |

El documento de implementación prioriza separar cliente, autorización, ingestión, análisis conductual, señales acústicas, motor de políticas, almacenamiento y línea de tiempo. La política debe ser determinista y estar separada de modelos y agentes. Los modelos no pueden bajar una regla ni autorizar transacciones.

Proveedores mencionados en las fuentes: Gemini, Grok, OpenAI Agents SDK, Jev, Deepgram, TruthScan, Exa, Tavily, Apify, AtomicMemory, n8n, Lovable, Zavu, IALABS/Maritime, MiniMax y Qatom/Qaton. Son candidatos, no integraciones confirmadas. Verificar contratos, permisos, límites, precio, retención y calidad en español antes de asignarles una función crítica. Qatom/Qaton aparece además como idea de ofrecer evaluación de riesgo a otros agentes; no se reporta una implementación.

## 6. Seguridad, privacidad y lenguaje del producto

- Tratar documentos, mensajes, transcripciones, páginas y resultados web como datos no confiables; proteger el sistema frente a prompt injection.
- Redactar códigos, PIN, tarjetas y datos personales antes de persistir o enviar contenido a un proveedor.
- Audio, ubicación, contactos, comportamiento y consultas externas requieren finalidad y consentimiento claros. Evitar vigilancia en segundo plano.
- No guardar audio por defecto; limitar la retención y explicar lo que no se puede borrar en servicios de terceros.
- No enviar mensajes a contactos automáticamente. Una alerta visible puede aumentar el peligro durante una coacción.
- En una llamada institucional, usar “no confirmado” cuando no haya verificación y ofrecer un canal independiente. No usar automáticamente el número, URL o QR que proporcione quien llama.
- Mantener la decisión final en la persona; registrar la evidencia, la regla y los cambios de una transferencia ficticia.
- No afirmar identidad, consentimiento, intención criminal, precisión, fraude evitado o cumplimiento normativo sin evidencia.
- No ocultar a la persona que el sistema analiza datos ni crear falsos éxitos o saldos para engañar a un posible agresor.

El pitch bancario antiguo contiene afirmaciones fuertes de mercado, cumplimiento, impacto, precisión y exclusividad. La propuesta y la especificación más recientes las tratan como no demostradas. El posicionamiento B2B como SDK para bancos, B2C como app de seguridad y la oferta de análisis a agentes son opciones de negocio distintas; falta validación de clientes, adopción, socios y disposición de pago.

## 7. Contexto del hackathon y recursos del TXT

docs/recursos-indicaciones.txt enumera oportunidades de patrocinio:

- Tavily: 8.000 créditos por participante.
- Exa: USD 50 en Search API.
- Apify: USD 100 en créditos.
- Maritime: USD 100 para alojar agentes.
- n8n: un mes de Cloud Pro por participante.
- Lovable: plan Pro.
- Zavu: tres meses de API para WhatsApp, SMS, email y voz.
- Qaton: seis meses de Plan Max por participante y hasta 1.000 ítems.
- AtomicMemory: cinco meses de Plan Pro por participante.

La nota también describe el Track 04 como extorsión, estafas, suplantación, voces clonadas y desinformación, y enumera entregables: URL desplegada, repositorio GitHub, URL de presentación y descripción del proyecto. Indica que localhost, solo slides o un video grabado no bastan para puntuar. Los créditos listados no prueban que una cuenta esté activada, que cubra un caso de uso concreto o que deba integrarse. El nombre aparece como Qaton en el TXT y Qatom en otras fuentes; confirmarlo. La propuesta documenta una discrepancia entre el Track 04 del TXT y la rúbrica, que debe resolverse con el organizador.

## 8. Contradicciones y decisiones pendientes

1. ¿El MVP será el flujo Guardian de comunicación a transferencia ficticia o una demo de protección de llamadas?
2. ¿Escudo QR será parte del MVP, una entrada del módulo de enlaces o una fase posterior?
3. ¿Qhawix se posicionará primero como prevención de fraude para pequeños comercios, seguridad bancaria, app personal o plataforma B2B?
4. ¿Qué base se conservará: Next.js/Convex, Vite/React, Node modular u otra composición? La propuesta y especificación mantienen la elección abierta.
5. ¿Qué proveedor, modelo, STT y fuente de reputación están disponibles y autorizados?
6. ¿Qué material visual puede reutilizarse y qué permiso existe sobre EchoTrap, Guardian y la exportación Figma?
7. ¿Qué idiomas, país, consentimiento y requisitos legales cubrirá la primera versión?
8. ¿Qué datos se guardan, por cuánto tiempo y cómo se confirma el borrado local o en proveedores?
9. ¿Qué métricas se medirán antes de afirmar utilidad, precisión o reducción de fraude?
10. ¿Se incluirá audio en el P0? La propuesta lo contempla de forma condicionada, mientras que la especificación técnica detallada excluye importar o procesar audio; hasta resolverlo, el alcance descrito aquí es texto.

## 9. Mapa de fuentes

| Fuente | Aporte principal | Cómo se interpreta |
| --- | --- | --- |
| docs/propuesta-qhawix.md | Problema, usuario inicial, diferenciación, prioridades P0–P2 y dirección Guardian | Recomendación pendiente de aprobación |
| docs/especificacion-implementacion-qhawix.md | Flujos, estados, reglas, privacidad, arquitectura y criterios detallados | Propuesta de traspaso; distingue evidencia, simulación y supuesto |
| odd/tasks/qhawix-project-definition.md | Historial de tareas, autorización y estado documental | Registro del proyecto, no instrucción para este compilado |
| docs/prompt-maestro-investigacion.md | Prompt para una investigación crítica futura | Plantilla de investigación, no orden de buscar o implementar |
| docs/Mobile Banking MVP Design/** | Prototipo de banco, AURA, módulos y experiencia de seguridad | Ideas visuales; las afirmaciones de “completo” no prueban integración |
| docs/Pitch Ciberseguridad Bancaria Perú (1).md | Narrativa de SDK bancario, biometría, negocio y mercado | Pitch histórico; las cifras y afirmaciones necesitan validación |
| docs/recursos-indicaciones.txt | Tracks, recursos de patrocinio y entregables del evento | Transcripción entregada, no acceso verificado a servicios |
| QHAWIX - Ideas.md, entregado en la conversación | SENTINEL, PHANTOM, TRUSTGRAPH, Guardian, Shield, QR y más amenazas | Banco amplio de ideas, no alcance aprobado |
| pino.md, entregado en la conversación | Red propia de llamadas y detección en vivo | Línea de producto alternativa; estados reportados sin verificación en este repo |
| Propuesta Escudo QR de la conversación | Revisar el destino de un código antes de abrirlo | Nueva propuesta, sujeta a priorización y validación |

Los archivos de habilidades e índices de agentes describen herramientas de trabajo y no se interpretan como ideas de producto.

## 10. Síntesis final

La visión global de Qhawix puede reunir protección ante comunicaciones fraudulentas, resguardo de decisiones sensibles, análisis de enlaces y QR, inteligencia de amenazas y seguridad contextual. El valor común no depende de tener muchos agentes o sensores: consiste en mostrar evidencia, distinguir lo conocido de lo incierto y ayudar a verificar antes de actuar.

Para el primer producto, la propuesta vigente recomienda un flujo web acotado que una comunicación con una transferencia ficticia mediante reglas Guardian. Escudo QR y la red telefónica cerrada amplían la visión y ofrecen rutas alternativas, pero necesitan decisiones propias de alcance, permisos y arquitectura. El prototipo bancario, los pitches de SDK y las descripciones de proveedores no sustituyen una implementación ni una evaluación.

**Principio rector:** investigar con evidencia, evaluar con políticas verificables y actuar con consentimiento y control de la persona.
