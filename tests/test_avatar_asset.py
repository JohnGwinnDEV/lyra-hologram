"""Validate the actual Blender GLB handoff, independently of the generator."""
import json
from pathlib import Path
import struct
import unittest

ROOT = Path(__file__).resolve().parents[1]
ASSET = ROOT / "avatar/assets/lyra/lyra-base.glb"


class AvatarAssetTests(unittest.TestCase):
    def document(self):
        self.assertTrue(ASSET.is_file(), "Rigged LYRA GLB has not been generated")
        data = ASSET.read_bytes()
        magic, version, length = struct.unpack_from("<4sII", data)
        self.assertEqual((magic, version, length), (b"glTF", 2, len(data)))
        size, kind = struct.unpack_from("<I4s", data, 12)
        self.assertEqual(kind, b"JSON")
        return json.loads(data[20:20 + size])

    def test_body_has_real_skin_weights_and_skeleton(self):
        doc = self.document()
        self.assertTrue(doc.get("skins"), "Export must contain an actual skeleton")
        self.assertGreater(len(doc["skins"][0]["joints"]), 20)
        skinned = [node for node in doc["nodes"] if "skin" in node]
        self.assertTrue(skinned)
        for node in skinned:
            for primitive in doc["meshes"][node["mesh"]]["primitives"]:
                self.assertIn("JOINTS_0", primitive["attributes"])
                self.assertIn("WEIGHTS_0", primitive["attributes"])

    def test_blink_and_jaw_morphs_survive_export(self):
        doc = self.document()
        body = next(mesh for mesh in doc["meshes"] if mesh["name"] == "LyraBody")
        targets = body.get("extras", {}).get("targetNames", [])
        for name in ("eyeBlinkLeft", "eyeBlinkRight", "jawOpen"):
            self.assertIn(name, targets)
            index = targets.index(name)
            for primitive in body["primitives"]:
                accessor = doc["accessors"][primitive["targets"][index]["POSITION"]]
                # A named but empty morph is not a functional face control.
                self.assertNotEqual(accessor.get("min"), accessor.get("max"), name)

    def test_asset_is_self_contained_clothed_and_licensed(self):
        doc = self.document()
        for resource in doc.get("buffers", []) + doc.get("images", []):
            self.assertNotIn("uri", resource, "GLB must not require external files/network")
        self.assertTrue(any("Outfit" in mesh.get("name", "") for mesh in doc["meshes"]))
        for name in ("Lashes", "SilverBlueEyes"):
            material = next(material for material in doc["materials"] if material["name"] == name)
            self.assertIn(material.get("alphaMode"), ("MASK", "BLEND"),
                          name + " must preserve its alpha mask rather than obscure the eyes")
        manifest = json.loads((ROOT / "assets/lyra-base-provenance.json").read_text())
        self.assertEqual(manifest["asset_license"], "CC0-1.0")
        import hashlib
        self.assertEqual(manifest["output_sha256"], hashlib.sha256(ASSET.read_bytes()).hexdigest())

    def test_coat_filaments_and_pendant_are_skinned_runtime_geometry(self):
        doc = self.document()
        for name in ("LyraCoat", "BlueFilaments", "Pendant", "SweptLocks"):
            matches = [index for index, mesh in enumerate(doc["meshes"]) if mesh.get("name") == name]
            self.assertTrue(matches, name + " must be included in the exported model")
            self.assertTrue(any(node.get("mesh") == matches[0] and "skin" in node for node in doc["nodes"]),
                            name + " must follow the character skeleton")
        fiber = next(material for material in doc["materials"] if material["name"] == "FiberBlue")
        self.assertGreater(max(fiber.get("emissiveFactor", [0, 0, 0])), 0,
                           "Hair filaments must retain emission through GLB export")

    def test_eyes_have_independent_gaze_bones(self):
        doc = self.document()
        names = {node.get("name") for node in doc["nodes"]}
        for name in ("eye_l", "eye_r"):
            self.assertIn(name, names, "Eye contact requires real independent eye joints")
        for name in ("EyeLeft", "EyeRight"):
            self.assertTrue(any(mesh.get("name") == name for mesh in doc["meshes"]), name)


if __name__ == "__main__":
    unittest.main()
