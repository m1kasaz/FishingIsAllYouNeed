class_name GameManagerService
extends Node

signal session_reset()
signal catch_recorded(result: Dictionary)
signal coins_changed(coins: int)
signal discovery_progress_changed(discovered_count: int, total_count: int)

var _coins: int = 0
var _discovered_fish_ids: Array[String] = []
var _last_result: Dictionary = {}

func _ready() -> void:
	reset_session()

func reset_session() -> void:
	_coins = 0
	_discovered_fish_ids.clear()
	_last_result = {}
	var save_manager: Node = get_node("/root/SaveManager")
	var fish_database: Node = get_node("/root/FishDatabase")
	save_manager.call("reset_session_data")
	session_reset.emit()
	coins_changed.emit(_coins)
	discovery_progress_changed.emit(_discovered_fish_ids.size(), int(fish_database.call("get_fish_count")))

func build_failure_result() -> Dictionary:
	return {
		"success": false,
		"title": "It got away...",
		"message": "The fish slipped back into the lake before you could secure it.",
		"coins_awarded": 0,
		"is_new": false,
	}

func record_catch(fish_data: Dictionary) -> Dictionary:
	"""Updates session progress and returns the UI-facing result payload."""
	var fish_id: String = str(fish_data.get("id", ""))
	var is_new: bool = not _discovered_fish_ids.has(fish_id)
	if is_new and fish_id != "":
		_discovered_fish_ids.append(fish_id)

	var coins_awarded: int = int(fish_data.get("value", 0))
	_coins += coins_awarded

	var result: Dictionary = {
		"success": true,
		"fish": fish_data.duplicate(true),
		"coins_awarded": coins_awarded,
		"is_new": is_new,
	}
	_last_result = result.duplicate(true)

	var save_manager: Node = get_node("/root/SaveManager")
	var fish_database: Node = get_node("/root/FishDatabase")
	save_manager.call("store_runtime_snapshot", _coins, _discovered_fish_ids)
	catch_recorded.emit(_last_result.duplicate(true))
	coins_changed.emit(_coins)
	discovery_progress_changed.emit(_discovered_fish_ids.size(), int(fish_database.call("get_fish_count")))
	return _last_result.duplicate(true)

func record_failure() -> Dictionary:
	_last_result = build_failure_result()
	catch_recorded.emit(_last_result.duplicate(true))
	return _last_result.duplicate(true)

func get_coins() -> int:
	return _coins

func get_last_result() -> Dictionary:
	return _last_result.duplicate(true)

func get_discovered_count() -> int:
	return _discovered_fish_ids.size()

func has_discovered_fish(fish_id: String) -> bool:
	return _discovered_fish_ids.has(fish_id)
