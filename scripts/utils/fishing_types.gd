class_name FishingTypes
extends RefCounted

const RARITY_ORDER: Array[String] = ["common", "rare", "epic", "legendary"]

enum FishingState {
	IDLE,
	CASTING,
	WAITING,
	BITING,
	BATTLE_BAR,
	BATTLE_QTE,
	RESULT,
}

enum BattleMode {
	BAR,
	QTE,
}

static func battle_mode_to_state(mode: BattleMode) -> FishingState:
	if mode == BattleMode.BAR:
		return FishingState.BATTLE_BAR
	return FishingState.BATTLE_QTE

static func battle_mode_name(mode: BattleMode) -> String:
	if mode == BattleMode.BAR:
		return "bar"
	return "qte"

static func state_name(state: FishingState) -> String:
	return FishingState.keys()[state].to_lower()
