extends Node
class_name cordmanager

const px_per_mile = 4
const ft_per_mile = 5280


func _get_empire(empire: String) -> Vector2:
	return Global.empires[empire].Cords if Global.empires else Vector2.ZERO


func _get_sector(sector: String) -> Vector2:
	return Global.sectors[sector].Cords if Global.sectors else Vector2.ZERO


func _get_town(town: String) -> Vector2:
	return Global.towns[town].Cords if Global.towns else Vector2.ZERO


func _get_distance(pos1: Vector2, pos2: Vector2) -> float:
	pos1 *= px_per_mile * ft_per_mile
	pos2 *= px_per_mile * ft_per_mile
	return pos1.distance_to(pos2)
