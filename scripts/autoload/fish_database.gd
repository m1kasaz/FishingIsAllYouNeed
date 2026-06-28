class_name FishDatabaseService
extends Node

const FISH_DATABASE_PATH: String = "res://data/fish_database.json"
const CONFIG_PATH: String = "res://data/config.json"
const REQUIRED_FIELDS: Array[String] = [
	"id",
	"name_zh",
	"name_en",
	"rarity",
	"min_weight",
	"max_weight",
	"base_value",
	"bite_rate_modifier",
	"battle_difficulty",
	"description",
	"category",
]

var _fish_definitions: Array[Dictionary] = []
var _config: Dictionary = {}
var _fish_by_id: Dictionary = {}
var _rarity_weights: Dictionary = {}

func _ready() -> void:
	_load_config()
	_load_database()

func get_config() -> Dictionary:
	return _config.duplicate(true)

func get_fish_count() -> int:
	return _fish_definitions.size()

func get_fish_definition(fish_id: String) -> Dictionary:
	if _fish_by_id.has(fish_id):
		return (_fish_by_id[fish_id] as Dictionary).duplicate(true)
	return {}

func get_random_fish() -> Dictionary:
	if _fish_definitions.is_empty():
		return {}

	var selected_rarity: String = _pick_weighted_value(_rarity_weights)
	var matching_fish: Array[Dictionary] = []

	for definition_variant: Variant in _fish_definitions:
		var definition: Dictionary = definition_variant as Dictionary
		if definition.get("rarity", "") == selected_rarity:
			matching_fish.append(definition)

	if matching_fish.is_empty():
		matching_fish = _fish_definitions

	var chosen_index: int = randi_range(0, matching_fish.size() - 1)
	var chosen_fish: Dictionary = matching_fish[chosen_index].duplicate(true)
	chosen_fish["weight"] = snappedf(randf_range(
		float(chosen_fish["min_weight"]),
		float(chosen_fish["max_weight"])
	), 0.01)
	chosen_fish["value"] = _calculate_value(chosen_fish)
	return chosen_fish

func get_bite_chance_per_second(fish_data: Dictionary) -> float:
	var base_chance: float = float(_config.get("bite_chance_per_second", 0.2))
	var modifier: float = float(fish_data.get("bite_rate_modifier", 1.0))
	return clampf(base_chance * modifier, 0.01, 0.95)

func get_battle_mode_weights() -> Dictionary:
	var mode_weights: Dictionary = _config.get("battle_mode_weights", {})
	return mode_weights.duplicate(true)

func _load_config() -> void:
	var loaded: Variant = _load_json_file(CONFIG_PATH)
	if loaded is Dictionary:
		_config = (loaded as Dictionary).duplicate(true)
		_rarity_weights = (_config.get("rarity_weights", {}) as Dictionary).duplicate(true)
		return
	push_error("FishDatabase failed to load config data from %s" % CONFIG_PATH)
	_config = {}
	_rarity_weights = {}

func _load_database() -> void:
	var loaded: Variant = _load_json_file(FISH_DATABASE_PATH)
	if loaded is not Array:
		push_error("FishDatabase expected an array in %s" % FISH_DATABASE_PATH)
		return

	_fish_definitions.clear()
	_fish_by_id.clear()

	for item_variant: Variant in loaded as Array:
		if item_variant is not Dictionary:
			push_error("FishDatabase found a non-dictionary fish record")
			continue
		var definition: Dictionary = item_variant as Dictionary
		if not _validate_definition(definition):
			continue
		var fish_id: String = str(definition["id"])
		var stored_definition: Dictionary = definition.duplicate(true)
		_fish_definitions.append(stored_definition)
		_fish_by_id[fish_id] = stored_definition

func _load_json_file(file_path: String) -> Variant:
	if not FileAccess.file_exists(file_path):
		push_error("Missing JSON file: %s" % file_path)
		return null

	var file: FileAccess = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		push_error("Could not open JSON file: %s" % file_path)
		return null

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed == null:
		push_error("Could not parse JSON file: %s" % file_path)
	return parsed

func _validate_definition(definition: Dictionary) -> bool:
	for field_name: String in REQUIRED_FIELDS:
		if not definition.has(field_name):
			push_error("FishDatabase missing required field '%s'" % field_name)
			return false

	if float(definition["min_weight"]) > float(definition["max_weight"]):
		push_error("FishDatabase has invalid weight range for %s" % definition.get("id", "unknown"))
		return false

	if definition["category"] is not Dictionary:
		push_error("FishDatabase category must be a dictionary for %s" % definition.get("id", "unknown"))
		return false

	return true

func _pick_weighted_value(weight_map: Dictionary) -> String:
	var total_weight: int = 0
	for key_variant: Variant in weight_map.keys():
		total_weight += int(weight_map[key_variant])

	if total_weight <= 0:
		return "common"

	var cursor: int = randi_range(1, total_weight)
	for key_variant: Variant in weight_map.keys():
		cursor -= int(weight_map[key_variant])
		if cursor <= 0:
			return str(key_variant)

	return str(weight_map.keys().front())

func _calculate_value(fish_data: Dictionary) -> int:
	var base_value: float = float(fish_data.get("base_value", 0))
	var min_weight: float = maxf(float(fish_data.get("min_weight", 0.1)), 0.1)
	var weight: float = maxf(float(fish_data.get("weight", min_weight)), 0.1)
	var rarity_bonus: float = 1.0 + float(fish_data.get("battle_difficulty", 0.0))
	var weight_ratio: float = weight / min_weight
	return maxi(1, int(round(base_value * weight_ratio * rarity_bonus)))
