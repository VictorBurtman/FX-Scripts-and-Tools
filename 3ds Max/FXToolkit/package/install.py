"""Runs inside Max after native MZP extraction; never executes a network tool."""
import datetime
import importlib.util
from pathlib import Path
import shutil
import sys
from pymxs import runtime as rt


def install(source):
    if int(rt.maxVersion()[0]) < 24000:
        raise RuntimeError("FX Toolkit requires 3ds Max 2022 or newer.")
    target = Path(str(rt.getDir(rt.Name("userScripts")))) / "FXToolkit"
    stamp = datetime.datetime.now().strftime("%Y%m%d-%H%M%S-%f")
    backup = target / "backups" / stamp
    copies = [(p, target / p.name) for p in (source / "runtime").glob("*.py")]
    copies += [(source / "tools.json", target / "tools.json")]
    copies += [(p, Path(str(rt.getDir(rt.Name("userMacros")))) / p.name)
               for p in (source / "macros").glob("*.mcr")]
    copies += [(p, Path(str(rt.getDir(rt.Name("userIcons")))) / p.name)
               for p in (source / "icons").iterdir() if p.is_file()]
    copies += [(source / "FXToolkit_startup.ms",
                Path(str(rt.getDir(rt.Name("userStartupScripts")))) / "FXToolkit_startup.ms")]
    # Validate the entire payload before replacing any installed file.
    for src, dst in copies:
        if not src.is_file():
            raise RuntimeError("Missing package file: " + str(src))
    replaced = []
    try:
        for index, (src, dst) in enumerate(copies):
            dst.parent.mkdir(parents=True, exist_ok=True)
            old = None
            if dst.exists():
                backup.mkdir(parents=True, exist_ok=True)
                old = backup / (str(index) + "-" + dst.name)
                shutil.copy2(str(dst), str(old))
            replaced.append((dst, old))
            shutil.copy2(str(src), str(dst))
        for macro in (source / "macros").glob("*.mcr"):
            rt.fileIn(str(Path(str(rt.getDir(rt.Name("userMacros")))) / macro.name))
        rt.colorman.reInitIcons()
        spec = importlib.util.spec_from_file_location("fx_toolkit_runtime", str(target / "fx_toolkit.py"))
        module = importlib.util.module_from_spec(spec)
        sys.modules[spec.name] = module
        spec.loader.exec_module(module)
        module.show_toolbar()
    except Exception:
        for dst, old in reversed(replaced):
            if old:
                shutil.copy2(str(old), str(dst))
            elif dst.exists():
                dst.unlink()
        raise
    # A hotkey failure must not masquerade as success or undo the usable toolbar.
    try:
        saved = module.install_hotkey()
        status = "Shift+V: tyPreview.\nPrevious hotkeys: " + str(saved)
    except Exception as exc:
        status = "Shift+V was NOT installed: " + str(exc) + "\nUse Customize > Hotkey Editor > FX > tyPreview."
    message = ("FX toolbar and 9 macros installed.\n\n" + status +
               "\n\nNetwork scripts are loaded from Q: when clicked.")
    if getattr(rt, "FXToolkitInstallSilent", False) == True:
        print(message)
    else:
        rt.messageBox(message, title="FX Toolkit")


# executeFile can retain the caller's __file__ in Max's shared Python namespace.
# The compiled function's filename always belongs to this extracted installer.
install(Path(install.__code__.co_filename).resolve().parent)
