"""Run with 3dsmaxbatch.exe. Redirects installation folders, restores hotkeys."""
import json
from pathlib import Path
import sys
import traceback
import uuid
import xml.etree.ElementTree as ET
from pymxs import runtime as rt

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "test-output"


def main():
    from qtmax import GetQMaxMainWindow
    try:
        from PySide2 import QtWidgets
    except ImportError:
        from PySide6 import QtWidgets
    keys = ("userScripts", "userMacros", "userIcons", "userStartupScripts")
    original = {key: str(rt.getDir(rt.Name(key))) for key in keys}
    original_keyboard = str(rt.actionMan.getKeyboardFile())
    run = OUTPUT / uuid.uuid4().hex
    run.mkdir(parents=True)
    checks = []
    try:
        for key in keys:
            folder = run / key
            folder.mkdir()
            rt.setDir(rt.Name(key), str(folder))
        rt.execute("global FXToolkitInstallSilent = true")
        for attempt in range(2):
            rt.fileIn(str(ROOT / "dist/FXToolkit_Network.mzp"))
            installed = run / "userScripts/FXToolkit"
            assert (installed / "fx_toolkit.py").is_file(), "Installer did not copy runtime"
            assert len(list((run / "userMacros").glob("FX-FX_*.mcr"))) == 10
            assert (run / "userStartupScripts/FXToolkit_startup.ms").is_file()
            module = sys.modules["fx_toolkit_runtime"]
            bars = GetQMaxMainWindow().findChildren(QtWidgets.QToolBar, module.OBJECT_NAME)
            assert len(bars) == 1, "Duplicate toolbar"
            assert len(bars[0].actions()) == 10
            labels = [a.text() for a in bars[0].actions()]
            index = labels.index("Scene Path")
            assert labels[index:index + 3] == ["Scene Path", "Caches Path", "Footages Path"]
            assert sum(not a.icon().isNull() for a in bars[0].actions()) == 5
            assert (installed / "FX-tyPreview.hsx").is_file(), "Hotkey install failed"
            assigned = ET.parse(str(installed / "FX-tyPreview.hsx")).getroot()
            assert any(n.tag == "Assign_Hotkey" and n.get("Shortcut") == "Shift+V"
                       and n.get("Id") == "647394-FX_TyPreview`FX" for n in assigned)
            after = list((installed / "backups").glob("*/After-FX.hsx"))
            assert len(after) == attempt + 1, "Max did not verify shortcut"
            checks.append("Native MZP installation %d: ten macros, one toolbar, five icons, Shift+V verified by Max" % (attempt + 1))
        rt.macros.run("FX", "FX_CopyPath")  # Unsaved scene: must be a no-op.
        rt.fileIn(str(run / "userStartupScripts/FXToolkit_startup.ms"))
        QtWidgets.QApplication.processEvents()
        module = sys.modules["fx_toolkit_runtime"]
        bar = module.show_toolbar()
        bar.grab().save(str(OUTPUT / "toolbar.png"))
        checks.append("Startup bootstrap, adjacent path buttons and Scene Path on an unsaved scene")
    finally:
        if original_keyboard and not rt.actionMan.loadKeyboardFile(original_keyboard):
            raise RuntimeError("Unable to restore original hotkey file: " + original_keyboard)
        for key, value in original.items():
            rt.setDir(rt.Name(key), value)
        rt.execute("FXToolkitInstallSilent = undefined")
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
