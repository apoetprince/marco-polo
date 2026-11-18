# Marco Polo · Teatro UX iPhone · v0.1
Fecha de preparación: 2026-11-18
Estado: protocolo de pruebas preparado; entorno web en iPhone **todavía no desplegado**
Dispositivo principal: iPhone 14 Pro Max (430 × 932 puntos lógicos; comprobar orientación real).

## Propósito
Disponer de un laboratorio de experiencia de usuario en el dispositivo físico, para recorrer el canon visual ya aprobado de Marco Polo y registrar, mediante capturas, anotaciones y grabaciones, qué sucede, qué debería suceder y en qué contexto. Es el paso previo a la envoltura nativa con Capacitor, TestFlight y App Store. Podrá servir a otros productos sin mezclar su identidad visual.

## Límites no negociables
- No rediseñar ni reinterpretar la jerarquía/estética canon. Referencias visuales aprobadas, especialmente mobile V0.3 y el shell persistente de entrada.
- Conservar `preview.html` como referencia/product preview; adaptar React/Supabase funcional en una rama separada, sin tocar `main`.
- No mezclar mockups con funcionalidades completas. Etiquetar cada estado: MOCK, PARCIAL, FUNCIONAL, BLOQUEADO.
- No usar datos personales, veterinarios o de terceros reales en la galería compartida o en pruebas públicas.
- NFC/QR debe resolver a enlaces públicos seguros; los permisos de perfil privado quedan separados de la visita pública.
- Sin nueva UX paralela. El teatro presenta los mismos estados del producto.

## Arquitectura del teatro
1. **Escena:** staging privado por HTTPS de la app actual, accesible desde Safari iPhone y «Agregar a pantalla de inicio». URL y despliegue pendientes.
2. **Bastidores:** panel de selección de `SCREEN/STATE_ID`, casos de uso, modo de prueba, datos ficticios y estado de implementación. Debe poder ocultarse para capturas limpias.
3. **Guion:** recorridos de prueba de tutor, mascota, visita NFC/QR, contacto público, cuidador/veterinario y pérdida de conexión.
4. **Bitácora:** cada evidencia enlaza screenshot/grabación, estado actual, comportamiento observado, expectativa y decisión/aprobación.
5. **Sala de otros productos:** un índice de proyectos aislados; no compartir componentes visuales por defecto.

## Inventario inicial de escenas, sujeto a auditoría
- MP-ENTRY: splash → home/entry persistente.
- MP-ID: identificación raíz DMT → tutor → asociaciones de mascotas.
- MP-TAG: tutor tag, pet tag, care tag; QR/link público y activación.
- MP-PUBLIC: perfil público seguro, `Avisar a mi humano`, visitante no autorizado.
- MP-PRIVATE: perfil de mascota, panel personal, vínculos y permisos.
- MP-CARE: salud, nutrición, cuidado; diario e historial.
- MP-LOST: modo perdido, aviso y contactos autorizados.
- MP-CONTEXT: estados vacíos, permiso denegado, éxito, error, sin conexión.
- MP-VOICE: Up2Talk / futuras integraciones, marcar claramente los placeholders.

## Protocolo de captura
En el iPhone 14 Pro Max:
1. Abrir escena por Safari o acceso de pantalla de inicio.
2. Recorrer una tarea completa, con y sin conexión cuando sea pertinente.
3. Tomar captura con botón lateral + volumen arriba.
4. Abrir miniatura y anotar con Marcación: flechas, círculos y comentario breve.
5. Usar grabación de pantalla para transiciones y reacciones que no se entienden con una imagen.
6. Registrar `SHOT_ID`, `PRODUCT`, `SCREEN/STATE_ID`, `ROUTE`, `COMPONENT`, `DEVICE`, `ORIENTATION`, `SOURCE`, `STATUS`, `OBSERVED`, `EXPECTED`, `CONTEXT`, `DECISION`, `PRIORITY`.

Nombre de evidencia: `MP_YYYYMMDD_STATEID_XX.png`.
Las capturas con información privada deben permanecer en un repositorio privado o almacenamiento restringido, no en el repositorio público.

## Formato breve de observación
```yaml
shot_id: MP_20261118_MP-ENTRY_01
product: marco-polo
screen_state_id: MP-ENTRY
route: /
component: por_auditar
device: iPhone 14 Pro Max
orientation: portrait
source: canon_v0.3 | preview_html | react
status: mock | parcial | funcional | bloqueado
observed: ...
expected: ...
trigger: tap | scan | input | network | permission
context: tutor | visitante | veterinario | cuidador
reaction: visual | haptic | notification | transition | error
decision: proposed | approved | rejected
priority: P0 | P1 | P2
evidence: ruta_privada_a_imagen
```

## Aprobación de una reacción UX
Una reacción se implementa solo cuando están definidos: disparador, condición/contexto, respuesta visible/audible/háptica, fallo y recuperación, visibilidad por rol, y evidencia de aprobación. Evitar funciones adicionales que alteren el canon.

## Próximos hitos
- [ ] Auditar `preview.html`, React y assets contra el canon aprobado, pantalla por pantalla.
- [ ] Preparar URL HTTPS de staging y datos ficticios de prueba, con acceso restringido.
- [ ] Implementar selector de estados en modo desarrollo sin afectar el producto.
- [ ] Abrirlo en iPhone y validar safe areas, touch targets, scroll y orientación.
- [ ] Generar primeras capturas con anotaciones y tabla de decisiones.
- [ ] Corregir P0/P1, entonces integrar Capacitor/TestFlight.
- [ ] Reutilizar el protocolo con un índice para otros productos, no sus pantallas.
