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
| `server/Scene/lib/` | Shared MAXScript scene context library, production registry entry point, examples, and API documentation. |
| `tests/` | Package/hotkey unit tests and native Max Batch installation and scene context tests. |
| `dist/` | The complete `FXToolkit_Network.mzp` and `FXToolkit_Server.zip`. |

## Installation and execution

Dropping the MZP into a viewport installs macros in `#userMacros`, icons in
`#userIcons`, runtime files in `#userScripts/FXToolkit`, and a loader in
`#userStartupScripts`. Reinstalling updates the existing FX toolbar.
Files replaced during installation are backed up; failures in the main
installation block attempt to restore the previous files.

The ten macros launch Patafix, PrepFX, Vecmap, Toolbox, tyFlow Open,
Copy Path, Caches Path, tyPreview, GeoInspector Pro, and Footages. Network tools are read
from the paths in `tools.json` when clicked; their sources are not installed
locally. Copy Path copies `maxfilepath` only when it is nonempty.

Deploy `Scene` and `Systems` from `FXToolkit_Server.zip` into
`Q:\fx\fx_tools\3dsMax\`. This installs the library and keeps GeoInspector at:

```text
Q:\fx\fx_tools\3dsMax\Systems\GeoinspectorPro\GeoInspector Pro.mse
```

The server ZIP replaces `GeoInspectorPro_Server.zip`; distribute only this
ZIP and the complete MZP. The build prepares files locally and does not deploy
them to Q:. Deploy the library before using Caches Path on client machines.

Vecmap needs both `vecmap.py` and `vecmap_lib` on the server. Other tool
dependencies remain the responsibility of their source projects.

### Shared scene context

`Scene/lib/FXSceneContext.ms` detects production, episode, and shot and returns
a struct with named fields including `production`, `pipeline`, `episode`,
`shot`, and `cachePath`. Call `FXSceneContext.current()` for the open scene or
`FXSceneContext.resolve fullScenePath` for an explicit path. Both only read.
Python tools can call the same functions through `pymxs.runtime`:

```maxscript
fileIn @"Q:\fx\fx_tools\3dsMax\Scene\lib\FXSceneContext.ms"
ctx = FXSceneContext.current()
cache = ctx.cachePath -- read only
FXSceneContext.ensureCacheDirectory ctx -- create missing cache folders
```

```python
from pymxs import runtime as rt
rt.fileIn(r"Q:\fx\fx_tools\3dsMax\Scene\lib\FXSceneContext.ms")
ctx = rt.FXSceneContext.current()
print(ctx.production, ctx.episode, ctx.shot, ctx.cachePath)
```

The adjacent `productions.cfg` delegates to the live PrepFX CFG by default,
avoiding duplicate production lists. It can instead contain compatible
`prod:Name|SceneRoot|FootageRoot|key=value` records. Preserve customized CFGs
when deploying updates. Every lookup rereads the registry; missing or invalid
configuration fails instead of silently using example productions.
The default directive is
`source:Q:\fx\fx_tools\3dsMax\Scene\PrepFX\prepFX.cfg`. Without a pipeline
option, records use `max_legacy`; arbitrary `key=value` metadata is retained
in `options`. Moving records into this registry does not reconfigure PrepFX,
whose current loader does not support the `source:` directive.

The Caches Path macro loads this library, resolves the saved scene, creates
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
See [the library README](3ds%20Max/FXToolkit/server/Scene/lib/README.txt) for
the complete schema, API, and usage examples. Add productions in the active
CFG without rebuilding the MZP; add pipeline layouts in the shared library
with corresponding native tests.

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

Both archives are rebuilt. By default the existing server ZIP supplies the
unchanged GeoInspector payload. To update it from its source repository:

```powershell
python build.py --geo-repo "C:\path\to\GeoInspectorPro"
```

The builder rejects an encrypted `.mse` older than its accompanying `.ms`.
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
tests include both user-provided studio paths and temporary cache directories.
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
