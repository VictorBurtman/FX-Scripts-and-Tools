import ast
import importlib.util
import json
from pathlib import Path
import unittest
import xml.etree.ElementTree as ET
import zipfile

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("hotkeys", str(ROOT / "package/runtime/hotkeys.py"))
hotkeys = importlib.util.module_from_spec(spec)
spec.loader.exec_module(hotkeys)


class HotkeyTests(unittest.TestCase):
    def setUp(self):
        self.defaults = ET.fromstring('''<MaxHotkeys>
          <Hotkey Shortcut="Shift+V" Id="0-40033"/>
          <Hotkey Shortcut="Shift+V" Id="7-123"/>
          <Hotkey Shortcut="Ctrl+S" Id="0-40006"/>
        </MaxHotkeys>''')
        self.contexts = {0: 0, 647394: 0, 7: 42}

    def test_preserves_other_keys_and_contexts(self):
        current = ET.fromstring('''<MaxHotkeyTransformations Locked="true">
          <Assign_Hotkey Shortcut="Ctrl+Alt+K" Id="0-888"/>
          <Unassign_Hotkey Shortcut="Ctrl+S" Id="0-40006"/>
          <Assign_Hotkey Shortcut="Shift+V" Id="647394-Other`Custom"/>
        </MaxHotkeyTransformations>''')
        before = ET.tostring(current)
        patched = hotkeys.patch_hotkeys(self.defaults, current, self.contexts)
        result = hotkeys.effective_bindings(self.defaults, patched)
        self.assertEqual(result, {("Shift+V", "7-123"), ("Ctrl+Alt+K", "0-888"),
                                  ("Shift+V", hotkeys.TARGET)})
        self.assertEqual(ET.tostring(current), before)
        twice = hotkeys.patch_hotkeys(self.defaults, patched, self.contexts)
        self.assertEqual(ET.tostring(patched), ET.tostring(twice))

    def test_existing_alternative_typreview_shortcut_survives(self):
        current = ET.Element("MaxHotkeyTransformations")
        ET.SubElement(current, "Assign_Hotkey", Shortcut="Ctrl+F8", Id=hotkeys.TARGET)
        patched = hotkeys.patch_hotkeys(self.defaults, current, self.contexts)
        self.assertIn(("Ctrl+F8", hotkeys.TARGET), hotkeys.effective_bindings(self.defaults, patched))

    def test_unknown_format_is_rejected(self):
        with self.assertRaises(ValueError):
            hotkeys.patch_hotkeys(ET.Element("Unknown"), ET.Element("Unknown"), self.contexts)


class PackageTests(unittest.TestCase):
    def test_distribution(self):
        with zipfile.ZipFile(ROOT / "dist/FXToolkit_Network.mzp") as z:
            self.assertIsNone(z.testzip())
            tools = json.loads(z.read("tools.json"))
            self.assertEqual(len(tools), 9)
            self.assertEqual(len([n for n in z.namelist() if n.endswith(".mcr")]), 9)
            self.assertIn('drop "install.ms"', z.read("mzp.run").decode())
            self.assertFalse(any(n.endswith(".mse") for n in z.namelist()))
            for tool in tools:
                code = z.read("macros/FX-" + tool["macro"] + ".mcr").decode()
                if tool.get("path"):
                    self.assertIn(tool["path"], code)
                    self.assertIn("doesFileExist", code)
                if tool.get("icon"):
                    for size in (16, 24):
                        for suffix in ("a", "i"):
                            self.assertIn("icons/%s_%s%s.bmp" % (tool["icon"], size, suffix), z.namelist())
            preview = z.read("macros/FX-FX_TyPreview.mcr").decode()
            self.assertNotIn("icon:", preview)
            copy_path = z.read("macros/FX-FX_CopyPath.mcr").decode()
            self.assertIn('if maxfilepath != "" do setclipboardText maxfilepath', copy_path)

    def test_python_37_syntax(self):
        for source in (ROOT / "package").rglob("*.py"):
            ast.parse(source.read_text(encoding="utf-8"), feature_version=(3, 7))


if __name__ == "__main__":
    unittest.main()
