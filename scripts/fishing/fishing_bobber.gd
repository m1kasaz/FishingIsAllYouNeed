class_name FishingBobber
extends Control

@onready var indicator: ColorRect = $Indicator
@onready var splash: ColorRect = $Splash
@onready var pulse_ring: ColorRect = $PulseRing
@onready var exclamation_label: Label = $ExclamationLabel

var _base_position: Vector2 = Vector2.ZERO
var _wait_wobble_time: float = 0.0
var _bite_flash_time: float = 0.0

func _ready() -> void:
	_base_position = position
	set_state(FishingTypes.FishingState.IDLE)

func set_state(state: FishingTypes.FishingState) -> void:
	"""Updates the bobber feedback to reflect the fishing state."""
	position = _base_position
	_bite_flash_time = 0.0
	indicator.color = Color("f6bd60")
	splash.visible = false
	pulse_ring.visible = false
	exclamation_label.visible = false

	match state:
		FishingTypes.FishingState.IDLE:
			visible = false
		FishingTypes.FishingState.CASTING:
			visible = true
			indicator.color = Color("f4a261")
		FishingTypes.FishingState.WAITING:
			visible = true
			indicator.color = Color("84d2f6")
			pulse_ring.visible = true
		FishingTypes.FishingState.BITING:
			visible = true
			indicator.color = Color("f94144")
			splash.visible = true
			pulse_ring.visible = true
			exclamation_label.visible = true
		_:
			visible = false

func update_wait_feedback(delta: float) -> void:
	if not visible:
		return
	_wait_wobble_time += delta
	position = _base_position + Vector2(sin(_wait_wobble_time * 2.2) * 4.0, cos(_wait_wobble_time * 3.0) * 2.0)
	if pulse_ring.visible:
		var ring_scale: float = 1.0 + 0.08 * sin(_wait_wobble_time * 4.0)
		pulse_ring.scale = Vector2(ring_scale, 1.0)
	if splash.visible:
		_bite_flash_time += delta
		position = _base_position + Vector2(sin(_bite_flash_time * 16.0) * 2.0, 7.0 + cos(_bite_flash_time * 20.0) * 1.5)

func trigger_bite_flash() -> void:
	indicator.color = Color("f94144")
	splash.visible = true
	pulse_ring.visible = true
	exclamation_label.visible = true
	position = _base_position + Vector2(0.0, 8.0)
