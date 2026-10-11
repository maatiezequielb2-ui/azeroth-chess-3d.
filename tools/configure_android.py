"""Configure Godot's editor paths without storing credentials in the repository."""
import os
from pathlib import Path
import re
import json

sdk = os.environ.get("ANDROID_HOME") or os.environ.get("ANDROID_SDK_ROOT")
if not sdk or not Path(sdk).is_dir():
    raise SystemExit("Missing Android SDK: set ANDROID_HOME to the installed SDK.")
java = os.environ.get("JAVA_HOME")
if not java or not Path(java).is_dir():
    raise SystemExit("Missing JDK: set JAVA_HOME to JDK 21.")
config = Path(os.environ.get("XDG_CONFIG_HOME", str(Path.home() / ".config"))) / "godot"
settings = config / "editor_settings-4.6.tres"
if not settings.exists():
    raise SystemExit("First run: godot --headless --editor --import --quit")
text = settings.read_text()
values = {
    "export/android/android_sdk_path": sdk,
    "export/android/java_sdk_path": java,
    "export/android/debug_keystore": os.environ.get("GODOT_ANDROID_KEYSTORE_DEBUG_PATH", ""),
    "export/android/debug_keystore_user": "androiddebugkey",
    "export/android/debug_keystore_pass": "android",
}
for key, value in values.items():
    line = f"{key} = {json.dumps(value)}"
    expression = re.compile(r"^" + re.escape(key) + r" = .*?$", re.M)
    if expression.search(text):
        text = expression.sub(lambda _: line, text)
    else:
        text += "\n" + line + "\n"
settings.write_text(text)
print("Godot Android SDK and JDK paths configured.")
