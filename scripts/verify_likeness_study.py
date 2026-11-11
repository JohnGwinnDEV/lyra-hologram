"""Verify the saved isolated study, rather than the builder's in-memory state."""
import bpy, json, hashlib, struct
from pathlib import Path
root=Path(__file__).resolve().parents[1]; out=root/'.tools/studies/likeness'
bpy.ops.wm.open_mainfile(filepath=str(out/'lyra-face-study.blend'))
body=bpy.data.objects['LyraBody_export']; keys=body.data.shape_keys.key_blocks
base=keys['Basis']; study=[k for k in keys if k.name.startswith('Study_')]
assert len(study)==7
for key in study:
    assert key.value==1
    changed=0
    for a,b in zip(base.data,key.data):
        displacement=(a.co-b.co).length
        assert displacement<.004
        if displacement>1e-7:
            assert (body.matrix_world@a.co).z>1.32, key.name
            changed+=1
    assert changed>0, key.name
for key in ['eyeBlinkLeft','eyeBlinkRight','jawOpen','mouthSmileLeft','mouthSmileRight']:
    assert key in keys
manifest=json.loads((out/'study.json').read_text())
assert hashlib.sha256((root/'avatar/assets/lyra/lyra-base.glb').read_bytes()).hexdigest()==manifest['runtime_model_sha256']
assert hashlib.sha256((out/'reference.png').read_bytes()).hexdigest()==manifest['reference_sha256']
for name in ['baseline-angle.png','study-angle.png','study-front-clay.png']:
    data=(out/name).read_bytes(); assert data[:8]==b'\x89PNG\r\n\x1a\n'
    assert struct.unpack('>II',data[16:24])==(768,960)
assert (out/'baseline-angle.png').read_bytes()!=(out/'study-angle.png').read_bytes()
assert bpy.context.scene.camera.name=='ReferenceAngle'
assert bpy.context.scene.view_layers[0].material_override is None
assert 'Study_MouthCorners' in keys
assert (out/'review.html').is_file()
print('PASS: saved study reloads; seven bounded face controls, original facial morphs, input hashes, matched render dimensions, and review files verified')
