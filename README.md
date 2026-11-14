# Turno de Medianoche · 0.4.0

**Turno de Medianoche** (repositorio `midnight-shift`) es un juego de terror y gestión en pixel art: atiendes una tienda de conveniencia durante un turno nocturno de 12 minutos que representa las 22:00–06:00, mientras aparecen criaturas y ocurren eventos ambientales. Está pensado para jugadores de PC que disfrutan experiencias cortas de atmósfera, exploración y gestión ligera.

Prototipo Godot 4.7.2, Compatibility, 640×360. Fases 1 y 2 en desarrollo; no se ha generado APK. Proyecto personal en desarrollo activo; el trabajo pendiente está en [`ROADMAP.md`](ROADMAP.md).

## Jugar

Abrir `project.godot` y pulsar F5. WASD/flechas para caminar, E para interactuar, R para reponer una nevera abierta, Escape para pausar, M para el mapa en la ciudad y F2 para elegir controles. El menú de pausa permite ajustar música y efectos por separado; las preferencias persisten.

El turno dura 12 minutos reales y representa las 22:00–06:00. Desde las 03:20 se reduce la clientela: dejan de llegar visitantes y salen de uno en uno. Hay apariciones a las 04:00, 04:30, 05:00 y 05:30 (la primera tras 9 minutos reales), de aproximadamente 16 segundos. Los clientes restantes huyen. Cerrar el turno anticipadamente omite los eventos posteriores.

Al terminar, sal a la ciudad: atelier en el extremo izquierdo, supermercado, ferretería central y cafetería derecha. E junto a cada puerta entra; E en el mostrador abre servicios y E junto a la salida vuelve a la calle. El mapa muestra cuatro negocios y dos zonas futuras.

## Personalización y ambiente

Hilo y Sombra tiene interior transitable y permite combinar tres peinados, tres prendas, cuatro colores de ropa y cuatro de cabello. Vista previa giratoria y confirmación antes de guardar en `user://appearance.cfg`. Cancelar conserva el aspecto anterior. Los peinados se componen de las hojas existentes, conservando proporciones y cuatro direcciones.

Música original de ambiente oscuro: tres capas estéreo con fundidos según hora y presencia. Composición reproducible en `tools/compose_night_score.py`; no usa samples externos. El murmullo anterior ya no se reproduce. Las criaturas se muestran en pasillos, con sombra y aparición gradual; algunas abren neveras. Son eventos ambientales, sin combate ni persecución.

## Comercio

Caja con productos, cantidades, bruto/neto/total, tarjeta o efectivo y cambio. El cliente espera al norte del mostrador y el empleado cobra desde el sur. Inventario agregado, precio uniforme $4 ($5 con terminal); descuentos e impuestos 0. E en estantes muestra vista frontal y precios. Abrir neveras conserva los productos del fondo.

Almacenamiento ($40): capacidad 24→40. Terminal ($60): precio $4→$5. Disuasión ($80): probabilidad de hurto 23%→10%. Reposición $8 por cuatro unidades. Dinero, noche, stock, mejoras y ubicación al cierre persisten; no se recupera un turno a mitad.

## Validación y límites

Pruebas en `tools/test_flow.gd`, `test_events.gd`, `test_city.gd`, `test_crowd_interiors.gd`, `test_crowd_soak.gd`, `test_commerce_ui.gd`, `test_spatial_events_ui.gd` y `test_night_atelier.gd`. La última cubre colisión física de paredes, lado de cobro, retirada gradual, huida, horario y duración de apariciones, mezcla/silencio musical, entrada al atelier, personalización persistente y salida. Cada prueba comercial usa un guardado separado. `capture_night_atelier.gd` produce capturas reales en `docs/new-*.png`.

Arte original generado con image_gen y preparado con Pillow. Tienda y ciudad prerenderizadas, muebles ordenados por profundidad; siete apariencias de clientes con cuatro direcciones. Puede haber solapamiento breve entre NPC. Pendientes (detalle en [`ROADMAP.md`](ROADMAP.md)): tiles modulares, separación local entre NPC, inventario por producto, vigilancia interactiva y pruebas Android.

Fuentes: Atkinson Hyperlegible y Pixelify Sans, de Google Fonts; licencias OFL incluidas en `assets/fonts`.

## Licencia

Publicado bajo licencia MIT; consulta [`LICENSE`](LICENSE). Las fuentes se distribuyen bajo SIL Open Font License (OFL), con sus textos en `assets/fonts`.

Actualización de comportamiento: HUD separa Neveras/Estantes. E sujeta perros y recupera mercancía; camina a la entrada para sacarlos. H junto al mostrador anima el escondite; Shift corre. Los civiles buscan refugio si hay peligro y la puerta está cerrada. La patrulla revisa sin detenidos si no hay sospechosos y escolta a los capturados delante del agente. Fantasmas pueden abrir neveras: revisa sus indicadores de estado.

Animaciones: agente, tres monstruos, variantes de clientes y perro tienen ciclos completos en cuatro direcciones. El perseguidor gruñe y grita cerca; la criatura con astas lanza alaridos y el fantasma azul solloza. Son efectos sintetizados originales. Pausa detiene marcha y vocalización. Preparación reproducible: tools/prepare_walk_cycles.py y tools/compose_creature_voices.py.
