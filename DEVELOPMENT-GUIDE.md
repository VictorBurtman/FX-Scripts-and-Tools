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
| `build.py` | Generates macros and packages the MZP; optionally packages the GeoInspector server payload. Uses only the Python standard library. |
| `package/mzp.run`, `package/install.ms` | Native MZP entry points for Run Script and drag-and-drop installation. |
| `package/install.py` | Copies local files, registers macros, creates the toolbar, and configures Shift+V. |
| `package/runtime/fx_toolkit.py` | Dockable Qt toolbar and Max hotkey integration. Buttons invoke registered macros. |
| `package/runtime/hotkeys.py` | XML transformations that preserve existing hotkey customizations. |
| `package/FXToolkit_startup.ms`, `package/runtime/bootstrap.py` | Recreate the toolbar when Max starts. |
| `package/icons/`, `assets/` | Distributed icons and the generated PrepFX artwork/prompt. |
| `tests/` | Package/hotkey unit tests and an optional Max Batch installation test. |
| `dist/` | The complete `FXToolkit_Network.mzp` and `GeoInspectorPro_Server.zip`. |

## Installation and execution

Dropping the MZP into a viewport installs macros in `#userMacros`, icons in
`#userIcons`, runtime files in `#userScripts/FXToolkit`, and a loader in
`#userStartupScripts`. Reinstalling updates the existing FX toolbar.
Files replaced during installation are backed up; failures in the main
installation block attempt to restore the previous files.

The nine macros launch Patafix, PrepFX, Vecmap, Toolbox, tyFlow Open,
Copy Path, tyPreview, GeoInspector Pro, and Footages. Network tools are read
from the paths in `tools.json` when clicked; their sources are not installed
locally. Copy Path copies `maxfilepath` only when it is nonempty.

Deploy the folder inside `GeoInspectorPro_Server.zip` so the script is at:

```text
Q:\fx\fx_tools\3dsMax\Systems\GeoinspectorPro\GeoInspector Pro.mse
```

Vecmap needs both `vecmap.py` and `vecmap_lib` on the server. Other tool
dependencies remain the responsibility of their source projects.

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

To also rebuild the server ZIP, supply the GeoInspector source repository:

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
directory settings and hotkey file. Test logs and Python caches are ignored.
Before release, check installation, reinstallation, restart, icon rendering,
network launches, and Shift+V on the target Max version.

## Validation status and known issue

Package tests and installation/reinstallation in Max Batch 2027 passed during
initial development. This does not replace testing on Max 2022 and the studio
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
