class_name ResultPanel
extends Control

signal confirmed()

@onready var title_label: Label = $Overlay/CenterSafe/PanelContainer/MarginContainer/VBoxContainer/Header/TitleLabel
@onready var fish_name_label: Label = $Overlay/CenterSafe/PanelContainer/MarginContainer/VBoxContainer/Header/FishNameLabel
@onready var rarity_label: Label = $Overlay/CenterSafe/PanelContainer/MarginContainer/VBoxContainer/InfoCard/MarginContainer/VBoxContainer/RarityLabel
@onready var summary_label: Label = $Overlay/CenterSafe/PanelContainer/MarginContainer/VBoxContainer/InfoCard/MarginContainer/VBoxContainer/SummaryLabel
@onready var detail_label: Label = $Overlay/CenterSafe/PanelContainer/MarginContainer/VBoxContainer/InfoCard/MarginContainer/VBoxContainer/DetailLabel
@onready var prompt_label: Label = $Overlay/CenterSafe/PanelContainer/MarginContainer/VBoxContainer/Footer/PromptLabel
@onready var continue_button: Button = $Overlay/CenterSafe/PanelContainer/MarginContainer/VBoxContainer/Footer/ContinueButton

var _is_visible: bool = false
var _confirm_delay_remaining: float = 0.0

func _ready() -> void:
	visible = false
	set_process(false)
	set_process_unhandled_input(false)
	continue_button.pressed.connect(_on_continue_button_pressed)
	continue_button.disabled = true

func show_result(result: Dictionary, confirm_delay_seconds: float = 0.45) -> void:
	"""Displays either a success card or a failure summary."""
	visible = true
	_is_visible = true
	_confirm_delay_remaining = confirm_delay_seconds
	continue_button.disabled = true
	set_process(true)
	set_process_unhandled_input(true)

	if bool(result.get("success", false)):
		var fish: Dictionary = result.get("fish", {}) as Dictionary
		var category: Dictionary = fish.get("category", {}) as Dictionary
		title_label.text = "本次收获"
		fish_name_label.text = str(fish.get("name_zh", "???"))
		rarity_label.text = "%s · %s" % [
			str(fish.get("rarity", "common")).capitalize(),
			"新发现" if bool(result.get("is_new", false)) else "已记录",
		]
		summary_label.text = "%.1fkg · %d 金币" % [
			float(fish.get("weight", 0.0)),
			int(result.get("coins_awarded", 0)),
		]
		detail_label.text = "%s\n%s / %s / %s" % [
			str(fish.get("description", "")),
			str(category.get("order", "未知目")),
			str(category.get("family", "未知科")),
			str(category.get("genus", "未知属")),
		]
	else:
		title_label.text = "鱼儿逃走了"
		fish_name_label.text = "只留下涟漪"
		rarity_label.text = "本次失败"
		summary_label.text = "未获得金币"
		detail_label.text = str(result.get("message", "再试一次，湖里还有新的收获。"))

	prompt_label.text = "稍等..."
	continue_button.text = "继续"

func _process(delta: float) -> void:
	if not _is_visible:
		return
	if _confirm_delay_remaining <= 0.0:
		set_process(false)
		continue_button.disabled = false
		prompt_label.text = "回车 / Space / Esc / 点击继续"
		return
	_confirm_delay_remaining = maxf(0.0, _confirm_delay_remaining - delta)

func _unhandled_input(event: InputEvent) -> void:
	if not _is_visible or _confirm_delay_remaining > 0.0:
		return
	if event.is_action_pressed("ui_confirm") or event.is_action_pressed("ui_cast") or event.is_action_pressed("ui_cancel"):
		_confirm_and_close()
		return
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
			_confirm_and_close()

func hide_result() -> void:
	visible = false
	_is_visible = false
	_confirm_delay_remaining = 0.0
	continue_button.disabled = true
	set_process(false)
	set_process_unhandled_input(false)

func _on_continue_button_pressed() -> void:
	if _confirm_delay_remaining > 0.0:
		return
	_confirm_and_close()

func _confirm_and_close() -> void:
	hide_result()
	confirmed.emit()
