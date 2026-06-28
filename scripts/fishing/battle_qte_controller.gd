class_name BattleQteController
extends Control

signal battle_completed(success: bool)

@onready var dial: Control = $CenterSafe/PanelContainer/MarginContainer/VBoxContainer/Dial
@onready var ring: ColorRect = $CenterSafe/PanelContainer/MarginContainer/VBoxContainer/Dial/Ring
@onready var pointer: ColorRect = $CenterSafe/PanelContainer/MarginContainer/VBoxContainer/Dial/Pointer
@onready var success_zone: ColorRect = $CenterSafe/PanelContainer/MarginContainer/VBoxContainer/Dial/SuccessZone
@onready var great_zone: ColorRect = $CenterSafe/PanelContainer/MarginContainer/VBoxContainer/Dial/GreatZone
@onready var center_dot: ColorRect = $CenterSafe/PanelContainer/MarginContainer/VBoxContainer/Dial/CenterDot
@onready var progress_label: Label = $CenterSafe/PanelContainer/MarginContainer/VBoxContainer/ProgressLabel
@onready var prompt_label: Label = $CenterSafe/PanelContainer/MarginContainer/VBoxContainer/PromptLabel
@onready var feedback_label: Label = $CenterSafe/PanelContainer/MarginContainer/VBoxContainer/FeedbackLabel

var _pointer_angle: float = 0.0
var _pointer_speed: float = 2.0
var _success_zone_size: float = 0.2
var _great_zone_size: float = 0.08
var _progress_score: int = 0
var _target_score: int = 4
var _fail_floor: int = 0
var _battle_active: bool = false
var _elapsed_seconds: float = 0.0
var _min_duration_seconds: float = 1.4
var _feedback_timer: float = 0.0

func _ready() -> void:
	visible = false
	set_process(false)

func begin_battle(fish_data: Dictionary, config: Dictionary) -> void:
	"""Starts the QTE battle using fish difficulty and config scaling."""
	visible = true
	_battle_active = true
	set_process(true)

	var difficulty: float = float(fish_data.get("battle_difficulty", 0.3))
	_elapsed_seconds = 0.0
	_feedback_timer = 0.0
	_min_duration_seconds = float(config.get("min_duration_seconds", 2.2))
	_pointer_angle = 0.0
	_progress_score = 1
	_pointer_speed = float(config.get("pointer_speed", 1.55)) + difficulty * 1.2
	_success_zone_size = clampf(float(config.get("success_zone_size", 0.24)) - difficulty * 0.05, 0.16, 0.28)
	_great_zone_size = clampf(float(config.get("great_zone_size", 0.09)) - difficulty * 0.02, 0.04, 0.1)
	_target_score = maxi(4, int(round(float(config.get("success_target", 5)) + difficulty * 1.5)))
	_fail_floor = int(config.get("fail_floor", 0))
	prompt_label.text = "指针进入绿色区时按 Space"
	feedback_label.text = "等待时机"
	_update_visuals()

func _process(delta: float) -> void:
	if not _battle_active:
		return
	_elapsed_seconds += delta
	_pointer_angle = wrapf(_pointer_angle + _pointer_speed * delta, 0.0, TAU)
	if _feedback_timer > 0.0:
		_feedback_timer = maxf(0.0, _feedback_timer - delta)
		if _feedback_timer == 0.0:
			feedback_label.text = "等待时机"
	_update_visuals()
	if Input.is_action_just_pressed("ui_cast"):
		_resolve_input()

func _resolve_input() -> void:
	var normalized_angle: float = _pointer_angle / TAU
	var zone_center: float = 0.72
	var distance: float = absf(_wrapped_distance(normalized_angle, zone_center))

	if distance <= _great_zone_size * 0.5:
		_progress_score += 2
		feedback_label.text = "完美"
	elif distance <= _success_zone_size * 0.5:
		_progress_score += 1
		feedback_label.text = "成功"
	else:
		_progress_score -= 1
		feedback_label.text = "失误"

	_feedback_timer = 0.4
	_progress_score = maxi(_fail_floor, _progress_score)
	_check_battle_outcome()
	_update_visuals()

func _check_battle_outcome() -> void:
	if _elapsed_seconds < _min_duration_seconds:
		return
	if _progress_score >= _target_score:
		_finish_battle(true)
	elif _progress_score <= _fail_floor:
		_finish_battle(false)

func _update_visuals() -> void:
	var dial_width: float = maxf(dial.size.x, 180.0)
	var center_x: float = dial_width * 0.5
	var center_y: float = 40.0
	var radius: float = 34.0
	var zone_center_angle: float = TAU * 0.72 - PI * 0.5
	var pointer_angle: float = _pointer_angle - PI * 0.5
	var zone_position: Vector2 = Vector2(center_x, center_y) + Vector2(cos(zone_center_angle), sin(zone_center_angle)) * radius

	ring.position = Vector2(center_x - ring.size.x * 0.5, center_y - ring.size.y * 0.5)
	success_zone.position = zone_position - Vector2(success_zone.size.x * 0.5, success_zone.size.y * 0.5)
	great_zone.position = zone_position - Vector2(great_zone.size.x * 0.5, great_zone.size.y * 0.5)
	success_zone.rotation = zone_center_angle + PI * 0.5
	great_zone.rotation = zone_center_angle + PI * 0.5
	pointer.position = Vector2(center_x - pointer.size.x * 0.5, center_y - pointer.size.y + 6.0)
	pointer.rotation = pointer_angle
	center_dot.position = Vector2(center_x - center_dot.size.x * 0.5, center_y - center_dot.size.y * 0.5)
	progress_label.text = "%d / %d" % [_progress_score, _target_score]

func _finish_battle(success: bool) -> void:
	_battle_active = false
	visible = false
	set_process(false)
	battle_completed.emit(success)

func _wrapped_distance(a: float, b: float) -> float:
	var distance: float = fmod(a - b + 1.5, 1.0) - 0.5
	return distance
