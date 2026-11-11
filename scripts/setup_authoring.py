"""Register the pinned, locally downloaded MPFB source in isolated Blender prefs."""
from pathlib import Path
import shutil
import bpy
import addon_utils

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / ".tools/authoring/mpfb2-2.0.18"
REPO = ROOT / ".tools/authoring/extensions/lyra_local"
PACKAGE = "bl_ext.lyra_local.mpfb"

assert bpy.app.version[:2] == (4, 5), bpy.app.version_string
assert (SOURCE / "src/mpfb/blender_manifest.toml").exists()
REPO.mkdir(parents=True, exist_ok=True)
shutil.copytree(SOURCE / "src/mpfb", REPO / "mpfb", dirs_exist_ok=True)
for name in ("LICENSE.md", "LICENSE.ASSETS.md", "LICENSE.CODE.md"):
    shutil.copyfile(SOURCE / name, REPO / "mpfb" / name)
repos = bpy.context.preferences.extensions.repos
if not any(repo.module == "lyra_local" for repo in repos):
    repos.new(name="LYRA Local", module="lyra_local", custom_directory=str(REPO))
addon_utils.enable(PACKAGE, default_set=True, persistent=True)
assert addon_utils.check(PACKAGE)[1], "MPFB did not enable"
bpy.ops.wm.save_userpref()
print("LYRA authoring setup: Blender", bpy.app.version_string, "with", PACKAGE)
