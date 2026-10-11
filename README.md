# Azeroth Chess 3D

Ajedrez 3D offline para Android, construido con Godot 4.6.3 y renderizador
Compatibility (OpenGL ES 3). Modelos originales low poly, cámara orbital,
sombras, animación de movimientos y alas, efectos mágicos y sonidos sintetizados.
No utiliza emojis, letras como figuras ni modelos oficiales extraídos de Warcraft.

## Instalar el APK

Cada push a main/master, pull request o ejecución manual de **Android APK**
compila y verifica un APK firmado de desarrollo.

1. Entrar en **Actions → Android APK → última ejecución verde**.
2. Descargar **Azeroth-Chess-3D-Android** en Artifacts y descomprimir el ZIP.
3. Abrir **Azeroth-Chess-3D.apk** en el dispositivo y permitir la instalación
   desde esa aplicación cuando Android lo solicite.

Requiere Android 7.0 o posterior y OpenGL ES 3.0. Incluye ARM64 y ARMv7;
la firma y la integridad del paquete se comprueban con apksigner y SHA256.
El APK de desarrollo usa una clave generada en cada ejecución: para instalar
una compilación de otra ejecución puede hacer falta desinstalar la anterior
(se pierde la partida guardada). Para distribución permanente se necesita una
clave de lanzamiento estable, conservada fuera del repositorio.

## Jugar

- Elegir Alianza (blancas) u Horda (negras) y uno de los 20 niveles 100–2000.
- Tocar una figura y después una casilla iluminada.
- Arrastrar para girar; pellizcar o usar + / − para acercar.
- Deshacer regresa al turno humano anterior.
- La coronación permite dama, torre, alfil o caballo.
- Enroque: mover el rey dos casillas. Captura al paso: tocar la casilla de destino.
- La partida se guarda después de cada movimiento y al pausar Android.
- Sonido y magia se pueden desactivar.

Las dificultades usan búsqueda negamax con poda alfa-beta, profundización
iterativa, búsqueda de capturas, evaluación posicional y errores deliberados
en niveles bajos. Son **ELO nominales aproximados, sin calibración competitiva**.
La IA corre en un hilo separado; cambios de partida descartan resultados antiguos.

| Figura | Alianza | Horda |
|---|---|---|
| Rey | Arthas, armadura y Frostmourne | Thrall, trenzas y Doomhammer |
| Dama | Jaina, túnica y báculo | Sylvanas, capucha, orejas y arco |
| Peón | Soldado humano con escudo | Soldado orco con hacha |
| Caballo | Hipogrifo con pico, astas y plumas | Gárgola con cuernos y alas |
| Alfil | Frostmourne sobre hielo | Gujas de Illidan cruzadas |
| Torre | Fortaleza humana con almenas | Fortaleza orca con pinchos |

## Desarrollo local

Abrir project.godot con Godot 4.6.3 o ejecutar:

```sh
godot --headless --editor --path . --import --quit
godot --headless --path . --script res://tests/test_chess.gd
godot --headless --path . --script res://tests/test_game.gd
godot --path .
```

Exportación Android local: instalar las plantillas oficiales 4.6.3,
JDK 21 y SDK Android (platform-tools, platforms;android-35, build-tools;35.0.0).
Configurar las rutas en Editor Settings → Export → Android o ejecutar
tools/configure_android.py con ANDROID_HOME y JAVA_HOME establecidos.
Generar una clave de desarrollo y exportar:

```sh
mkdir -p build
export GODOT_ANDROID_KEYSTORE_DEBUG_PATH="$PWD/build/debug.keystore"
export GODOT_ANDROID_KEYSTORE_DEBUG_USER=androiddebugkey
export GODOT_ANDROID_KEYSTORE_DEBUG_PASSWORD=android
keytool -genkeypair -keystore "$GODOT_ANDROID_KEYSTORE_DEBUG_PATH" -storepass android -alias androiddebugkey -keypass android -dname "CN=Azeroth Chess Development,O=Azeroth Chess,C=AR" -keyalg RSA -keysize 2048 -validity 10000
python3 tools/configure_android.py
godot --headless --path . --export-debug Android build/Azeroth-Chess-3D.apk
```

## Verificación

Pruebas del motor: perft inicial 20/400/8902; Kiwipete 48/2039/97862;
final con torres y captura al paso 2812; enroque, jaque, mate, ahogado,
captura al paso clavada, cuatro coronaciones, 50 movimientos, triple
repetición, material insuficiente, guardado y movimientos legales en
los 20 niveles. Pruebas de integración: escena 3D, selección, animación,
respuesta de IA, deshacer, coronación, guardado y nueva partida mientras
la IA está trabajando.

Mallas estáticas agrupadas por material, modelos reutilizados con PackedScene,
materiales compartidos, geometría de baja densidad y luces con una sola
fuente de sombras. La calidad visual y los FPS deben verificarse en el
dispositivo real; las pruebas headless no sustituyen esa medición.

Proyecto de fans no afiliado a Blizzard. Los nombres de personajes y Warcraft
pertenecen a sus respectivos titulares; las esculturas y sonidos de este
proyecto son originales.
