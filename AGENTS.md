# Turno de Medianoche — reglas del proyecto

Aplican a todo este repositorio. Mantener este archivo actualizado con las decisiones explícitas del usuario; no convertir propuestas del agente en preferencias aprobadas.

## Dirección visual aprobada
- Continuar la versión 2D en Godot. El proyecto 3D es independiente.
- Pixel art moderno, detallado y coherente. Usar al protagonista como base de proporciones para clientes, ladrones y policías; permitir atuendos, sexo y cabello variados.
- Movimiento natural con frente, espalda y ambos perfiles; animar piernas y brazos según desplazamiento real. Monstruos y perros también deben moverse, no deslizarse como imágenes.
- Cada calle debe verse completa en una sola toma. No introducir panoramas con cámara que persigue al personaje para resolver la escala.
- Diseñar el exterior del supermercado a partir de su interior: materiales, colores, luz, tamaño aparente y puertas coherentes.
- Los mapas conectados comparten perspectiva, escala, pavimento, clima y paleta, pero tienen negocios y composiciones diferentes; no duplicar el escenario cambiando sólo un letrero.
- Conservar el tamaño original de los interiores de cafetería, ferretería y atelier: fondo de 640×360 y personaje a escala 1.6. El usuario rechazó encogerlos para igualarlos a las fachadas.
- La noche base debe ser seca. Lluvia y nieve son efectos animados con audio, no marcas permanentes en el fondo; sólo caen fuera de los locales.

## Interfaz y visibilidad
- Centrar todos los menús según su tamaño y el viewport, incluso si se redimensiona.
- Una sola interfaz coherente. El usuario aprobó el estilo Nocturno con controles compactos e iconos.
- No volver a añadir un selector de tres diseños ni un botón permanente de interactuar. Mantener Comandos en el menú.
- Los avisos inferiores deben ocupar su propia franja fuera del escenario. Nunca tapar la patrulla, ruedas, entrada o personajes con la interfaz.
- Seguridad abre sin pausar el juego; pausa sí lo detiene. Métodos de pago elegidos por el cliente.
- El probador mantiene al mismo cuerpo y sus animaciones; incluir selector hombre/mujer y seis conjuntos de peinado/ropa.
- Texto sobre personajes legible, blanco con borde oscuro. Evitar etiquetas innecesarias de neveras abiertas/cerradas y "A salvo, esperando".
- Recortar props por su silueta y ordenar profundidad por los pies: no permitir rectángulos de suelo superpuestos sobre personajes.

## Mecánicas que no deben retroceder
- Stock separado por estantes y neveras, productos adecuados a su zona; sin mercancía no hay venta.
- Neveras independientes; la mercancía sólo se daña tras tres horas de puerta abierta. Cerrar reinicia el contador.
- Ladrones no pagan, roban entre 1 y 5 unidades, salen de verdad o buscan escapar si la puerta está cerrada. Primera noche: objetivo de 2 a 4, sujeto a acceso y duración.
- Policía aparece después de que la patrulla se detenga, persigue al ladrón y lo escolta cerca, detenido delante; abre y vuelve a cerrar la puerta. Informar detenciones sólo si ocurrieron.
- Perros más lentos, conducta variable, patas animadas; pueden correr, robar o ensuciar y el jugador puede atraparlos y sacarlos.
- Terror en las dos últimas horas; clientes se retiran o huyen. Música cambia por situación; sustos, voces y efectos deben encajar con el tono del juego.

## Forma de trabajar
- Hablar en español, implementar y verificar, con actualizaciones breves. Avanzar proactivamente dentro del pedido.
- No alterar decisiones visuales aprobadas para resolver otro problema. Conservar originales y comprobar el resultado en capturas reales de Godot.
- Al cambiar mapas, revisar juntos arte, colisiones, entradas/salidas, cámara, clima, mapa del barrio y controles táctiles.
- Guardar GDScript en UTF-8 y respetar la indentación existente. Ejecutar las pruebas pertinentes; no afirmar que algo se probó si sólo se inspeccionó.
- No borrar cambios ajenos ni subir archivos temporales o logs indiscriminadamente. Informar con precisión qué está local y qué se publicó.
