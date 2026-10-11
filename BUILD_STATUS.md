# Estado verificable de la entrega

Verificado el 11 de octubre de 2026.

## Implementado y probado localmente

- Proyecto Godot 4.6.3 completo, escena 3D y 12 modelos originales por facción.
- Ajedrez, 20 dificultades nominales, controles táctiles, sonidos y animaciones.
- Guardado y restauración, deshacer, selección de bando, efectos opcionales.
- Exportación Android configurada para ARM64/ARMv7, Android 8 o superior.
- Workflow .github/workflows/android.yml para compilar, firmar y verificar APK.
- tests/test_chess.gd: cero fallos.
- tests/test_game.gd: cero fallos.

Los modelos tienen diseño low poly original. La semejanza artística no ha sido
evaluada mediante captura visual en este entorno headless. El rendimiento en
un teléfono todavía no está medido.

## APK: no generado en este entorno

Se ejecutó:

```sh
godot --headless --path . --export-debug Android build/Azeroth-Chess-3D.apk
```

Godot rechaza la exportación porque no están instaladas las plantillas:

- godot/export_templates/4.6.3.stable/android_debug.apk
- godot/export_templates/4.6.3.stable/android_release.apk

Tampoco hay SDK Android con platform-tools/adb y build-tools/apksigner.
Java 21 sí está instalado. Las descargas por curl/git fallan al intentar
conectar al proxy de salida (curl error 7). Los intentos de solicitar acceso
de red adicional fueron cancelados; no se descargaron estos componentes.

## Publicación y compilación GitHub Actions: pendientes

El repositorio real encontrado es:
https://github.com/maatiezequielb2-ui/azeroth-chess-3d.

El punto final forma parte del nombre. Está público y vacío, y pertenece a
maatiezequielb2-ui. La conexión Matias puede leerlo, pero intentar crear README.md
devolvió HTTP 403, Resource not accessible by integration. La consulta de
instalaciones administrables devuelve una lista vacía.

Por eso no se ha subido el proyecto ni se ha ejecutado GitHub Actions. No se
modificó ningún repositorio remoto ni se creó otro.

## Cómo desbloquear

Autorizar la integración de GitHub de ChatGPT para escribir en ese repositorio
con la cuenta maatiezequielb2-ui. Una vez autorizado, se puede publicar el
proyecto completo y el push dispara Android APK. Alternativa: subir manualmente
los archivos extraídos de la copia ZIP al mismo repositorio, incluyendo
.github/workflows/android.yml; Actions entrega el APK en el artifact
Azeroth-Chess-3D-Android después de una ejecución exitosa.

Esta entrega incluye código y evidencia de los bloqueos, pero todavía no
incluye un APK instalable. No es correcto afirmar que la compilación Android
pasó hasta ejecutar y revisar el workflow o instalar las dependencias locales.
