"""
Ability System - Base class for all player abilities

Override these methods in child classes:
- _ability_logic(delta, player) - Core ability behavior
- _on_ability_unlocked() - Custom unlock effects
- _on_ability_upgraded() - Custom upgrade effects  
- _on_ability_activated() - Animation/sound on activation
"""

extends Node
class_name Ability

# --- SIGNALS ---
signal ability_unlocked
signal ability_upgraded
signal ability_failed_to_unlock
signal ability_failed_to_upgrade
signal ability_used

# --- Core Ability Properties ---

var is_unlocked: bool = false
var ability_level: int = 0
var ability_name: String = "Unnamed Ability"
var description: String = "No description available."
var is_passive: bool = false
var category: String = "General" # e.g. "Combat", "Movement", "Buff", "Debuff"
var tags: Array = [] # e.g. ["Fire", "Physical", "Healing", "AOE", "Single Target"]

@export var max_ability_level: int = 5
@export var mana_cost: int = 0

var cooldown_time: float = 0.0
var cooldown_timer: float = 0.0

# Pre-Requisites
@export var requirements: Array[AbilityRequirement] = []

# --- Unlock / Upgrade ---

func can_unlock(player: Node) -> bool: # Checks ability pre-requisites
	for req in requirements:
		if not req.is_met(player):
			return false
	return true

func unlock(player: Node) -> void:
	if not can_unlock(player):
		ability_failed_to_unlock.emit()
		return
	is_unlocked = true
	ability_level = 1
	ability_unlocked.emit()
	_on_ability_unlocked()

func upgrade() -> void:
	if not is_unlocked or ability_level >= max_ability_level:
		ability_failed_to_upgrade.emit()
		return
	ability_level += 1
	ability_upgraded.emit()
	_on_ability_upgraded()

func can_use(player: Node) -> bool:
	return is_unlocked and cooldown_timer <= 0.0 and player.current_mana >= mana_cost

func activate(player: Node) -> void:
	if not can_use(player):
		return
	player.current_mana -= mana_cost
	if cooldown_time > 0.0:
		cooldown_timer = cooldown_time
	ability_used.emit()
	_on_ability_activated()

func get_requirements_description() -> String:
	if requirements.is_empty():
		return "No requirements"
	var req_descriptions: Array[String] = []
	for req in requirements:
		req_descriptions.append(req.get_description())
	return ", ".join(req_descriptions)

# --- Called each frame from Player.gd ---

func process_ability(delta: float, player: Node) -> void:
	if cooldown_timer > 0.0:
		cooldown_timer = max(cooldown_timer - delta, 0.0)

	if is_passive or can_use(player):
		_ability_logic(delta, player)

# -- Methods to be overridden by child classes ---
func _ability_logic(delta: float, player: Node) -> void:
	# Override in child classes to implement ability-specific logic
	pass

func _on_ability_unlocked() -> void:
	# Override in child classes for custom unlock behavior
	pass

func _on_ability_upgraded() -> void:
	# Override in child classes for custom upgrade behavior
	pass

func _on_ability_activated() -> void:
	# Override in child classes for custom activation behavior like playing animation or sound
	pass