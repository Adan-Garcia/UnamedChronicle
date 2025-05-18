extends Node
class_name data_graber


func _get_empire(empire: String) -> EmpireData:
	return Global.empires[empire] if Global.empires else null


func _get_sector(sector: String) -> SectorData:
	return Global.sectors[sector] if Global.sectors else null


func _get_town(town: String) -> TownData:
	return Global.towns[town] if Global.towns else null
