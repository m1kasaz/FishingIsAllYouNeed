class_name BattleBarController
extends Control

signal battle_completed(success: bool)

@onready var progress_bar: ProgressBar = $CenterSafe/PanelContainer/MarginContainer/VBoxContainer/CatchProgressBar
@onready var playfield: ColorRect = $CenterSafe/PanelContainer/MarginContainer/VBoxContainer/Playfield
@onready var capture_area: ColorRect = $CenterSafe/PanelContainer/MarginContainer/VBoxContainer/Playfield/CaptureArea
@onready var fish_marker: ColorRect = $CenterSafe/PanelContainer/MarginContainer/VBoxContainer/Playfield/FishMarker
@onready var prompt_label: Label = $CenterSafe/PanelContainer/MarginContainer/VBoxContainer/PromptLabel
@onready var status_label: Label = $CenterSafe/PanelContainer/MarginContainer/VBoxContainer/StatusLabel

var _capture_progress: float = 0.35
var _capture_area_center: float = 0.5
var _fish_position: float = 0.5
var _fish_velocity: float = 0.0
var _fill_speed: float = 0.5
var _drain_speed: float = 0.4
var _lift_speed: float = 0.7
var _fall_speed: float = 0.5
var _fish_speed: float = 0.35
var _capture_height: float = 0.18
var _battle_active: bool = false
var _elapsed_seconds: float = 0.0
var _min_duration_seconds: float = 1.4

func _ready() -> void:
	visible = false
	set_process(false)

func begin_battle(fish_data: Dictionary, config: Dictionary) -> void:
	"""Starts the bar battle using fish difficulty and global config."""
	visible = true
	_battle_active = true
	set_process(true)

	var difficulty: float = float(fish_data.get("battle_difficulty", 0.3))
	_elapsed_seconds = 0.0
	_min_duration_seconds = float(config.get("min_duration_seconds", 2.4))
	_capture_progress = 0.5
	_capture_area_center = 0.5
	_fish_position = 0.5
	_fish_velocity = 0.0
	_fill_speed = float(config.get("fill_speed", 0.5)) + difficulty * 0.06
	_drain_speed = float(config.get("drain_speed", 0.25)) + difficulty * 0.12
	_lift_speed = float(config.get("capture_area_lift_speed", 0.86)) - difficulty * 0.05
	_fall_speed = float(config.get("capture_area_fall_speed", 0.42)) + difficulty * 0.08
	_fish_speed = float(config.get("fish_base_speed", 0.32)) + difficulty * 0.25
	_capture_height = clampf(float(config.get("capture_area_height", 0.24)) - difficulty * 0.05, 0.12, 0.28)
	prompt_label.text = "Hold mouse"
	status_label.text = "Keep fish in zone"
	_update_visuals()

func _process(delta: float) -> void:
	if not _battle_active:
		return
	_elapsed_seconds += delta
	_update_capture_area(delta)
	_update_fish(delta)
	_update_progress(delta)
	_update_status_text()
	_update_visuals()
	_check_battle_outcome()

func _update_capture_area(delta: float) -> void:
	var delta_amount: float = _lift_speed * delta if Input.is_action_pressed("ui_reel") else -_fall_speed * delta
	_capture_area_center = clampf(_capture_area_center + delta_amount, _capture_height * 0.5, 1.0 - _capture_height * 0.5)

func _update_fish(delta: float) -> void:
	var drift: float = randf_range(-1.0, 1.0) * _fish_speed * delta
	_fish_velocity = clampf(_fish_velocity + drift, -_fish_speed, _fish_speed)
	_fish_position = clampf(_fish_position + _fish_velocity * delta * 1.7, 0.08, 0.92)
	if _fish_position <= 0.08 or _fish_position >= 0.92:
		_fish_velocity *= -0.5

func _update_progress(delta: float) -> void:
	var capture_top: float = _capture_area_center - _capture_height * 0.5
	var capture_bottom: float = _capture_area_center + _capture_height * 0.5
	var delta_amount: float = _fill_speed * delta if _fish_position >= capture_top and _fish_position <= capture_bottom else -_drain_speed * delta
	_capture_progress = clampf(_capture_progress + delta_amount, 0.0, 1.0)

func _update_status_text() -> void:
	var capture_top: float = _capture_area_center - _capture_height * 0.5
	var capture_bottom: float = _capture_area_center + _capture_height * 0.5
	status_label.text = "Good" if _fish_position >= capture_top and _fish_position <= capture_bottom else "Recover"

func _check_battle_outcome() -> void:
	if _elapsed_seconds < _min_duration_seconds:
		return
	if _capture_progress >= 1.0:
		_finish_battle(true)
	elif _capture_progress <= 0.0:
		_finish_battle(false)

func _update_visuals() -> void:
	var playfield_width: float = playfield.size.x
	var center_x: float = _capture_area_center * playfield_width
	capture_area.position.x = center_x - (_capture_height * playfield_width * 0.5)
	capture_area.size.x = _capture_height * playfield_width
	fish_marker.position.x = _fish_position * playfield_width - fish_marker.size.x * 0.5
	progress_bar.value = _capture_progress * 100.0

func _finish_battle(success: bool) -> void:
	_battle_active = false
	visible = false
	set_process(false)
	battle_completed.emit(success)
