# Estado verificable de la entrega

Verificado el 11 de octubre de 2026.

Proyecto publicado exclusivamente en https://github.com/maatiezequielb2-ui/azeroth-chess-3d.

## APK generado y verificado

GitHub Actions terminó correctamente:
https://github.com/maatiezequielb2-ui/azeroth-chess-3d./actions/runs/38106207826

Commit compilado: e857a9c46456fb7808cdbe912998c5594fba05d2.
Artifact Azeroth-Chess-3D-Android: contiene Azeroth-Chess-3D.apk y SHA256SUMS.txt.
https://github.com/maatiezequielb2-ui/azeroth-chess-3d./actions/runs/38106207826/artifacts/11690371036
Disponible hasta el 10 de noviembre de 2026.

- Pruebas de reglas y de integración: ambas con cero fallos.
- Firma APK verificada con apksigner: esquemas v2 y v3.
- Paquete com.azerothchess.game, versión 1.0.0 (código 1).
- Android mínimo API 24 (Android 7.0), objetivo API 36.
- Arquitecturas ARM64 y ARMv7.
- Firma de desarrollo generada por ejecución; no es una entrega firmada para tienda.

## Correcciones para compilar

La configuración de Android instala platform-tools sin el paquete obsoleto tools.
La exportación directa usa los valores SDK de las plantillas oficiales Godot 4.6.3.
Se habilitó la importación de texturas ETC2/ASTC requerida para exportar a Android.

La calidad visual, los FPS y la instalación en un teléfono real no se verificaron en este entorno.

## Pantalla vertical y horizontal

Rotación automática habilitada. Interfaz con tres columnas en vertical y cuatro en horizontal, botones de 64 unidades y cámara que encuadra tablero y figuras fuera de los paneles. Pruebas de límites de controles y proyección a 540x960, 960x540, 720x1280 y 1280x720, con cámara a 0, 45 y 180 grados: cero fallos. GitHub Actions volvió a compilar y verificar el APK correctamente.

Los modelos de personajes del APK siguen siendo los procedurales originales. Los candidatos externos encontrados todavía no se descargaron ni integraron.
