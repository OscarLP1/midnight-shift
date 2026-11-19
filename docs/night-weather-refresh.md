# Mostrador, interfaz y exterior nocturno

Implementación: recorte del mostrador mediante shader para eliminar el suelo rectangular superpuesto; interfaz única Nocturno, controles superiores agrupados y mensajes inferiores; selección de estilos y F2 retirados.

El shader del fondo conserva el interior original. Sustituye únicamente el pavimento frontal y los márgenes laterales por arte nocturno seco. Las aceras son decorativas: no amplían el área transitable del supermercado.

Lluvia: tres velocidades/profundidades, salpicaduras y transición gradual. Nieve: deriva lateral, tres tamaños/profundidades y depósitos en los bordes. Efectos limitados al exterior del supermercado y visibles en ciudad. Audio ambiental sigue las transiciones y se amortigua más al cerrar la puerta.

Arte: herramienta integrada image_gen, edición de store-modern.png. Fuentes guardadas en assets/art_direction/store-dry-night-source.png y store-night-sidewalks-source.png. La segunda es la utilizada en ejecución.

Instrucciones de generación: conservar exactamente interior, objetos, escala, perspectiva e iluminación; reemplazar sólo exterior húmedo por pavimento mate azul gris seco de noche, sin lluvia, nieve, charcos, personas ni interfaz. Segunda edición: añadir aceras únicamente en los márgenes exteriores del 3,3 % a cada lado, conectadas con el pavimento frontal, con bordillos, desagües pequeños y hierbas junto a las paredes; mantener todo el edificio y su tamaño.

Verificación: tools/test_weather_ui.gd comprueba materiales, estilo único, transiciones y máscaras por ubicación; produce docs/weather-ui-0.png a weather-ui-2.png al ejecutarse con renderer gráfico. tools/test_flow.gd valida llegada a caja, venta, prevención de doble cobro, pausa, cierre y guardado. Ambas pruebas pasaron en Godot 4.7.2.
