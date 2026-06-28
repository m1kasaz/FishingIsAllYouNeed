class_name SaveManagerService
extends Node

const DEFAULT_SAVE_DATA: Dictionary = {
	"coins": 0,
	"discovered_fish_ids": [],
}

var _session_save_data: Dictionary = DEFAULT_SAVE_DATA.duplicate(true)

func get_save_data() -> Dictionary:
	return _session_save_data.duplicate(true)

func store_runtime_snapshot(coins: int, discovered_fish_ids: Array[String]) -> void:
	"""Keeps an in-memory snapshot until persistent saves are implemented."""
	_session_save_data = {
		"coins": coins,
		"discovered_fish_ids": discovered_fish_ids.duplicate(),
	}

func reset_session_data() -> void:
	_session_save_data = DEFAULT_SAVE_DATA.duplicate(true)
