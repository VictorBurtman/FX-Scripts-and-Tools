FX SCENE CONTEXT - shared MAXScript library (target: 3ds Max 2022)

DEPLOYMENT
Copy this 00_Lib folder to Q:\fx\fx_tools\3dsMax\00_Lib\.
FXSceneContext.ms and productions.cfg must be alongside each other.
No Python package, local installation, or admin rights are required by the
library. The Toolkit's Caches Path macro loads it from Q: on each click.
Keep your customized productions.cfg when deploying subsequent updates.

PRODUCTION REGISTRY
productions.cfg is the active registry and contains production records directly:
  prod:Alice2|S:\alice2\production|S:\alice2_footage\production
  prod:BES2|S:\bes2\shots|S:\bes2_footage\shots|pipeline=maya_shots

Use UTF-8 (with or without BOM). Blank lines and # comments are ignored.
Format: prod:Name|SceneRoot[|FootageRoot][|key=value...]
SceneRoot is required; FootageRoot is optional. Paths must be absolute drive
or UNC paths. Options may be interspersed with positional paths. No pipeline
option means max_legacy; pipeline=maya_shots selects the Maya layout.
Additional key=value specs are preserved in options for other tools.
Other PrepFX setting lines are ignored. Duplicate names/roots/options fail.
Use either prod: records or one source: directive, never both. A source can
also be relative to the CFG. Missing files and source cycles are errors;
there is no automatic fallback to PrepFX's configuration.

Changes are read on the next lookup; nothing is cached between calls.
There is no separate example CFG to deploy.
PrepFX has not been changed: keep its existing prepFX.cfg until its loader
is migrated separately to this shared productions.cfg. During that transition,
changes needed by both tools must be applied to both registries.

DETECTION AND CACHE LAYOUTS
The configured scene root determines the production, not its display name.
Matching is case-insensitive, accepts / or \, respects directory boundaries,
and selects the longest matching root. Episode names are e followed by digits;
shot names are s followed by digits, optionally with an alphanumeric suffix.
Leading zeroes are retained; the returned episode and shot use lower case.

Max: <root>\<episode>\...\<shot>\scene.max
  Cache: <root>\<episode>\fx\3D_Sources\<shot>
  Example scene: S:\alice2\production\e322\fx\s0780\e322sfx0780.max
  Result: S:\alice2\production\e322\fx\3D_Sources\s0780
  When no shot folder exists, a recognized scene filename can provide it:
  e322sfx0780, e322sa0780, e322sl0780, e322sr0780, or e322s0780.

Maya: <root>\<episode>\<shot>\...\scene.max
  Cache: <root>\<episode>\<shot>\fx\wip\3d\datas
  Example scene: S:\bes2\shots\e203\s5340\fx\wip\3d\3dsmax\e203s5340_fx_v002.max
  Result: S:\bes2\shots\e203\s5340\fx\wip\3d\datas

Recognized filenames must agree with the folders. Ambiguous shots, unknown
productions/pipelines, unsaved scenes, and unsupported layouts raise errors.
An arbitrary filename is fine when episode and shot folders identify it.
Resolution does not require the scene file to exist and creates no folders.
Creation requires an existing production root and episode (and Maya shot).
It creates missing cache directories recursively, including 3D_Sources and
the Max cache shot folder. Repeating the operation preserves existing data.
Unavailable shares, permissions and file/directory conflicts raise errors.
Clipboard copying happens only after directory creation succeeds.

MAXSCRIPT API
  fileIn @"Q:\fx\fx_tools\3dsMax\00_Lib\FXSceneContext.ms"
  ctx = FXSceneContext.current()
  format "% / % / %\n" ctx.production ctx.episode ctx.shot
  cache = ctx.cachePath

Context fields:
  production, productionRoot, footageRoot, pipeline, episode, shot,
  department (always "fx"), scenePath, cachePath, configPath, options.
configPath identifies the final CFG read after source: delegation.
ctx.asArray() returns #(production, pipeline, episode, shot, cachePath).
options is an array of #(key, value) pairs.

Functions (configPath: is optional; defaults to this library's productions.cfg):
  FXSceneContext.current configPath:@"C:\test\productions.cfg"
  FXSceneContext.resolve @"S:\alice2\production\e322\fx\s0780\e322sfx0780.max"
  FXSceneContext.loadProductions()
  FXSceneContext.getCachePath fullScenePath                 -- read only
  FXSceneContext.getCachePath fullScenePath create:true     -- create folders
  FXSceneContext.ensureCacheDirectory ctx                  -- create folders
  FXSceneContext.copyCachePath fullScenePath                -- create + copy
  FXSceneContext.copyCurrentCachePath()                     -- create + copy

loadProductions() returns records with name, root, footageRoot, pipeline,
options, and a getOption key defaultValue:undefined method.
Callers should catch exceptions and display/report them in their own UI.
Loading the library itself has no directory or clipboard side effects.

PYTHON IN 3DS MAX (same library, no duplicate parsing)
  from pymxs import runtime as rt
  rt.fileIn(r"Q:\fx\fx_tools\3dsMax\00_Lib\FXSceneContext.ms")
  ctx = rt.FXSceneContext.current()
  print(ctx.production, ctx.episode, ctx.shot, ctx.cachePath)
  values = list(ctx.asArray())
  cache = rt.FXSceneContext.getCachePath(str(scene_path), create=True)

MAINTENANCE
Add productions or metadata in the active CFG; no MZP rebuild is needed.
New pipeline layouts require a library change (resolve/buildCachePath and
creation checks) and matching tests. Keep field names stable for callers.
The toolkit repository includes tests/max_scene_context.py for native Max
Batch validation; it uses temporary workspace fixtures, not production data.
