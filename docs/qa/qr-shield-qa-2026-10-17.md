# QHAWIX QA — Escudo QR

**Fecha:** 17-10-2026, America/Bogota | **Rama:** `feature/qr-shield` | **Commit base:** `f83702132ca45a06025e4e6db71103cd91a4ace5`

**Fuente normativa:** `docs/QHAWIX-ESPECIFICACION-MAESTRA.md`, v1.0.0; SHA-256 `9e54e1948289b0282f28decefc20a63d9d42263c5a87ecf8b06755a613af4216` (coincide con la huella del catálogo de la skill).

## Alcance

Revisión de Escudo QR en Fase 4a: **F-07; RF-02 y RF-15–21; RNF-01, RNF-03, RNF-05–08, RNF-10–11; T-13–23; AC-03–07 y AC-10**. El módulo de reputación real, gateway, landing y release no están presentes/configurados en este alcance.

## Correcciones aplicadas

- Una respuesta Web Risk `no_match` válida ya no requiere `providerExpiresAt`: la especificación indica que Lookup no entrega una expiración negativa. La app valida fuente, hora, cobertura y categorías, la conserva localmente como máximo 60 segundos y vence la revisión antes de abrir.
- Una respuesta negativa no se acepta si hay señales locales, cobertura incompleta, hora futura, consulta vencida o metadatos de expiración de proveedor incompatibles. Un `match` solo bloquea como amenaza conocida si tiene categorías y vigencia futura válida.
- Al vencer un `no_match`, la app conserva un estado que exige una nueva comprobación antes de permitir abrir; no basta volver a confirmar la advertencia anterior.
- El estado de pantalla separa la vigencia local de revisión de la vigencia informada por el proveedor; la UI explica el límite de 60 segundos.
- La revisión de pantalla se reinicia al cambiar el QR para volver a ocultar URL y contenido sensible previamente revelados. La confirmación de apertura se invalida si el QR cambia mientras el diálogo está abierto.
- El aviso del inicio refleja si el proveedor de reputación está configurado; la selección de varios QR muestra una vista previa de URL con secretos reconocibles redactados.
- Las vistas de cámara, error y ruta no encontrada se pueden desplazar en ventanas bajas o con texto ampliado; el marco de escaneo tiene etiqueta y ayuda semánticas. Los botones de decisión alcanzan el objetivo mínimo de 48 dp de §25, los diálogos permiten desplazamiento y la entrada manual acepta contenido multilínea.
- El escape de texto cubre más controles de formato invisibles (incluidos controles bidireccionales y caracteres de ancho cero). El inspector rechaza etiquetas Punycode malformadas en lugar de tratarlas como hosts válidos.
- Se reforzó la decisión de apertura para no reutilizar un resultado negativo si la URL reanalizada presenta señales.
- Se añadieron pruebas de widget para el aviso de proveedor, la vista previa redactada de candidatos, el reinicio de revelaciones sensibles y el descarte de confirmaciones asociadas a un QR reemplazado. También hay pruebas unitarias y de integración Android para límites/formatos QR, URLs y secretos, resultados de reputación, vencimiento y reconsulta obligatoria, consentimiento, respuestas tardías, selección/deduplicación de candidatos, lectura desde imagen y entrada manual sin activar la cámara.

## Evidencia y límites

- `git diff --check -- ui/analysis_options.yaml ui/android ui/lib ui/pubspec.yaml ui/pubspec.lock ui/test`: terminó con código 0 para las rutas rastreadas; Git no incluye archivos no rastreados en ese diff. Solo notificó conversiones LF/CRLF.
- En la comprobación general actual, `git diff --check` termina con código 1 por tres espacios finales preexistentes en el archivo modificado `docs/ideas-globales-qhawix.md` (líneas 3, 4 y 39); se dejó intacto por estar fuera de este arreglo. Los dos archivos Dart de este cambio no tienen espacios finales.
- Búsqueda de dependencias: el Domain no importa Flutter, cámara, HTTP, launcher ni Data; ViewModel no importa Data; Data no importa ViewModel.
- Búsqueda de espacios al final en los archivos Dart del módulo y las pruebas: sin coincidencias.
- Para los cambios de vistas, comprobación de espacios al final en los Dart de `ui/lib/features/qr_shield/view`, `ui/lib/app/qr_shield_router.dart` y `ui/test/features/qr_shield/view/qr_shield_views_test.dart`: sin coincidencias.
- `dart format --output=none --set-exit-if-changed lib/features/qr_shield/view lib/app/qr_shield_router.dart test/features/qr_shield/view/qr_shield_views_test.dart`: **BLOCKED**, `dart` no se reconoce.
- `flutter analyze lib/features/qr_shield/view lib/app/qr_shield_router.dart test/features/qr_shield/view/qr_shield_views_test.dart` y `flutter test test/features/qr_shield/view/qr_shield_views_test.dart`: **BLOCKED**, `flutter` no se reconoce. Las pruebas añadidas no se declaran aprobadas.
- Verificación de contrato, autopruebas de herramientas y auditoría automatizada de evidencia: **BLOCKED**, el alias `python.exe` de WindowsApps no se pudo iniciar. La comprobación manual de SHA-256 del maestro coincide con el catálogo.
- No hay evidencia de dispositivo/emulador Android, verificación física de permiso/ciclo de cámara, tráfico de gateway ni proveedor configurado. Por tanto, no se afirma que T-13–23 hayan pasado.

El estado completo de cada T-01–T-28 y AC-01–AC-12 está en [`qr-shield-qa-evidence.json`](qr-shield-qa-evidence.json). Resumen: **T: 0 PASS, 0 FAIL, 12 BLOCKED, 16 NOT_RUN; AC: 0 PASS, 0 FAIL, 12 BLOCKED**.

## Recomendación

**NO APTO PARA PILOTO.** La corrección local de Fase 4a está implementada, pero la suite Flutter no pudo ejecutarse y faltan integración autorizada de reputación, validación Android y evidencia de las demás compuertas. Próximo paso: disponer de Flutter/Dart y un emulador o dispositivo Android, ejecutar formato/análisis/pruebas y completar T-13–23; después, validar F4b con un proveedor real autorizado y sus pruebas de gateway.
