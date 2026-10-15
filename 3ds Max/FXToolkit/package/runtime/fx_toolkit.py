"""Dockable FX toolbar for Max 2022/PySide2 (also supports PySide6)."""
import datetime
from functools import partial
import importlib.util
import json
from pathlib import Path
import xml.etree.ElementTree as ET

from pymxs import runtime as rt
import qtmax
try:
    from PySide2 import QtCore, QtGui, QtWidgets
except ImportError:
    from PySide6 import QtCore, QtGui, QtWidgets

ROOT = Path(__file__).resolve().parent
OBJECT_NAME = "FXToolkit.Toolbar"
_toolbar = None


def run_macro(name, checked=False):
    try:
        rt.macros.run("FX", name)
    except Exception as exc:
        rt.messageBox(str(exc), title="FX Toolkit")


def icon_for(prefix):
    """Use the original Max image strip and its alpha mask, first icon."""
    folder = Path(str(rt.getDir(rt.Name("userIcons"))))
    image = QtGui.QImage(str(folder / (prefix + "_24i.bmp"))).copy(0, 0, 24, 24)
    alpha = QtGui.QImage(str(folder / (prefix + "_24a.bmp"))).copy(0, 0, 24, 24)
    if image.isNull() or alpha.isNull():
        return QtGui.QIcon()
    image = image.convertToFormat(QtGui.QImage.Format_ARGB32)
    for y in range(image.height()):
        for x in range(image.width()):
            color = image.pixelColor(x, y)
            # _a.bmp stores alpha (white = opaque); it is not a monochrome mask.
            color.setAlpha(alpha.pixelColor(x, y).red())
            image.setPixelColor(x, y, color)
    return QtGui.QIcon(QtGui.QPixmap.fromImage(image))


def show_toolbar():
    global _toolbar
    main = qtmax.GetQMaxMainWindow()
    if main is None:
        raise RuntimeError("3ds Max main window is not ready")
    toolbar = main.findChild(QtWidgets.QToolBar, OBJECT_NAME)
    if toolbar is None:
        toolbar = QtWidgets.QToolBar("FX", main)
        toolbar.setObjectName(OBJECT_NAME)
        toolbar.setFloatable(True)
        toolbar.setMovable(True)
        main.addToolBar(QtCore.Qt.TopToolBarArea, toolbar)
    else:
        toolbar.clear()
    toolbar.setIconSize(QtCore.QSize(24, 24))
    toolbar.setToolButtonStyle(QtCore.Qt.ToolButtonIconOnly)
    action_class = getattr(QtWidgets, "QAction", None) or QtGui.QAction
    for tool in json.loads((ROOT / "tools.json").read_text(encoding="utf-8")):
        action = action_class(tool["label"], toolbar)
        action.setObjectName(tool["macro"])
        action.setToolTip(tool["label"] + (" (Shift+V)" if tool["macro"] == "FX_TyPreview" else ""))
        if tool.get("icon"):
            action.setIcon(icon_for(tool["icon"]))
        action.triggered.connect(partial(run_macro, tool["macro"]))
        toolbar.addAction(action)
        if not tool.get("icon") or action.icon().isNull():
            toolbar.widgetForAction(action).setToolButtonStyle(QtCore.Qt.ToolButtonTextOnly)
    toolbar.show()
    _toolbar = toolbar
    return toolbar


def schedule_toolbar():
    # Wait for the main window event loop after startup scripts have run.
    QtCore.QTimer.singleShot(0, show_toolbar)


def install_hotkey():
    spec = importlib.util.spec_from_file_location("fx_toolkit_hotkeys", str(ROOT / "hotkeys.py"))
    hotkeys = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(hotkeys)
    defaults_path = Path(str(rt.getDir(rt.Name("maxRoot")))) / "UI_ln" / "CUI" / "Default.hsxb"
    defaults = ET.parse(str(defaults_path)).getroot()
    contexts = {}
    for i in range(1, int(rt.actionMan.numActionTables) + 1):
        table = rt.actionMan.getActionTable(i)
        contexts[int(table.id) & 0xFFFFFFFF] = int(table.contextID)
    stamp = datetime.datetime.now().strftime("%Y%m%d-%H%M%S-%f")
    backup_dir = ROOT / "backups" / stamp
    backup_dir.mkdir(parents=True, exist_ok=True)
    backup = backup_dir / "Before-FX.hsx"
    original_name = str(rt.actionMan.getKeyboardFile())
    (backup_dir / "original-keyset.txt").write_text(original_name, encoding="utf-8")
    if not rt.actionMan.saveKeyboardFile(str(backup)):
        raise RuntimeError("Cannot back up the current hotkeys")
    try:
        current = ET.parse(str(backup)).getroot()
        patched = hotkeys.patch_hotkeys(defaults, current, contexts)
        target = ROOT / "FX-tyPreview.hsx"
        ET.ElementTree(patched).write(str(target), encoding="utf-8", xml_declaration=True)
        if not rt.actionMan.loadKeyboardFile(str(target)):
            raise RuntimeError("3ds Max rejected the FX hotkey file")
        # Serialize again to confirm Max accepted the macro binding.
        verified = backup_dir / "After-FX.hsx"
        if not rt.actionMan.saveKeyboardFile(str(verified)):
            raise RuntimeError("Cannot verify the assigned shortcut")
        effective = hotkeys.effective_bindings(defaults, ET.parse(str(verified)).getroot())
        if (hotkeys.SHORTCUT, hotkeys.TARGET) not in effective:
            raise RuntimeError("3ds Max did not retain Shift+V for tyPreview")
        if not rt.actionMan.loadKeyboardFile(str(target)):
            raise RuntimeError("Cannot activate the FX hotkey file")
    except Exception:
        if not rt.actionMan.loadKeyboardFile(str(backup)):
            raise RuntimeError("Hotkey setup failed AND restore failed; load manually: " + str(backup))
        raise
    return backup
