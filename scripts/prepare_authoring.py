"""Verify and unpack approved, already downloaded authoring archives locally."""
from pathlib import Path
import hashlib
import json
import tarfile
import zipfile

ROOT = Path(__file__).resolve().parents[1]
TOOLS = ROOT / ".tools/authoring"
manifest = json.loads((ROOT / "assets/lyra-base-provenance.json").read_text())
for record in manifest["inputs"]:
    archive = ROOT / ".tools/downloads" / record["file"]
    if not archive.is_file():
        raise SystemExit(f"Download the approved archive first: {record['url']} -> {archive}")
    if hashlib.sha256(archive.read_bytes()).hexdigest() != record["sha256"]:
        raise SystemExit(f"Checksum mismatch: {archive}")


def extract_zip(archive, destination):
    with zipfile.ZipFile(archive) as bundle:
        for name in bundle.namelist():
            if Path(name).is_absolute() or ".." in Path(name).parts:
                raise ValueError(f"Unsafe archive path: {name}")
        bundle.extractall(destination)


TOOLS.mkdir(parents=True, exist_ok=True)
if not (TOOLS / "blender-4.5.15-linux-x64/blender").exists():
    with tarfile.open(ROOT / ".tools/downloads/blender-4.5.15-linux-x64.tar.xz") as bundle:
        bundle.extractall(TOOLS, filter="data")
if not (TOOLS / "mpfb2-2.0.18/src/mpfb/blender_manifest.toml").exists():
    extract_zip(ROOT / ".tools/downloads/mpfb-v2.0.18.zip", TOOLS)
data = TOOLS / "user/blender/extensions/.user/lyra_local/mpfb/data"
for filename, pack in (("core-assets-alt.zip", "makehuman_system_assets"), ("faceunits01.zip", "faceunits01")):
    archive = ROOT / ".tools/downloads" / filename
    with zipfile.ZipFile(archive) as bundle:
        metadata = json.loads(bundle.read("packs/" + pack + ".json"))
        if {item["license"] for item in metadata.values()} != {"CC0"}:
            raise SystemExit(f"Unexpected asset license in {filename}")
    if not (data / "packs" / (pack + ".json")).exists():
        extract_zip(archive, data)
print("Verified all four archive hashes; pinned tools and CC0 packs are prepared locally.")
