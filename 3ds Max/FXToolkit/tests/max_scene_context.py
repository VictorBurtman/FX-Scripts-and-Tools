"""Exercise the actual MAXScript library in Max Batch, with workspace fixtures.

No production/network writes and no clipboard changes. resolve() is pure except
for reading the registry; directory creation is tested only below test-output.
"""
import json
from pathlib import Path
import traceback
import uuid
from pymxs import runtime as rt

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "test-output" / "scene-context"


def main():
    run = OUTPUT / uuid.uuid4().hex
    run.mkdir(parents=True)
    cfg = run / "productions.cfg"
    example = (ROOT / "server/00_Lib/productions.cfg").read_text(encoding="utf-8")
    cfg.write_text(example, encoding="utf-8-sig")
    rt.fileIn(str(ROOT / "server/00_Lib/FXSceneContext.ms"))
    service = rt.FXSceneContext
    checks = []

    def resolve(path, registry=cfg):
        return service.resolve(path, configPath=str(registry))

    def reject(path, phrase, registry=cfg):
        try:
            resolve(path, registry)
        except Exception as error:
            assert phrase.lower() in str(error).lower(), str(error)
        else:
            raise AssertionError("Expected rejection: " + str(path))

    cases = [
        (r"S:\alice2\production\e322\fx\s0780\e322sfx0780.max",
         "Alice2", "max_legacy", "e322", "s0780", r"S:\alice2\production\e322\fx\3D_Sources\s0780"),
        (r"S:\bes2\shots\e203\s5340\fx\wip\3d\3dsmax\e203s5340_fx_v002.max",
         "BES2", "maya_shots", "e203", "s5340", r"S:\bes2\shots\e203\s5340\fx\wip\3d\datas"),
        (r"S:\alice2\production\e313\fx\s0010\e313sfx0010.max",
         "Alice2", "max_legacy", "e313", "s0010", r"S:\alice2\production\e313\fx\3D_Sources\s0010"),
        (r"S:\bes2\shots\e204\s0940\fx\wip\3d\3dsmax\e204s0940_fx_v001.max",
         "BES2", "maya_shots", "e204", "s0940", r"S:\bes2\shots\e204\s0940\fx\wip\3d\datas"),
        (r"s:/ALICE2/production/E313/FX/S0010/e313sfx0010_v003.max",
         "Alice2", "max_legacy", "e313", "s0010", r"S:\alice2\production\e313\fx\3D_Sources\s0010"),
        (r"S:\alice2\production\e313\anim\e313sa0010.max",
         "Alice2", "max_legacy", "e313", "s0010", r"S:\alice2\production\e313\fx\3D_Sources\s0010"),
        (r"S:\bes2\shots\e204\s0940a\fx\wip\3d\3dsmax\e204s0940a_fx_v007.max",
         "BES2", "maya_shots", "e204", "s0940a", r"S:\bes2\shots\e204\s0940a\fx\wip\3d\datas"),
        (r"S:\alice2\production\e313\fx\s0010\arbitrary_scene.max",
         "Alice2", "max_legacy", "e313", "s0010", r"S:\alice2\production\e313\fx\3D_Sources\s0010"),
    ]
    for scene, production, pipeline, episode, shot, cache in cases:
        context = resolve(scene)
        assert tuple(context.asArray()) == (production, pipeline, episode, shot, cache)
        assert context.department == "fx"
        assert context.configPath == str(cfg)
        assert context.scenePath.lower().endswith(".max")
    # The deployed library reads the adjacent registry without a config override.
    default_context = service.resolve(cases[0][0])
    assert default_context.cachePath == cases[0][-1]
    assert default_context.configPath == str(ROOT / "server/00_Lib/productions.cfg")
    checks.append("Max and Maya layouts, case/separators, zero padding, filename fallback, shot suffix, named context fields")

    footage_cases = [
        (cases[0][0], r"S:\alice2_footage\production\e322\rendu-compo\s0780\e322sr0780_FX"),
        (cases[1][0], r"S:\bes2_footage\shots\e203\s5340\fx\wip\fx3d"),
        (cases[1][0].replace("v002.max", "v002_test.max"), r"S:\bes2_footage\shots\e203\s5340\fx\wip\fx3d"),
        (cases[6][0], r"S:\bes2_footage\shots\e204\s0940a\fx\wip\fx3d"),
        (r"S:\bes2\shots\e204\s0810\fx\wip\3d\3dsmax\e204s0810_fx_v002.max",
         r"S:\bes2_footage\shots\e204\s0810\fx\wip\fx3d"),
    ]
    for scene, expected in footage_cases:
        assert service.getFootagesPath(scene, configPath=str(cfg)) == expected
    unversioned = cases[1][0].replace("e203s5340_fx_v002.max", "arbitrary.max")
    assert resolve(unversioned).shot == "s5340", "Footage validation must not break other context consumers"
    assert service.getFootagesPath(unversioned, configPath=str(cfg)) == footage_cases[1][1]
    checks.append("Max footage folders use _FX; Maya copies the fx3d folder regardless of filename version")

    reject("", "Save the scene")
    try:
        service.current(configPath=str(cfg))
    except Exception as error:
        assert "Save the scene" in str(error)
    else:
        raise AssertionError("Unsaved current scene must be rejected")
    reject(r"S:\alice2\production_extra\e313\s0010\test.max", "outside")
    reject(r"S:\unconfigured\production\e313\s0010\test.max", "outside")
    reject(r"S:\alice2\production\not_an_episode\s0010\test.max", "episode")
    reject(r"S:\alice2\production\e313\fx\test.max", "identify the shot")
    reject(r"S:\alice2\production\e313\fx\s0010\e314sfx0010.max", "episode directory disagree")
    reject(r"S:\alice2\production\e313\fx\s0010\e313sfx0020.max", "shot directory disagree")
    reject(r"S:\alice2\production\e313\fx\s0010\s0020\test.max", "Ambiguous")
    reject(r"S:\bes2\shots\e204\fx\e204s0940.max", "Maya shots require")
    reject(r"S:alice2\production\e313\s0010\test.max", "absolute")
    reject(r"S:\alice2\production\e313\s0010\test.txt", ".max")
    reject(r"S:\alice2\production\..\elsewhere\e313\s0010\test.max", "outside")
    checks.append("Missing, ambiguous, mismatched and unrelated scene contexts rejected")

    pointer = run / "pointer.cfg"
    pointer.write_text("source:productions.cfg\n", encoding="utf-8")
    assert resolve(cases[0][0], pointer).production == "Alice2"
    cfg.write_text(example.replace("prod:Alice2|", "prod:AliceRenamed|"), encoding="utf-8")
    assert resolve(cases[0][0], pointer).production == "AliceRenamed"
    cfg.write_text(example + "\nprod:Nested|S:\\alice2\\production\\nested|pipeline=max_legacy\n", encoding="utf-8")
    assert resolve(r"S:\alice2\production\nested\e313\s0010\test.max").production == "Nested"
    unc = run / "unc.cfg"
    unc.write_text("prod:UNC|\\\\server\\share\\shots||pipeline=maya_shots|custom=hello\n", encoding="utf-8")
    context = resolve(r"\\SERVER\share\shots\e204\s0940\test.max", unc)
    assert context.cachePath == r"\\server\share\shots\e204\s0940\fx\wip\3d\datas"
    assert service.getFootagesPath(r"\\server\share\shots\e204\s0940\e204s0940_fx_v009.max", configPath=str(unc)) == r"\\server\share\shots\e204\s0940\fx\wip\fx3d"
    record = list(service.loadProductions(configPath=str(unc)))[0]
    assert record.getOption("custom") == "hello"
    assert record.footageRoot == ""
    assert record.getOption("missing", defaultValue="fallback") == "fallback"
    checks.append("Live registry reload, relative delegation, longest root, UNC and arbitrary production metadata")

    bad = run / "bad.cfg"
    for text, phrase in [
        ("source:bad.cfg\n", "cycle"),
        ("source:missing.cfg\n", "unavailable"),
        ("prod:A|\n", "Missing production"),
        ("prod:\n", "Missing production"),
        ("# no records\n", "No productions"),
        ("source:productions.cfg\n" + example, "either source"),
        (example + "\nprod:Alice2|S:\\different\n", "Duplicate production name"),
        (example + "\nprod:Alias|S:\\alice2\\production\n", "Duplicate production root"),
        ("prod:A|S:\\alice2\\production|pipeline=unsupported\n", "Unsupported"),
    ]:
        bad.write_text(text, encoding="utf-8")
        reject(cases[0][0], phrase, bad)
    checks.append("Invalid registries, duplicate records, missing source and source cycles rejected")

    local_cfg = run / "local.cfg"
    max_root, maya_root = run / "max-production", run / "maya-shots"
    local_cfg.write_text("prod:LocalMax|%s\nprod:LocalMaya|%s|pipeline=maya_shots\n" % (max_root, maya_root), encoding="utf-8")
    (max_root / "e313").mkdir(parents=True)
    (maya_root / "e204/s0940").mkdir(parents=True)
    local_max_scene = str(max_root / "e313/fx/s0010/e313sfx0010.max")
    local_maya_scene = str(maya_root / "e204/s0940/fx/wip/3d/3dsmax/e204s0940_fx_v001.max")
    for scene in (local_max_scene, local_maya_scene):
        context = resolve(scene, local_cfg)
        cache = Path(context.cachePath)
        assert not cache.exists(), "Read-only resolve must not create folders"
        assert service.getCachePath(scene, configPath=str(local_cfg)) == str(cache)
        assert not cache.exists()
        for _ in range(2):
            result = service.getCachePath(scene, configPath=str(local_cfg), create=True)
            assert result == str(cache) and cache.is_dir()
    blocked = resolve(str(max_root / "e999/s0010/test.max"), local_cfg)
    try:
        service.ensureCacheDirectory(blocked)
    except Exception as error:
        assert "Episode folder unavailable" in str(error)
    else:
        raise AssertionError("Must not create a missing episode")
    assert not (max_root / "e999").exists()
    collision_scene = str(max_root / "e313/s0020/test.max")
    collision_cache = Path(resolve(collision_scene, local_cfg).cachePath)
    collision_cache.write_text("file blocks directory creation", encoding="utf-8")
    try:
        service.getCachePath(collision_scene, configPath=str(local_cfg), create=True)
    except Exception:
        pass
    else:
        raise AssertionError("Expected file/directory collision to fail")
    assert collision_cache.is_file()
    checks.append("Read-only resolution; recursive, idempotent creation for both pipelines; missing episode and file collisions rejected")

    # Loading twice is supported for tools that fileIn the shared service on click.
    rt.fileIn(str(ROOT / "server/00_Lib/FXSceneContext.ms"))
    assert rt.FXSceneContext.resolve(cases[0][0], configPath=str(cfg)).shot == "s0780"
    checks.append("Library can be reloaded by independent callers")

    # Execute the real network entry points against a stub library. This checks
    # loading/dispatch without a mounted Q: drive or any clipboard changes.
    stub = run / "entry-point-stub.ms"
    stub.write_text('''global FXSceneContext
global FXPathEntryCalled
struct FXPathEntryStub (
    fn copyCurrentCachePath = (FXPathEntryCalled = "cache"),
    fn copyCurrentFootagesPath = (FXPathEntryCalled = "footages")
)
FXSceneContext = FXPathEntryStub()
''', encoding="utf-8")
    for relative, expected in (("Caches_path/cache_path.ms", "cache"), ("Footages_path/footages_path.ms", "footages")):
        source = ROOT / "server/Scene" / relative
        staged = run / source.name
        code = source.read_text(encoding="utf-8").replace(
            r"Q:\fx\fx_tools\3dsMax\00_Lib\FXSceneContext.ms", str(stub))
        staged.write_text(code, encoding="utf-8")
        rt.fileIn(str(staged))
        assert rt.FXPathEntryCalled == expected
    checks.append("Both network scripts load the shared library and dispatch to the expected entry point")
    return {"passed": True, "max_version": str(rt.maxVersion()), "checks": checks}


OUTPUT.mkdir(parents=True, exist_ok=True)
try:
    result = main()
except Exception:
    result = {"passed": False, "error": traceback.format_exc()}
(OUTPUT / "result.json").write_text(json.dumps(result, indent=2), encoding="utf-8")
print(json.dumps(result, indent=2))
if not result["passed"]:
    raise RuntimeError(result["error"])
