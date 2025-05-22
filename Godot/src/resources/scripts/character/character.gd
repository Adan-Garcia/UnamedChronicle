extends Resource

class_name Character

@export var Origin: Address
@export var CurrentLocation: Address

@export var Name: String
# Mana (only used by some, but reusable for magical entities)
@export var Mana: int = 0
@export var Energy: float = 10.0
@export var Health: float = 10.0
# Primary traits (usable by all characters including enemies)
# Range: 0–20, average is 10
@export var Strength: int = 10
@export var Agility: int = 10
@export var Endurance: int = 10
@export var Intelligence: int = 10
@export var Charisma: int = 10

# Combat skills
@export var Melee: int = 10
@export var Ranged: int = 10
@export var Defense: int = 10

# Common utility skills (for stealth, AI pathing, or challenge types)
@export var Stealth: int = 10
@export var Tracking: int = 10
@export var Tactics: int = 10
@export var Perception: int = 10


func _to_json(
	obj: Object = self,
	recurse_resources := true,
	recurse_nodes := true,
	skip_keys := ["script", "resource_name", "resource_local_to_scene"]
) -> Dictionary:
	var result := {}
	if obj == null:
		return result

	var property_list = obj.get_property_list()
	for prop in property_list:
		var name = prop.name
		var usage = prop.usage

		# Skip keys we know are editor/system noise
		if name in skip_keys:
			continue

		# Only export visible export vars
		if not (usage & PROPERTY_USAGE_STORAGE != 0 and usage & PROPERTY_USAGE_EDITOR != 0):
			continue

		var value = obj.get(name)

		# Recurse into Resources
		if recurse_resources and value is Resource:
			result[name] = _to_json(value, recurse_resources, recurse_nodes, skip_keys)
		# Recurse into Nodes
		elif recurse_nodes and value is Node:
			result[name] = _to_json(value, recurse_resources, recurse_nodes, skip_keys)
		else:
			result[name] = value

	return result
