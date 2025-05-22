@tool
extends Node


func _ready():
    var hierarchy = build_hierarchy("res://Tigyia Minimal 2025-05-01-10-00.json")
    var file = FileAccess.open("res://heirarchy.json", FileAccess.WRITE)
    if file:
        file.store_string(JSON.stringify(hierarchy, "\t"))
        file.close()

func build_hierarchy(json_path: String) -> Dictionary:
    var file = FileAccess.open(json_path, FileAccess.READ)
    if not file:
        push_error("Failed to open file: " + json_path)
        return {}

    var data = JSON.parse_string(file.get_as_text())
    file.close()

    if typeof(data) != TYPE_DICTIONARY or not data.has("map"):
        push_error("Invalid or missing 'map' in JSON")
        return {}

    var mp = data["map"]
    var empires_list = mp["states"]
    var sectors_list = []
    for p in mp["provinces"]:
        if typeof(p) == TYPE_DICTIONARY:
            sectors_list.append(p)

    var towns_list = []
    for b in mp["burgs"]:
        if b.has("cell"):
            towns_list.append(b)

    var cell2prov_str = mp["cellprovinces"]
    var empire_names: Array = []
    var empire_map: Dictionary = {}

    for s in empires_list:
        if s.has("pole"):
            empire_map[s["i"]] = {
                "id": s["i"],
                "name": s.get("name", ""),
                "x": s["pole"][0],
                "y": s["pole"][1],
                "area": s["area"],
                "neighbors": s["neighbors"],
                "urban": s["urban"],
                "rural": s["rural"],
                "diplomacy": s["diplomacy"],
                "sectors": []
            }

    var sector_map: Dictionary = {}
    for p in sectors_list:
        sector_map[p["i"]] = {
            "id": p["i"],
            "name": p.get("name", ""),
            "x": p["pole"][0],
            "y": p["pole"][1],
            "towns": []
        }

    for s in empires_list:
        var sid = s["i"]
        for pid in s.get("provinces", []):
            if sector_map.has(pid):
                empire_map[sid]["sectors"].append(sector_map[pid])
        empire_names.append(s["name"])

    for t in towns_list:
        var cell_str = str(t["cell"])
        var prov_id = cell2prov_str.get(cell_str)
        if prov_id != null and sector_map.has(prov_id):
            sector_map[prov_id]["towns"].append({
                "id": t["i"],
                "name": t["name"],
                "x": t["x"],
                "y": t["y"],
                "capital": t["capital"],
                "culture": t["culture"],
                "population": t["population"]
            })

    return {
        "Empires": empire_map.values(),
        "EmpireList": empire_names
    }
