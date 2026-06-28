class_name FishingController
extends Node

const CAST_DURATION: float = 0.45

@onready var _fish_database: Node = get_node("/root/FishDatabase")
@onready var _audio_manager: Node = get_node("/root/AudioManager")
@onready var _game_manager: Node = get_node("/root/GameManager")
@onready var hud: HudController = $"../HUD"
@onready var result_panel: ResultPanel = $"../ResultLayer/ResultPanel"
@onready var bobber: FishingBobber = $"../LakeLayer/Bobber"
@onready var lake_layer: Node2D = $"../LakeLayer"
@onready var cast_timer: Timer = $CastTimer
@onready var bite_timer: Timer = $BiteTimer
@onready var bite_window_timer: Timer = $BiteWindowTimer
@onready var battle_intro_timer: Timer = $BattleIntroTimer
@onready var bar_battle: BattleBarController = $"../BattleLayer/BattleBar"
@onready var qte_battle: BattleQteController = $"../BattleLayer/BattleQTE"

var _state: FishingTypes.FishingState = FishingTypes.FishingState.IDLE
var _current_fish: Dictionary = {}
var _config: Dictionary = {}
var _boat_move_speed: float = 54.0
var _boat_min_x: float = 56.0
var _boat_max_x: float = 236.0

func _ready() -> void:
	_config = _fish_database.call("get_config") as Dictionary
	_boat_move_speed = float(_config.get("boat_move_speed", 54.0))
	_boat_min_x = float(_config.get("boat_min_x", 56.0))
	_boat_max_x = float(_config.get("boat_max_x", 236.0))
	cast_timer.wait_time = CAST_DURATION
	bite_window_timer.wait_time = float(_config.get("bite_window_seconds", 1.4))
	battle_intro_timer.wait_time = float(_config.get("battle_intro_seconds", 0.35))
	cast_timer.timeout.connect(_on_cast_timer_timeout)
	bite_timer.timeout.connect(_on_bite_timer_timeout)
	bite_window_timer.timeout.connect(_on_bite_window_timeout)
	battle_intro_timer.timeout.connect(_on_battle_intro_timeout)
	bar_battle.battle_completed.connect(_on_bar_battle_completed)
	qte_battle.battle_completed.connect(_on_qte_battle_completed)
	result_panel.confirmed.connect(_on_result_confirmed)
	_transition_to(FishingTypes.FishingState.IDLE)

func _process(delta: float) -> void:
	if _state == FishingTypes.FishingState.WAITING or _state == FishingTypes.FishingState.BITING:
		bobber.update_wait_feedback(delta)
	_handle_boat_movement(delta)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_pause") and _state != FishingTypes.FishingState.RESULT:
		hud.set_prompt("Pause later", "Easy")
		return

	if _state == FishingTypes.FishingState.IDLE and event.is_action_pressed("ui_cast"):
		start_cast()
		return

	if _state == FishingTypes.FishingState.BITING and _is_hook_input(event):
		_confirm_hook()

func start_cast() -> void:
	"""Begins a new fishing attempt from the idle state."""
	_current_fish = _fish_database.call("get_random_fish") as Dictionary
	if _current_fish.is_empty():
		hud.set_prompt("Missing fish data", "Error")
		return
	_transition_to(FishingTypes.FishingState.CASTING)
	_audio_manager.call("play_sfx", &"cast")
	cast_timer.start()

func _handle_boat_movement(delta: float) -> void:
	if _state != FishingTypes.FishingState.IDLE and _state != FishingTypes.FishingState.WAITING:
		return
	var direction: float = Input.get_action_strength("boat_right") - Input.get_action_strength("boat_left")
	if is_zero_approx(direction):
		return
	lake_layer.position.x = clampf(lake_layer.position.x + direction * _boat_move_speed * delta, _boat_min_x, _boat_max_x)

func _transition_to(state: FishingTypes.FishingState) -> void:
	_state = state
	bobber.set_state(state)
	match state:
		FishingTypes.FishingState.IDLE:
			hud.set_top_visible(true)
			hud.set_bottom_visible(true)
			hud.set_prompt("A / D 移动  ·  Space 抛竿", "湖面平静")
		FishingTypes.FishingState.CASTING:
			hud.set_top_visible(true)
			hud.set_bottom_visible(true)
			hud.set_prompt("鱼线抛出", "抛竿")
		FishingTypes.FishingState.WAITING:
			hud.set_top_visible(true)
			hud.set_bottom_visible(true)
			hud.set_prompt("观察浮标", "等待上钩")
		FishingTypes.FishingState.BITING:
			hud.set_top_visible(true)
			hud.set_bottom_visible(true)
			hud.set_prompt("Space / 点击收钩", "鱼咬钩了！")
		FishingTypes.FishingState.BATTLE_BAR:
			hud.set_top_visible(false)
			hud.set_bottom_visible(false)
			if qte_battle.visible:
				qte_battle.visible = false
		FishingTypes.FishingState.BATTLE_QTE:
			hud.set_top_visible(false)
			hud.set_bottom_visible(false)
			if bar_battle.visible:
				bar_battle.visible = false
		FishingTypes.FishingState.RESULT:
			hud.set_top_visible(false)
			hud.set_bottom_visible(false)

func _on_cast_timer_timeout() -> void:
	_transition_to(FishingTypes.FishingState.WAITING)
	_schedule_next_bite_roll()

func _schedule_next_bite_roll() -> void:
	bite_timer.wait_time = randf_range(0.35, 0.85)
	bite_timer.start()

func _on_bite_timer_timeout() -> void:
	if _state != FishingTypes.FishingState.WAITING:
		return

	var bite_chance: float = float(_fish_database.call("get_bite_chance_per_second", _current_fish)) * bite_timer.wait_time
	if randf() <= bite_chance:
		_trigger_bite()
	else:
		_schedule_next_bite_roll()

func _trigger_bite() -> void:
	_transition_to(FishingTypes.FishingState.BITING)
	bobber.trigger_bite_flash()
	_audio_manager.call("play_sfx", &"bite")
	bite_window_timer.start()

func _confirm_hook() -> void:
	if _state != FishingTypes.FishingState.BITING:
		return
	bite_window_timer.stop()
	hud.set_prompt("抓稳了", "战斗开始")
	battle_intro_timer.start()

func _on_bite_window_timeout() -> void:
	if _state != FishingTypes.FishingState.BITING:
		return
	_handle_battle_result(false)

func _on_battle_intro_timeout() -> void:
	if _state != FishingTypes.FishingState.BITING:
		return
	_start_battle()

func _start_battle() -> void:
	var battle_weights: Dictionary = _fish_database.call("get_battle_mode_weights") as Dictionary
	var battle_mode: FishingTypes.BattleMode = _pick_battle_mode(battle_weights)
	var battle_state: FishingTypes.FishingState = FishingTypes.battle_mode_to_state(battle_mode)
	_transition_to(battle_state)

	if battle_mode == FishingTypes.BattleMode.BAR:
		bar_battle.begin_battle(_current_fish, _config.get("battle_bar", {}) as Dictionary)
	else:
		qte_battle.begin_battle(_current_fish, _config.get("battle_qte", {}) as Dictionary)

func _pick_battle_mode(weights: Dictionary) -> FishingTypes.BattleMode:
	var bar_weight: int = int(weights.get("bar", 50))
	var qte_weight: int = int(weights.get("qte", 50))
	var total_weight: int = maxi(1, bar_weight + qte_weight)
	var roll: int = randi_range(1, total_weight)
	if roll <= bar_weight:
		return FishingTypes.BattleMode.BAR
	return FishingTypes.BattleMode.QTE

func _is_hook_input(event: InputEvent) -> bool:
	return event.is_action_pressed("ui_cast") or event.is_action_pressed("ui_reel")

func _on_bar_battle_completed(success: bool) -> void:
	_handle_battle_result(success)

func _on_qte_battle_completed(success: bool) -> void:
	_handle_battle_result(success)

func _handle_battle_result(success: bool) -> void:
	_transition_to(FishingTypes.FishingState.RESULT)
	bar_battle.visible = false
	qte_battle.visible = false
	var result_variant: Variant = _game_manager.call("record_catch", _current_fish) if success else _game_manager.call("record_failure")
	var result: Dictionary = result_variant as Dictionary
	result_panel.show_result(result, float(_config.get("result_confirm_delay_seconds", 0.45)))
	_audio_manager.call("play_sfx", &"result")

func _on_result_confirmed() -> void:
	_current_fish = {}
	_transition_to(FishingTypes.FishingState.IDLE)
