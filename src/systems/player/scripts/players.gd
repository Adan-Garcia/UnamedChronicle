extends Node
class_name playermanager

signal stats_changed(player_name: String)

const STAT_LIMITS := {"Energy": 20.0, "Health": 20.0, "Mana": 20.0}

@export var info: Dictionary[String, Player]
## Where each player's resource lives on disk, so changes can be saved back.
var save_paths: Dictionary[String, String] = {}


func register(player: Player, path: String) -> void:
	info[player.Name] = player
	save_paths[player.Name] = path


## Apply the Referee's stat_changes (only Energy, Mana and Health may change).
func apply_stat_changes(player_name: String, changes: Dictionary) -> void:
	var player: Player = info.get(player_name)
	if player == null or changes.is_empty():
		return
	for stat in changes.keys():
		if stat not in STAT_LIMITS:
			continue
		var value = clampf(
			float(player.Data.get(stat)) + float(changes[stat]), 0.0, STAT_LIMITS[stat]
		)
		player.Data.set(stat, roundi(value) if stat == "Mana" else value)
	stats_changed.emit(player_name)
	save_player(player_name)


## Recover a little energy as in-game time passes.
func rest(player_name: String, amount: float) -> void:
	var player: Player = info.get(player_name)
	if player and player.Data.Energy < 10.0:
		player.Data.Energy = minf(10.0, player.Data.Energy + amount)


func save_player(player_name: String) -> void:
	if player_name in info and player_name in save_paths:
		var err := ResourceSaver.save(info[player_name], save_paths[player_name])
		if err != OK:
			push_error("Failed to save player %s (%d)" % [player_name, err])
