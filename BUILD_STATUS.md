# Estado verificable de la entrega

Verificado el 11 de octubre de 2026.

Proyecto publicado exclusivamente en https://github.com/maatiezequielb2-ui/azeroth-chess-3d.

## APK generado y verificado

GitHub Actions terminó correctamente:
https://github.com/maatiezequielb2-ui/azeroth-chess-3d./actions/runs/38105652910

Commit compilado: 7d826fba2bf842a939edf12dfd89d9a2b5617d00.
Artifact Azeroth-Chess-3D-Android: contiene Azeroth-Chess-3D.apk y SHA256SUMS.txt.
https://github.com/maatiezequielb2-ui/azeroth-chess-3d./actions/runs/38105652910/artifacts/11690355207
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
