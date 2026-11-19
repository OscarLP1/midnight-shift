# Exterior en una sola toma

Decisión del usuario: descartar las calles panorámicas con desplazamiento de cámara y restaurar el tamaño anterior de los interiores.

- Escenarios de ciudad: 640×360 unidades, cámara fija. La franja inferior de mensajes ocupa 48 unidades adicionales fuera del escenario; la patrulla sigue visible.
- Cafetería, ferretería y atelier: fondos completos de 640×360, personaje a escala 1.6, igual que antes de la reducción rechazada.
- Nuevos fondos: `assets/courtyard-avenue.png` y `assets/courtyard-modistas.png`, creados con image_gen integrado. Las versiones panorámicas no se usan.
- Avenida: supermercado bajo de tonos crema y nogal, con su interior visible; ferretería ocre y cafetería azul verdosa. Modistas: lavandería, atelier y taller de muebles con arquitectura diferente y pavimento conectado.
- Las puertas y las rutas se configuran en `scripts/district_layout.gd`; entrada, salida y mapa del barrio deben usar esos datos.

Prompt de dirección aplicado a Avenida: nueva escena exterior en 16:9, una sola cámara fija, local de una planta basado en materiales y colores de store-modern.png; supermercado dominante, ferretería y café pequeños; umbrales en torno a y237, acera despejada hasta y290 y calle frontal; noche seca sin lluvia, nieve, personas ni interfaz pintadas. Mantener visibles todos los edificios y tejados, sin panoramas estirados.

Prompt de dirección aplicado a Modistas: usar la nueva Avenida como referencia exacta de cámara, noche, pavimento, escala e iluminación; cambiar composición, dimensiones y negocios por lavandería, atelier con espejos/ropa y taller de muebles de tejado bajo; entrada del atelier cerca del centro; conservar acera y bordillo alineados; sin efectos climáticos permanentes.

Validación: `tools/test_district_scale.gd` verifica acceso a los cuatro negocios, servicios de los tres interiores, escala restaurada, vuelta a sus puertas, enlaces entre calles, mapa y regreso al supermercado. Capturas gráficas bajo `docs/district-*.png`. `tools/capture_patrol_footer.gd` verifica que la franja de mensajes empieza debajo del escenario.
