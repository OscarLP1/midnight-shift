# Android — instalación de prueba

APK: `exports/Turno-de-Medianoche-Android.apk`.

Requiere Android 7.0 o posterior y un teléfono ARM de 32 o 64 bits. Es una compilación de prueba con firma debug, para instalar directamente.

1. Copiar el APK al teléfono por USB o descargarlo desde una ubicación propia.
2. Abrirlo desde Archivos y permitir a esa aplicación instalar aplicaciones si Android lo solicita.
3. Instalar y abrir **Turno de Medianoche**. Jugar en horizontal.

## Controles táctiles

- Mando izquierdo: moverse; llevarlo al borde para correr.
- Botón contextual derecho: abrir/cerrar, cobrar, examinar, reparar o limpiar según dónde estés. Sólo aparece cuando hay una acción cercana. También puedes tocar cerca del personaje.
- Mantener pulsado cerca del personaje frente a una nevera abierta: revisar productos.
- Placa superior: seguridad, policía, puerta del local y escondite. La tienda sigue activa.
- Tocar cerca del personaje escondido: salir del escondite. También puede hacerse desde Seguridad.
- Pausa superior: detener el juego y acceder a las opciones de sonido.
- Atrás de Android: cerrar Seguridad o una vista de productos; pausar/reanudar el juego.
- En móvil, la guía **Controles** explica los gestos; en PC se mantienen **Comandos** y los atajos de teclado.

La interfaz se adapta al área segura de la pantalla y a proporciones panorámicas o de tablet. El escenario conserva su escala y perspectiva, completo en una toma.

## Verificación

Se verifican exportación, firma APK v2/v3, bibliotecas ARM y gestos táctiles en pruebas de Godot. La comprobación en un teléfono físico está pendiente si no hay uno conectado.

Las herramientas, plantillas, firma de prueba y APK quedan en `exports/`, excluido del repositorio. La configuración de exportación está en `export_presets.cfg`.
