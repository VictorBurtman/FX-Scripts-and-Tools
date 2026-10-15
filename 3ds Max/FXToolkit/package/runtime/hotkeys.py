"""Pure XML transformation, independent of Max and Qt, for HSX hotkeys."""
import copy
import xml.etree.ElementTree as ET

TARGET = "647394-FX_TyPreview`FX"
SHORTCUT = "Shift+V"


def normalized(shortcut):
    return frozenset(part.strip().lower() for part in shortcut.split("+"))


def effective_bindings(defaults, transformations):
    bindings = {(e.attrib["Shortcut"], e.attrib["Id"]) for e in defaults.findall("Hotkey")}
    for node in transformations:
        pair = (node.attrib["Shortcut"], node.attrib["Id"])
        if node.tag == "Assign_Hotkey":
            bindings.add(pair)
        elif node.tag == "Unassign_Hotkey":
            bindings.discard(pair)
        else:
            raise ValueError("Unsupported HSX transformation: " + node.tag)
    return bindings


def patch_hotkeys(defaults, current, contexts):
    if defaults.tag != "MaxHotkeys" or current.tag != "MaxHotkeyTransformations":
        raise ValueError("Unrecognized 3ds Max hotkey XML format")
    if 647394 not in contexts:
        raise ValueError("MAXScript action table is unavailable")
    main_context = contexts[647394]
    result = copy.deepcopy(current)
    result.set("Locked", "false")
    result.set("Description", "FX Toolkit - user hotkeys + tyPreview")
    bindings = effective_bindings(defaults, current)
    conflicts = []
    for shortcut, action in bindings:
        if normalized(shortcut) != normalized(SHORTCUT):
            continue
        # Signed action-table IDs are supported as well as unsigned DWORD IDs.
        table = int(action.split("-", 1)[0]) if not action.startswith("-") else -int(action[1:].split("-", 1)[0])
        if contexts.get(table & 0xFFFFFFFF) == main_context and action != TARGET:
            conflicts.append((shortcut, action))
    if not conflicts and (SHORTCUT, TARGET) in bindings:
        return result
    for shortcut, action in sorted(conflicts):
        ET.SubElement(result, "Unassign_Hotkey", Shortcut=shortcut, Id=action)
    if (SHORTCUT, TARGET) not in bindings:
        ET.SubElement(result, "Assign_Hotkey", Shortcut=SHORTCUT, Id=TARGET)
    return result
