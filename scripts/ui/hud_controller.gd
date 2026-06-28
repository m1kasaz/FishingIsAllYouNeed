class_name HudController
extends CanvasLayer

@onready var _game_manager: Node = get_node("/root/GameManager")
@onready var _fish_database: Node = get_node("/root/FishDatabase")
@onready var top_safe: MarginContainer = $TopSafe
@onready var bottom_card: PanelContainer = $BottomSafe/BottomCard
@onready var coins_label: Label = $TopSafe/TopRow/LeftCard/MarginContainer/VBoxContainer/CoinsLabel
@onready var discovery_label: Label = $TopSafe/TopRow/LeftCard/MarginContainer/VBoxContainer/DiscoveryLabel
@onready var time_label: Label = $TopSafe/TopRow/RightCard/MarginContainer/VBoxContainer/TimeLabel
@onready var pause_label: Label = $TopSafe/TopRow/RightCard/MarginContainer/VBoxContainer/PauseLabel
@onready var prompt_label: Label = $BottomSafe/BottomCard/MarginContainer/VBoxContainer/PromptLabel
@onready var status_label: Label = $BottomSafe/BottomCard/MarginContainer/VBoxContainer/StatusLabel

func _ready() -> void:
	_game_manager.connect("coins_changed", _on_coins_changed)
	_game_manager.connect("discovery_progress_changed", _on_discovery_progress_changed)
	_on_coins_changed(int(_game_manager.call("get_coins")))
	_on_discovery_progress_changed(
		int(_game_manager.call("get_discovered_count")),
		int(_fish_database.call("get_fish_count"))
	)
	time_label.text = "时间：清晨"
	pause_label.text = "Esc：菜单"
	set_prompt("A / D 移动  ·  Space 抛竿", "湖面平静")
	set_top_visible(true)
	set_bottom_visible(true)

func set_prompt(prompt_text: String, state_text: String) -> void:
	prompt_label.text = prompt_text
	status_label.text = state_text

func set_top_visible(is_visible: bool) -> void:
	top_safe.visible = is_visible

func set_bottom_visible(is_visible: bool) -> void:
	bottom_card.visible = is_visible

func _on_coins_changed(coins: int) -> void:
	coins_label.text = "金币：%d" % coins

func _on_discovery_progress_changed(discovered_count: int, total_count: int) -> void:
	discovery_label.text = "图鉴：%d/%d" % [discovered_count, total_count]
