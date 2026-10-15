"""Recreate the toolbar at startup, without touching the user's hotkeys."""
import importlib.util
from pathlib import Path
import sys
from pymxs import runtime as rt

root = Path(str(rt.getDir(rt.Name("userScripts")))) / "FXToolkit"
spec = importlib.util.spec_from_file_location("fx_toolkit_runtime", str(root / "fx_toolkit.py"))
module = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = module
spec.loader.exec_module(module)
module.schedule_toolbar()
