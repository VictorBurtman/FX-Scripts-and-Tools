"""Build the FX Toolkit MZP and optional server ZIP using the standard library."""
import argparse
import json
from pathlib import Path
import zipfile

ROOT = Path(__file__).resolve().parent


def macro_source(tool, category="FX", name=None):
    name = name or tool["macro"]
    icon = '\nicon:#("%s", 1)' % tool["icon"] if tool.get("icon") else ""
    if tool["kind"] == "copy_path":
        body = 'if maxfilepath != "" do setclipboardText maxfilepath'
    else:
        command = ('python.executeFile scriptPath throwOnError:true clearUndoBuffer:false'
                   if tool["kind"] == "python" else 'fileIn scriptPath')
        body = '''local scriptPath = @"%s"
        if doesFileExist scriptPath then
        (
            try (%s)
            catch (messageBox ("%s: " + getCurrentException()) title:"FX Toolkit")
        )
        else messageBox ("Network tool unavailable. Check Q: and the server path:\\n\\n" + scriptPath) title:"%s"''' % (tool["path"], command, tool["label"], tool["label"])
    return '''macroScript %s
category:"%s"
internalCategory:"%s"
toolTip:"%s"
buttonText:"%s"%s
(
    on execute do
    (
        %s
    )
)
''' % (name, category, category, tool["label"], tool["label"], icon, body)


def write_zip(path, contents):
    path.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(str(path), "w", zipfile.ZIP_DEFLATED) as archive:
        for name, data in sorted(contents.items()):
            info = zipfile.ZipInfo(name, (2026, 1, 1, 0, 0, 0))
            info.compress_type = zipfile.ZIP_DEFLATED
            archive.writestr(info, data.encode("utf-8") if isinstance(data, str) else data)
    with zipfile.ZipFile(str(path)) as archive:
        assert archive.testzip() is None
    print(path)


def build(geo_repo=None):
    tools = json.loads((ROOT / "tools.json").read_text(encoding="utf-8"))
    contents = {p.relative_to(ROOT / "package").as_posix(): p.read_bytes()
                for p in (ROOT / "package").rglob("*")
                if p.is_file() and "__pycache__" not in p.parts}
    contents["tools.json"] = (ROOT / "tools.json").read_bytes()
    contents["README.txt"] = (ROOT / "README.txt").read_bytes()
    for tool in tools:
        contents["macros/FX-" + tool["macro"] + ".mcr"] = macro_source(tool)
        if tool.get("icon"):
            for size in (16, 24):
                for suffix in ("a", "i"):
                    required = "icons/%s_%s%s.bmp" % (tool["icon"], size, suffix)
                    if required not in contents:
                        raise FileNotFoundError(required)
    write_zip(ROOT / "dist" / "FXToolkit_Network.mzp", contents)
    if geo_repo:
        source = Path(geo_repo)
        encrypted = source / "GeoInspector Pro.mse"
        plain = source / "GeoInspector Pro.ms"
        if plain.exists() and encrypted.stat().st_mtime < plain.stat().st_mtime:
            raise RuntimeError("GeoInspector Pro.mse is stale: re-encrypt it in 3ds Max first")
        write_zip(ROOT / "dist" / "GeoInspectorPro_Server.zip", {
            "GeoinspectorPro/GeoInspector Pro.mse": encrypted.read_bytes(),
            "DEPLOY.txt": "Copy the GeoinspectorPro folder into Q:\\fx\\fx_tools\\3dsMax\\Systems\\.\nIcons are installed locally by the MZP.\n"})


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--geo-repo", type=Path, help="Optional source of the GeoInspector Pro.mse server payload")
    build(parser.parse_args().geo_repo)
