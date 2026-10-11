# Azeroth Chess 3D — prototipo de modelos locales

Doce esculturas GLB construidas localmente en Blender, sin descargar modelos. Peones Footman y Grunt con caminar y golpe; colores apagados; interfaz vertical y horizontal.

**Prototipo visual:** las mallas todavía no alcanzan el detalle de la propuesta conceptual aprobada. [Renders reales](design/actual-model-renders.jpg). No son modelos oficiales.

Abrir project.godot con Godot 4.6.3. Regenerar mallas: `blender --background --python tools/build_models.py -- --preview`. El APK de desarrollo se obtiene del artifact Azeroth-Chess-3D-Android del workflow Android APK. Android 7.0 o superior. Los modelos y renders tienen un artifact separado.

Pruebas: `godot --headless --path . --script res://tests/test_chess.gd` y `godot --headless --path . --script res://tests/test_game.gd`.
