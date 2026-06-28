class_name AudioManagerService
extends Node

signal sfx_requested(name: StringName)
signal bgm_requested(name: StringName)

var _current_bgm: StringName = &""

func play_sfx(name: StringName) -> void:
	"""Requests a sound effect by semantic name."""
	sfx_requested.emit(name)

func play_bgm(name: StringName) -> void:
	"""Stores and emits the requested BGM cue."""
	_current_bgm = name
	bgm_requested.emit(name)

func stop_bgm() -> void:
	"""Clears the active BGM cue."""
	_current_bgm = &""
	bgm_requested.emit(&"")

func get_current_bgm() -> StringName:
	return _current_bgm
