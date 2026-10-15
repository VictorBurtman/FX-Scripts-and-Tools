# Development Guide

This repository contains FX scripts for 3ds Max, Houdini, and Maya. Most tools
are standalone scripts. The packaged **FX Toolkit** lives in
`3ds Max/FXToolkit/` and installs a shared studio toolbar for 3ds Max.

## FX Toolkit architecture

The target is **3ds Max 2022**, using its embedded Python 3, `pymxs`, and
PySide2. The toolbar also supports PySide6 for newer Max versions.

| File or directory | Responsibility |
| --- | --- |
| `tools.json` | Tool order, macro identities, labels, network paths, and icon prefixes. |
| `build.py` | Generates macros and packages the MZP and server ZIP. Uses only the Python standard library. |
| `package/mzp.run`, `package/install.ms` | Native MZP entry points for Run Script and drag-and-drop installation. |
| `package/install.py` | Copies local files, registers macros, creates the toolbar, and configures Shift+V. |
| `package/runtime/fx_toolkit.py` | Dockable Qt toolbar and Max hotkey integration. Buttons invoke registered macros. |
| `package/runtime/hotkeys.py` | XML transformations that preserve existing hotkey customizations. |
| `package/FXToolkit_startup.ms`, `package/runtime/bootstrap.py` | Recreate the toolbar when Max starts. |
| `package/icons/`, `assets/` | Distributed icons and the generated PrepFX artwork/prompt. |
| `server/00_Lib/` | Shared MAXScript scene context library, production records and API documentation. |
| `server/Scene/Caches_path/`, `server/Scene/Footages_path/` | Network entry scripts using the shared library. |
| `tests/` | Package/hotkey unit tests and native Max Batch installation and scene context tests. |
| `dist/` | The complete `FXToolkit_Network.mzp` and `FXToolkit_Server.zip`. |

## Installation and execution

Dropping the MZP into a viewport installs macros in `#userMacros`, icons in
`#userIcons`, runtime files in `#userScripts/FXToolkit`, and a loader in
`#userStartupScripts`. Reinstalling updates the existing FX toolbar.
Files replaced during installation are backed up; failures in the main
installation block attempt to restore the previous files.

The ten macros launch Patafix, PrepFX, Vecmap, Toolbox, tyFlow Open,
Scene Path, Caches Path, Footages Path, tyPreview, and GeoInspector Pro. Network tools are read
from the paths in `tools.json` when clicked; their sources are not installed
locally. Scene Path copies `maxfilepath` only when it is nonempty.

Deploy `00_Lib` and `Scene` from `FXToolkit_Server.zip` into
`Q:\fx\fx_tools\3dsMax\`. The ZIP contains `00_Lib/FXSceneContext.ms`,
`00_Lib/productions.cfg`, `Scene/Caches_path/cache_path.ms`, and
`Scene/Footages_path/footages_path.ms`. Documentation stays in the repository. GeoInspector is already
deployed separately and is no longer bundled in this ZIP.

The build prepares files locally and does not deploy them to Q:. Deploy the
updated library and both network entry scripts, then install the updated MZP
to apply the button labels, order, and launcher paths. The server ZIP contains
exactly these four runtime/configuration files, with no README or DEPLOY file.

The deployed library folder needs `FXSceneContext.ms` and `productions.cfg`
side by side; `README.txt` is repository documentation, excluded from the ZIP. When migrating from
`Scene\lib`, copy the new production records into `00_Lib\productions.cfg`
instead of retaining the old `source:` redirect to PrepFX. Reinstall the MZP
on each workstation to update the macro's stored path. The old example CFG
is no longer used or distributed.

Vecmap needs both `vecmap.py` and `vecmap_lib` on the server. Other tool
dependencies remain the responsibility of their source projects.

### Shared scene context

`00_Lib/FXSceneContext.ms` detects production, episode, and shot and returns
a struct with named fields including `production`, `pipeline`, `episode`,
`shot`, and `cachePath`. Call `FXSceneContext.current()` for the open scene or
`FXSceneContext.resolve fullScenePath` for an explicit path. Both only read.
Python tools can call the same functions through `pymxs.runtime`:

```maxscript
fileIn @"Q:\fx\fx_tools\3dsMax\00_Lib\FXSceneContext.ms"
ctx = FXSceneContext.current()
cache = ctx.cachePath -- read only
FXSceneContext.ensureCacheDirectory ctx -- create missing cache folders
```

```python
from pymxs import runtime as rt
rt.fileIn(r"Q:\fx\fx_tools\3dsMax\00_Lib\FXSceneContext.ms")
ctx = rt.FXSceneContext.current()
print(ctx.production, ctx.episode, ctx.shot, ctx.cachePath)
```

The adjacent `productions.cfg` contains the production records directly:
`prod:Name|SceneRoot|FootageRoot|key=value`. The supplied list contains Alice2,
BES2, Borrowers, Oum3, and smurfs. Without a pipeline option, records use
`max_legacy`; BES2 uses `pipeline=maya_shots`. Arbitrary metadata is retained
in `options`. Every lookup rereads this file; missing or invalid configuration
fails without falling back to PrepFX. Preserve customized CFGs on updates.
There is no separate example CFG.

PrepFX is maintained and deployed separately; these Toolkit changes do not
modify its script. Any PrepFX installation still using `prepFX.cfg` must keep
that file until its loader is migrated to the shared `00_Lib\productions.cfg`.

The Caches Path macro loads `Scene/Caches_path/cache_path.ms`, which loads
the shared library, resolves the saved scene, creates
missing cache folders, then copies the path. Max productions use
`<root>\<episode>\fx\3D_Sources\<shot>`; `pipeline=maya_shots` uses
`<root>\<episode>\<shot>\fx\wip\3d\datas`. Unknown productions, ambiguous or
conflicting names, and unavailable roots fail without copying a guessed path.
Directory creation requires an existing production root and episode, plus
the shot folder for Maya productions. Missing cache directories are created
recursively; existing files are preserved. The clipboard changes only after
creation succeeds. Scene resolution compares configured roots on directory
boundaries, prefers the longest match, and checks recognized filenames
against episode/shot folders.
See [the library README](3ds%20Max/FXToolkit/server/00_Lib/README.txt) for
the complete schema, API, and usage examples. Add productions in the active
CFG without rebuilding the MZP; add pipeline layouts in the shared library
with corresponding native tests.

### Path buttons and network entry scripts

The toolbar groups **Scene Path, Caches Path, Footages Path** together, in that
order. Their internal macro IDs remain `FX_CopyPath`, `FX_CachesPath`, and
`FX_Footages` to preserve existing bindings. Scene Path retains the original
inline copy of `maxFilePath`. The other two macros only load their network
scripts; both scripts load `00_Lib/FXSceneContext.ms` on each execution.

`Scene/Footages_path/footages_path.ms` calls
`FXSceneContext.copyCurrentFootagesPath()`. The library also exposes
`getFootagesPath fullScenePath` and `buildFootagesPath context` for read-only
lookups. The paths use the configured footage root (or the scene root when
absent) and the following layouts:

- Max: `<footageRoot>\<episode>\rendu-compo\<shot>\<episode>sr<shotNumber>_FX`.
- Maya: `<footageRoot>\<episode>\<shot>\fx\wip\fx3d`.

For example, Alice2 episode e322 shot s0780 resolves to
`S:\alice2_footage\production\e322\rendu-compo\s0780\e322sr0780_FX`.
BES2 episode e204 shot s0810 resolves to
`S:\bes2_footage\shots\e204\s0810\fx\wip\fx3d`.

Maya paths stop at `fx3d`, without a version subfolder. Filename versions and
save suffixes do not change the result; unversioned filenames are also valid
when the scene folders identify the shot. Footages Path copies the
expected path without creating directories or opening Explorer. Caches Path
retains its existing directory creation behavior. Deploy the updated library
and both entry scripts, then reinstall the MZP to update labels and launchers.

### Hotkeys

At installation, the current hotkeys are exported to
`#userScripts/FXToolkit/backups/<timestamp>/Before-FX.hsx`. Shift+V is assigned
to tyPreview in the main UI context; other contexts and shortcuts are retained.
The new set is loaded and exported again for verification. Failure triggers
an attempt to restore the backup and reports the hotkey error separately.
Startup does not reapply Shift+V; reinstalling does. To restore a previous
keyset, load its `Before-FX.hsx` through Max's Hotkey Editor.

## Build and validate

From the repository root:

```powershell
cd "3ds Max/FXToolkit"
python build.py
python -m unittest discover -s tests -p "test_*.py"
```

Both archives are rebuilt directly from this repository. No GeoInspector
source repository or previous server archive is required.
Edit `tools.json` for path/button changes, then rebuild; do not edit generated
macros inside the archive. Keep macro identities stable to preserve shortcuts.
To re-export PrepFX icons, run `python export_prepfx_icons.py` with Pillow
installed. The MZP build itself does not require Pillow.

`tests/max_install.py` can run through `3dsmaxbatch.exe`. It redirects install
folders into ignored `test-output/` directories and restores the original
directory settings and hotkey file. `tests/max_scene_context.py` validates
the real MAXScript library, config reloads, both layouts, invalid inputs and
directory creation in temporary fixtures, without changing the clipboard.
Test logs and Python caches are ignored.
Before release, check installation, reinstallation, restart, icon rendering,
network launches, and Shift+V on the target Max version.

## Validation status and known issue

Six package tests, ten-action installation/reinstallation, and the native
scene context tests passed in Max Batch 2027 on October 15, 2026. The context
tests include both user-provided studio paths, temporary cache directories,
and automatic discovery of the adjacent registry after the move to `00_Lib`.
They also cover the final Max/Maya footage layouts, Maya version independence,
and dispatch from both network scripts to the shared library. Installation
tests verify the three path buttons are adjacent in the requested order.
This does not replace testing on Max 2022 and the studio
network. Custom toolbar positioning across sessions is not guaranteed.

One workstation reported `EXCEPTION_ACCESS_VIOLATION` at
`rt.colorman.reInitIcons()` in `package/install.py`. That call reloads Max's
global CUI icons, before the toolbar and hotkeys are configured. The root cause
is unconfirmed. Avoiding that global refresh is a proposed workaround, **not
yet implemented**. The FX Qt toolbar loads its bitmap icons directly; native
CUI macro icons may need a Max restart if the refresh is removed.

Keep unrelated changes in other tool directories out of FX Toolkit commits.
See the root `README.md` for usage/license terms and the toolkit's `README.txt`
for installation instructions and Autodesk references.
