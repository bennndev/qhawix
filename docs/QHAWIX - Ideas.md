# **QHAWIX**

## **Documento maestro de ideas, arquitectura tecnológica y definición del MVP**

**Propósito:** consolidar todas las ideas propuestas para Qhawix, identificar las capacidades técnicas necesarias y proporcionar una base común para que el equipo evalúe alternativas y defina el MVP de la hackathon.

**Estado:** exploración de producto y arquitectura. Las tecnologías y funcionalidades mencionadas son propuestas; su implementación dependerá del tiempo disponible, las condiciones de los créditos y las capacidades reales de cada plataforma.

---

# **1\. Visión del proyecto**

Qhawix es una propuesta de plataforma inteligente de seguridad personal, digital y financiera que utiliza agentes de inteligencia artificial, herramientas externas, protocolos MCP y análisis contextual para identificar riesgos, investigar amenazas y coordinar respuestas preventivas.

La visión es construir algo más ambicioso que un antivirus, un chatbot de ciberseguridad o una aplicación SOS convencional: un sistema capaz de correlacionar señales de distintas fuentes, investigar escenarios sospechosos, explicar sus conclusiones y recomendar o ejecutar acciones autorizadas.

### **Problema que buscamos resolver**

Las personas se enfrentan a amenazas que suelen tratarse por separado:

* Phishing, smishing y páginas fraudulentas.  
* Suplantación de identidad y estafas mediante inteligencia artificial.  
* Comprobantes falsos y fraudes relacionados con billeteras digitales.  
* Robo de credenciales, sesiones y dispositivos.  
* Exposición de información mediante *shoulder surfing*.  
* Extorsión, coacción y situaciones de peligro físico.  
* Seguimiento no deseado y riesgos durante desplazamientos.  
* Aplicaciones maliciosas y abuso de permisos.  
* Dificultad para verificar información antes de realizar una acción sensible.

Qhawix busca conectar estas amenazas mediante un sistema de inteligencia que transforme señales aisladas en evaluaciones de riesgo explicables.

### **Propuesta de valor**

**Qhawix investiga, correlaciona y responde ante amenazas digitales y físicas mediante agentes de IA especializados, inteligencia externa y políticas de seguridad controladas.**

Su diferenciación potencial reside en cinco capacidades:

1. Investigación paralela mediante agentes especializados.  
2. Correlación temporal de evidencias en un grafo de amenazas.  
3. Memoria persistente de incidentes con procedencia y estado de verificación.  
4. Protección contextual que se adapta a las preferencias del usuario.  
5. Respuestas coordinadas con límites de autorización y auditoría.

No se presupone que Qhawix sea el primer producto en ofrecer estas capacidades. La innovación deberá demostrarse mediante una implementación funcional y evaluaciones comparativas.

---

# **2\. Conceptos y líneas de producto propuestas**

## **2.1. SENTINEL — Sistema inmunológico digital**

Concepto principal para Qhawix.

Un sistema multiagente que recibe información sospechosa, investiga distintas señales, correlaciona evidencias y determina qué respuesta es apropiada.

Ejemplo: el usuario comparte un mensaje que suplanta a un familiar, contiene un enlace sospechoso y adjunta una captura de un supuesto pago. Qhawix analiza cada elemento por separado y combina los resultados para explicar el riesgo.

**Tecnologías propuestas:**

* Grok API para razonamiento y análisis.  
* OpenAI Agents SDK como alternativa o marco de orquestación de agentes.  
* MCP para conectar herramientas externas.  
* Exa y Tavily para investigación web.  
* Apify para extracción autorizada de información pública.  
* AtomicMemory para memoria de investigaciones.  
* PostgreSQL para datos estructurados.  
* n8n para automatizaciones.  
* Backend propio para políticas, autorización y auditoría.

## **2.2. PHANTOM — Protección frente a exposición y coacción**

Concepto orientado a situaciones en las que una persona puede estar siendo observada, presionada o forzada a utilizar su teléfono.

Funciones posibles:

* Interfaz de privacidad dentro de Qhawix.  
* Ocultación de información sensible en pantallas propias.  
* Reducción de vistas previas de notificaciones configurables.  
* Acceso rápido a un protocolo de emergencia.  
* Contactos de confianza y acciones previamente configuradas.  
* Investigación de capacidades oficiales del sistema operativo para aplicar restricciones adicionales.

Limitaciones: una aplicación convencional no puede garantizar que se ocultará de otras aplicaciones ni que permanecerá invisible ante una persona que controla físicamente el teléfono. No debe prometer protección infalible contra la coacción.

**Tecnologías propuestas:** Kotlin, Jetpack Compose y APIs oficiales de Android; evaluación posterior de mecanismos de privacidad y restricciones de aplicaciones en iOS.

## **2.3. TRUSTGRAPH — Grafo de inteligencia sobre amenazas**

Sistema que relaciona indicadores y eventos de seguridad.

Entidades posibles:

* Dominios y URLs.  
* Campañas de phishing.  
* Mensajes y patrones de suplantación.  
* Reportes de amenazas.  
* Comprobantes analizados.  
* Indicadores técnicos.  
* Fuentes de información y resultados de investigación.

Cada relación debe distinguir entre evidencia confirmada, reporte de usuario e inferencia del modelo.

**Tecnologías propuestas:**

* PostgreSQL como almacenamiento principal.  
* pgvector para recuperación semántica.  
* Grafo de conocimiento implementado inicialmente en tablas relacionales o estructuras de nodos y aristas.  
* Evaluación de una base de datos de grafos dedicada si el volumen y las consultas lo justifican.  
* AtomicMemory para recuperación contextual de investigaciones anteriores.

No es obligatorio desplegar una base de datos de grafos independiente en el MVP.

## **2.4. Guardian — Seguridad física contextual**

Sistema que permite definir reglas personales de seguridad.

Funciones posibles:

* Configuración de zonas habituales y horarios.  
* Temporizador de llegada.  
* Detección de desviaciones respecto de una ruta elegida, cuando sea técnicamente viable.  
* Preguntas de confirmación de bienestar.  
* Contactos de confianza.  
* Compartición temporal de ubicación.  
* Botón SOS.  
* Instrucciones para actuar ante robo del teléfono.  
* Acceso a procedimientos para bloquear cuentas y líneas telefónicas.

La ubicación y la hora son señales contextuales, no pruebas de peligro. Las reglas deben ser configurables, transparentes y desactivables.

**Tecnologías propuestas:** Kotlin, Jetpack Compose, APIs de ubicación de Android, geocercas, notificaciones y backend de eventos. Firebase Cloud Messaging puede utilizarse para notificaciones remotas si se necesita.

## **2.5. Shield — Modo de Protección Adaptativa**

Sistema de protección por niveles.

**Nivel 1: Protección habitual**

* Análisis de enlaces.  
* Alertas sobre amenazas conocidas.  
* Recomendaciones de privacidad.  
* Revisión de permisos y señales de riesgo.

**Nivel 2: Precaución**

* Advertencias reforzadas.  
* Ocultación de información sensible dentro de Qhawix.  
* Recordatorios antes de acciones sensibles.  
* Activación de reglas de privacidad configuradas por el usuario.

**Nivel 3: Emergencia**

* Acceso rápido a SOS.  
* Contactos de confianza.  
* Compartición de ubicación autorizada.  
* Procedimientos para proteger cuentas y dispositivos.

La activación puede depender de reglas definidas por el usuario, eventos verificables y confirmaciones. No se debe permitir que un agente bloquee arbitrariamente el dispositivo.

## **2.6. Sentinel Lab — Laboratorio adversarial**

Sistema de pruebas para evaluar las defensas de Qhawix.

Funciones posibles:

* Generación de escenarios sintéticos de phishing.  
* Variaciones de mensajes para probar robustez.  
* Pruebas de instrucciones maliciosas dirigidas a agentes.  
* Comparación entre un detector convencional y el sistema multiagente.  
* Medición de precisión, recall, falsos positivos, falsos negativos, latencia y coste.  
* Registro de fallos y evaluación de mejoras.

**Tecnologías propuestas:** Python, scripts de evaluación, conjuntos de datos sintéticos, API de Grok y herramientas de evaluación del backend.

Este módulo puede ser interno y utilizarse para demostrar rigor técnico ante los jueces.

---

# **3\. Catálogo completo de amenazas y funcionalidades**

## **3.1. Phishing, smishing y páginas falsas**

**Problema:** mensajes de WhatsApp, SMS, correos y páginas que suplantan bancos, familiares o empresas.

**Funcionalidades:**

* Compartir un enlace con Qhawix.  
* Normalizar y analizar el dominio.  
* Consultar fuentes de reputación.  
* Investigar redirecciones cuando sea posible.  
* Detectar señales de suplantación.  
* Explicar qué evidencia justifica la advertencia.  
* Recomendar abrir el servicio oficial directamente.

**Tecnologías:** Grok, Exa, Tavily, APIs de reputación de URLs, herramientas MCP propias y backend de evaluación.

Una fuente que puede evaluarse es Google Safe Browsing para usos compatibles; para un producto comercial debe revisarse Google Web Risk u otra solución adecuada según sus condiciones.

## **3.2. Comprobantes falsos y fraude con billeteras digitales**

**Problema:** capturas de pantalla manipuladas o falsas que aparentan confirmar un pago.

**Funcionalidades:**

* Extracción de importe, fecha, destinatario y otros campos.  
* Detección de inconsistencias.  
* Comparación con formatos de referencia conocidos.  
* Identificación de elementos visuales sospechosos.  
* Explicación de lo que se puede y no se puede verificar.  
* Confirmación independiente si existe una integración financiera autorizada.

**Tecnologías:** OCR mediante ML Kit u otra alternativa evaluada, modelo de visión compatible, Grok cuando admita el análisis requerido y un motor de reglas.

Mensaje fundamental: «Comprobante analizado; pago no verificado». Una imagen no demuestra por sí sola que una transferencia se haya realizado.

## **3.3. Integración con Yape**

Hay que diferenciar tres escenarios:

1. **Aceptar pagos para monetizar Qhawix:** evaluar proveedores y métodos de pago que admitan Yape.  
2. **Consultar movimientos o verificar operaciones:** requiere una integración oficial que autorice ese acceso.  
3. **Proteger al usuario mientras usa Yape:** puede realizarse mediante análisis de contenido compartido, advertencias, recomendaciones y procedimientos de respuesta.

No se debe diseñar el MVP suponiendo que existe una API pública que permite bloquear transferencias o controlar cuentas personales de Yape.

## **3.4. Shoulder surfing**

**Problema:** una persona observa el PIN, contraseñas, mensajes o saldo mientras el usuario utiliza el teléfono.

**Funcionalidades:**

* Modo de privacidad en Qhawix.  
* Ocultación de información sensible en interfaces propias.  
* Recomendaciones contextuales.  
* Reducción de vistas previas de notificaciones configurables.  
* Investigación de mecanismos oficiales de protección adicionales.

La detección automática de observadores mediante la cámara es experimental y presenta limitaciones de privacidad, precisión y permisos.

## **3.5. Aplicaciones maliciosas y robo de sesiones**

**Problema:** aplicaciones sospechosas, abuso de permisos, superposiciones engañosas y robo de credenciales.

**Funcionalidades:**

* Revisión de permisos accesibles.  
* Orientación para identificar aplicaciones sospechosas.  
* Alertas basadas en indicadores verificables.  
* Procedimientos de respuesta ante robo del dispositivo.  
* Ayuda para revocar sesiones y proteger cuentas.

La inspección de otras aplicaciones está limitada por Android, iOS y las políticas de sus tiendas. Qhawix no debe prometer acceso irrestricto al contenido de otras apps.

## **3.6. Extorsión, robo y peligro físico**

**Funcionalidades:**

* SOS.  
* Contactos de confianza.  
* Temporizador de llegada.  
* Compartición temporal de ubicación.  
* Instrucciones de emergencia.  
* Acceso rápido a procedimientos de bloqueo de cuentas y líneas telefónicas.

El sistema facilita una respuesta, pero no puede garantizar la detección o prevención de una agresión.

## **3.7. Deepfakes y suplantación mediante IA**

**Problema:** voces clonadas, mensajes personalizados y solicitudes fraudulentas de dinero.

**Funcionalidades:**

* Análisis de transcripciones o audios compartidos voluntariamente.  
* Detección de urgencia y patrones de ingeniería social.  
* Recomendación de verificar mediante un canal independiente.  
* Configuración de palabras de seguridad con contactos cercanos.

No se debe confiar exclusivamente en un detector de voz sintética.

## **3.8. Inteligencia colectiva de amenazas**

**Funcionalidades:**

* Reporte de dominios sospechosos.  
* Agrupación de incidentes similares.  
* Detección de campañas repetidas.  
* Comparación con fuentes externas.  
* Actualización de la memoria de amenazas.  
* Controles contra reportes falsos y abuso del sistema.

**Tecnologías:** n8n, Exa, Tavily, Apify cuando sea apropiado, PostgreSQL y AtomicMemory.

## **3.9. Protección frente a prompt injection**

Las páginas web, mensajes y documentos analizados pueden contener instrucciones maliciosas dirigidas a los agentes.

**Defensas propuestas:**

* Tratar el contenido investigado como datos no confiables.  
* Separar instrucciones del sistema y contenido de terceros.  
* Limitar las herramientas disponibles por agente.  
* Validar las salidas estructuradas.  
* Exigir autorización para acciones sensibles.  
* Registrar llamadas a herramientas y resultados.  
* Probar ataques sintéticos mediante Sentinel Lab.

---

# **4\. Arquitectura multiagente propuesta**

## **4.1. Agentes especializados**

### **Agent 1 — Intake & Classification**

Recibe el contenido compartido, identifica su tipo y define qué análisis hacen falta.

### **Agent 2 — URL Intelligence**

Examina dominios, reputación, redirecciones y señales de phishing.

### **Agent 3 — Message & Social Engineering**

Analiza urgencia, suplantación, manipulación emocional y solicitudes sospechosas.

### **Agent 4 — Visual & Receipt Analysis**

Extrae datos de capturas, busca inconsistencias y explica las limitaciones de la verificación visual.

### **Agent 5 — Threat Research**

Investiga fuentes web y recupera evidencias adicionales mediante Exa, Tavily u otras herramientas.

### **Agent 6 — Threat Correlation**

Relaciona los resultados con incidentes y campañas previas. Construye o actualiza el grafo de evidencias.

### **Agent 7 — Memory & Learning**

Recupera casos similares, registra resultados con procedencia y propone actualizaciones de memoria sujetas a validación.

### **Agent 8 — Risk Assessment**

Combina resultados estructurados mediante reglas y criterios definidos. Distingue hechos, inferencias y datos insuficientes.

### **Agent 9 — Response Planner**

Propone acciones proporcionales al riesgo: advertir, solicitar confirmación, recomendar una verificación independiente o facilitar un protocolo de emergencia.

### **Agent 10 — Safety & Policy**

Valida permisos, restricciones y acciones permitidas. Puede rechazar una acción aunque los agentes investigadores la recomienden.

### **Agent 11 — Adversarial Evaluator**

Prueba escenarios sintéticos y mide la calidad de las decisiones.

No es necesario implementar once agentes independientes en el MVP. Se pueden agrupar funciones para reducir latencia, complejidad y coste.

## **4.2. Flujo de investigación**

1. El usuario comparte un mensaje, enlace o captura.  
2. Intake identifica los elementos y genera un identificador de incidente.  
3. Los agentes pertinentes investigan en paralelo.  
4. Los resultados se validan mediante esquemas estructurados.  
5. Threat Correlation relaciona las evidencias.  
6. Risk Assessment evalúa el escenario.  
7. Safety & Policy determina qué respuestas están autorizadas.  
8. El usuario recibe una explicación y una recomendación.  
9. Se registran los resultados relevantes.  
10. AtomicMemory puede conservar información útil, con procedencia y estado de verificación.

Los agentes no deben ejecutar acciones irreversibles ni controlar cuentas financieras.

---

# **5\. MCP: servidores, herramientas y responsabilidades**

MCP significa Model Context Protocol. Es un protocolo para conectar aplicaciones de IA con herramientas y recursos externos; no sustituye a los agentes, al backend ni al motor de políticas.

## **5.1. ¿Debemos crear nuestro propio MCP?**

La propuesta es desarrollar uno o varios servidores MCP propios cuando aporten una interfaz reutilizable, permisos claros y una capacidad diferencial.

No es necesario crear un servidor MCP para cada servicio externo. Si un proveedor ya ofrece una integración adecuada, se puede utilizar directamente o mediante un workflow de n8n.

### **Qhawix Threat Intelligence MCP**

Servidor propio que expone herramientas como:

* `analyze_url`: analiza una URL mediante fuentes autorizadas.  
* `search_threat_intelligence`: investiga indicadores de amenaza.  
* `get_related_incidents`: recupera incidentes relacionados.  
* `get_indicator_reputation`: consulta reputación y procedencia.  
* `correlate_evidence`: relaciona evidencias de un incidente.  
* `get_incident_summary`: devuelve un resumen estructurado.  
* `submit_threat_report`: registra un reporte sujeto a validación.

### **Qhawix Incident MCP**

Herramientas posibles:

* `create_incident`  
* `get_incident`  
* `append_evidence`  
* `get_incident_timeline`  
* `get_risk_assessment`  
* `get_recommended_actions`

### **Qhawix Guardian MCP**

Herramientas posibles, con autorización estricta:

* `get_safety_preferences`  
* `get_arrival_timer_status`  
* `request_safety_check`  
* `prepare_emergency_protocol`  
* `request_location_sharing`

Las herramientas de emergencia deben tener límites claros y no activar acciones sensibles sin la autorización exigida.

### **Qhawix Evaluation MCP**

Herramientas para el laboratorio interno:

* `run_synthetic_scenario`  
* `evaluate_detection_result`  
* `compare_model_outputs`  
* `get_benchmark_summary`

Los nombres anteriores son propuestas de diseño, no APIs existentes.

## **5.2. Tecnología para desarrollar MCP**

Alternativas:

* Python con el SDK oficial de MCP.  
* TypeScript con el SDK oficial de MCP.  
* Servidores MCP proporcionados por los propios proveedores.  
* n8n como consumidor o expositor de herramientas MCP, según la configuración disponible.

Para el primer servidor propio, elegiría Python si el equipo ya lo utiliza para IA y análisis de datos, o TypeScript si busca mantener una sola base tecnológica para herramientas y backend.

El servidor MCP debe conectarse a servicios mediante credenciales almacenadas de forma segura. No debe confiar en que un agente solicite una acción significa que está autorizado a realizarla.

---

# **6\. Herramientas y créditos disponibles en la hackathon**

La selección definitiva debe verificarse con las condiciones de cada beneficio.

## **Grok**

**Función propuesta:** razonamiento, análisis de mensajes, generación de hipótesis y escenarios sintéticos.

Uso:

* Análisis de ingeniería social.  
* Extracción de evidencias estructuradas.  
* Investigación asistida, si la API habilitada admite las funciones necesarias.  
* Generación de casos adversariales.

## **n8n Cloud Pro**

**Función propuesta:** automatización de workflows.

Uso:

* Orquestación de investigaciones.  
* Ejecución de tareas programadas.  
* Integración con APIs.  
* Notificaciones.  
* Registro de incidentes.  
* Procesos de actualización de inteligencia.

El backend debe conservar el control de las autorizaciones críticas.

## **Exa**

**Función propuesta:** búsqueda web para agentes.

Uso:

* Investigar dominios y entidades.  
* Recuperar información relevante.  
* Buscar referencias públicas sobre campañas sospechosas.  
* Contrastar hipótesis.

## **Tavily**

**Función propuesta:** búsqueda web adicional.

Uso:

* Investigación complementaria.  
* Contraste de resultados.  
* Recuperación de información actualizada.

No se deben utilizar ambos proveedores automáticamente en cada consulta. Se recomienda enrutamiento por necesidad y presupuesto.

## **Apify**

**Función propuesta:** extracción de información pública y ejecución de Actors.

Uso:

* Recolectar datos públicos autorizados.  
* Enriquecer investigaciones.  
* Preparar datasets de amenazas.  
* Integrar capacidades mediante MCP cuando resulte útil.

No se debe recolectar información privada ni incumplir términos de uso.

## **AtomicMemory**

**Función propuesta:** memoria persistente para agentes.

Uso:

* Recuperar investigaciones previas.  
* Recordar patrones de campañas.  
* Conservar procedencia de las evidencias.  
* Mantener contexto entre sesiones.

Debe distinguir hechos confirmados, reportes e inferencias. Una conclusión incorrecta no debe convertirse automáticamente en una verdad persistente.

## **Lovable**

**Función propuesta:** desarrollo rápido de la interfaz.

Uso:

* Dashboard de incidentes.  
* Panel de agentes.  
* Visualización del grafo de amenazas.  
* Cronología de investigación.  
* Explicaciones y resultados.

La interfaz debe conectarse al backend real para que la demostración refleje resultados auténticos.

## **Maritime / IALABS**

**Función propuesta:** evaluar capacidades de despliegue y operación de agentes.

Antes de integrarlo, verificar las funciones incluidas en el beneficio y compararlas con el despliegue convencional de un servicio de Python.

## **Zavu**

Beneficio pendiente de verificar. Confirmar producto, API, condiciones y límites con el equipo del evento antes de asignarle una responsabilidad crítica.

## **Qatom**

Beneficio pendiente de verificar. Revisar el acceso concedido y su utilidad concreta antes de incorporarlo a la arquitectura.

---

# **7\. Stack tecnológico general**

| Capa | Tecnología propuesta | Responsabilidad |
| ----- | ----- | ----- |
| Aplicación Android | Kotlin \+ Jetpack Compose | Interfaz móvil y funcionalidades de Guardian |
| Dashboard web | Lovable, frontend generado y adaptado | Investigación y visualización |
| Backend principal | Spring Boot | API, usuarios, incidentes, autorización y políticas |
| Servicios de IA | Python | Agentes, análisis y evaluación |
| Orquestación de agentes | Grok API y/o OpenAI Agents SDK | Razonamiento y delegación |
| Automatización | n8n | Workflows y tareas asíncronas |
| Protocolo de herramientas | MCP | Conexión estandarizada con herramientas |
| Base de datos | PostgreSQL | Incidentes, usuarios, eventos y evidencias |
| Recuperación semántica | pgvector | Búsqueda de casos similares |
| Memoria de agentes | AtomicMemory | Contexto persistente |
| Búsqueda web | Exa \+ Tavily | Investigación y contraste |
| Extracción web | Apify | Recolección autorizada |
| OCR | ML Kit u otra alternativa | Extracción de datos de capturas |
| Notificaciones | Firebase Cloud Messaging, si hace falta | Alertas remotas |
| Evaluación | Python \+ datasets sintéticos | Métricas y pruebas adversariales |

No es obligatorio implementar toda esta arquitectura en el MVP. El backend Spring Boot puede ser la API central y delegar el análisis a un servicio de Python; n8n se encarga de los workflows operativos.

---

# **8\. Casos de demostración**

## **Caso A — Estafa con suplantación y comprobante**

1. El usuario comparte un mensaje urgente.  
2. Un agente analiza el lenguaje y la posible suplantación.  
3. Otro analiza la URL.  
4. Otro extrae información del comprobante.  
5. El sistema correlaciona las evidencias.  
6. La aplicación explica el riesgo y recomienda verificar al remitente por un canal conocido y comprobar la operación en la fuente oficial.

## **Caso B — Campaña de phishing previamente desconocida**

1. El usuario reporta un dominio sospechoso.  
2. Qhawix investiga fuentes públicas.  
3. La búsqueda identifica páginas o reportes relacionados.  
4. El grafo conecta los indicadores.  
5. La memoria registra el incidente con procedencia y estado de verificación.  
6. Un caso posterior puede recuperar la información relevante.

## **Caso C — Seguridad física**

1. El usuario configura un temporizador de llegada.  
2. El temporizador vence.  
3. La aplicación solicita una confirmación de bienestar.  
4. Si el usuario indica que necesita ayuda, puede iniciar un protocolo autorizado.  
5. El sistema facilita el contacto con una persona de confianza.

Este caso puede utilizar reglas deterministas sin necesitar agentes de IA para cada decisión.

## **Caso D — Caso ambiguo**

Un mensaje legítimo presenta características que parecen sospechosas.

El sistema debe reconocer la incertidumbre, mostrar evidencias y recomendar una verificación, en vez de afirmar que se trata de un fraude.

Este escenario es importante para demostrar que Qhawix no depende de respuestas alarmistas del modelo.

---

# **9\. Definición preliminar del MVP**

La selección final corresponde al equipo. La recomendación es construir un flujo completo y funcional antes de intentar implementar todos los módulos.

## **MVP propuesto: investigación multiagente de fraudes**

### **Incluido**

1. Una interfaz para compartir mensajes, URLs y capturas.  
2. Un agente de clasificación.  
3. Un agente de análisis de URLs.  
4. Un agente de análisis de mensajes.  
5. Un agente de investigación web.  
6. OCR o extracción multimodal de datos de capturas.  
7. Un motor de correlación y evaluación de riesgo.  
8. Una explicación basada en evidencias.  
9. Un registro de incidentes.  
10. Un dashboard con trazas de agentes y métricas.  
11. Un MCP propio de inteligencia o incidentes, si el tiempo lo permite.  
12. Un conjunto de pruebas sintéticas.

### **Opcional si queda tiempo**

* AtomicMemory para recuperación persistente de incidentes.  
* n8n para automatizaciones y notificaciones.  
* TRUSTGRAPH visual.  
* Un prototipo de Guardian con temporizador y SOS.  
* Comparación entre proveedores de búsqueda.  
* Laboratorio adversarial automatizado.

### **Fuera del alcance inicial**

* Bloquear arbitrariamente Yape u otras aplicaciones.  
* Controlar transferencias financieras.  
* Acceder a movimientos privados sin una integración autorizada.  
* Monitorizar indiscriminadamente todas las aplicaciones.  
* Detectar con certeza una agresión física.  
* Prometer detección infalible de deepfakes.  
* Construir todos los módulos a producción durante la hackathon.

---

# **10\. Seguridad y gobernanza**

Qhawix debe incorporar desde el principio:

* Autorización por herramienta y por usuario.  
* Permisos mínimos.  
* Validación de entradas y salidas estructuradas.  
* Protección de credenciales y secretos.  
* Tratamiento de páginas, mensajes y documentos como datos no confiables.  
* Límites de tiempo, coste y llamadas por investigación.  
* Registro de decisiones relevantes.  
* Procedencia de evidencias.  
* Diferenciación entre hechos, reportes e inferencias.  
* Consentimiento explícito para ubicación y compartición de datos.  
* Minimización y retención limitada de datos personales.  
* Acciones críticas sujetas a autorización.  
* Manejo de errores y posibilidad de abstenerse.

El motor de políticas debe estar separado de los agentes. Un resultado de alto riesgo no autoriza por sí mismo a borrar datos, bloquear aplicaciones, contactar a terceros o ejecutar operaciones financieras.

---

# **11\. Métricas para demostrar calidad técnica**

El equipo debería medir:

* Precisión y recall en los escenarios de prueba.  
* Tasa de falsos positivos.  
* Tasa de falsos negativos.  
* Latencia total y latencia por agente.  
* Coste promedio por incidente.  
* Número de llamadas a herramientas.  
* Calidad y trazabilidad de las evidencias.  
* Porcentaje de resultados con incertidumbre correctamente identificada.  
* Robustez ante prompt injection.  
* Porcentaje de workflows completados correctamente.  
* Diferencia de rendimiento frente a un detector base sin coordinación multiagente.

No se debe afirmar que los agentes mejoran la detección sin comparar los resultados experimentales.

---

# **12\. Plan de ejecución sugerido**

## **Fase 1 — Acordar el alcance**

* Definir el problema principal.  
* Elegir el caso de demostración.  
* Establecer qué capacidades serán reales y cuáles simuladas.  
* Confirmar beneficios y límites de los proveedores.

## **Fase 2 — Construir el flujo vertical**

* Crear la API de incidentes.  
* Implementar un caso de análisis.  
* Integrar los agentes esenciales.  
* Mostrar resultados en la interfaz.

## **Fase 3 — Añadir herramientas y memoria**

* Integrar búsqueda web.  
* Conectar fuentes de reputación.  
* Implementar MCP propio si aporta valor.  
* Incorporar memoria de incidentes si el tiempo lo permite.

## **Fase 4 — Endurecer la solución**

* Validar permisos.  
* Probar entradas maliciosas.  
* Controlar costes y latencia.  
* Verificar que el sistema puede abstenerse.

## **Fase 5 — Preparar la demostración**

* Ensayar casos positivos, negativos y ambiguos.  
* Mostrar la investigación de cada agente.  
* Presentar el grafo de evidencias.  
* Mostrar métricas reales.  
* Explicar las limitaciones y el siguiente paso del producto.

---

# **13\. Decisiones pendientes del equipo**

Antes de cerrar el MVP, hay que resolver:

1. ¿El eje principal será la prevención de fraude digital o la seguridad física y digital integrada?  
2. ¿La demostración se realizará en una aplicación Android, un dashboard web o ambos?  
3. ¿Cuántos integrantes trabajarán en backend, agentes, frontend y evaluación?  
4. ¿Cuánto tiempo real queda para construir y presentar?  
5. ¿Qué acceso y límites tienen los créditos de Grok, n8n, Exa, Tavily, Apify, AtomicMemory, Zavu, Qatom y Maritime?  
6. ¿Qué proveedor será el principal y cuál actuará como alternativa?  
7. ¿Qué servidor MCP propio aporta una capacidad diferencial?  
8. ¿Qué funcionalidades serán reales y cuáles serán demostraciones controladas?  
9. ¿Qué datos se almacenarán y durante cuánto tiempo?  
10. ¿Qué métricas utilizarán para demostrar que la arquitectura multiagente aporta valor?

---

# **14\. Síntesis ejecutiva**

Qhawix propone construir una plataforma de seguridad personal, digital y financiera impulsada por agentes de IA. La arquitectura combina análisis multimodal, investigación web, memoria persistente, correlación de evidencias, herramientas MCP y workflows automatizados.

El concepto central es SENTINEL: un sistema que investiga amenazas y coordina respuestas explicables. TRUSTGRAPH permite conectar indicadores e incidentes, Guardian aborda la seguridad física y Shield propone protección adaptativa. PHANTOM y Sentinel Lab añaden líneas de innovación para privacidad bajo presión y evaluación adversarial.

La arquitectura propuesta puede utilizar Grok, n8n, Exa, Tavily, Apify, AtomicMemory y Lovable, además de herramientas MCP propias, PostgreSQL, Python, Spring Boot y Kotlin.

La recomendación para la hackathon es demostrar un flujo multiagente completo de investigación de fraude, con evidencias, memoria, trazabilidad y una respuesta segura. Los módulos físicos, el bloqueo de aplicaciones y las integraciones financieras deben incorporarse según su viabilidad y los permisos disponibles.

**Principio rector de Qhawix:** investigar con inteligencia artificial, decidir mediante políticas verificables y actuar únicamente con autorización.

