extends Node
class_name Player

# --- SIGNALS ---
signal health_modified(current, max)
signal mana_modified(current, max)
signal ability_added(ability)
signal ability_removed(ability)

# --- PLAYER CONTROLLER ---
@export var controller: PlayerController

# --- PLAYER PROPERTIES ---
@export var player_name: String = "Player"
@export var level: int = 1
@export var xp: int = 0
@export var ability_points: int = 0

@export var job: String = "Novice" # e.g. "Warrior", "Mage", "Rogue"

@export var max_health: int = 100
@export var current_health: int = 100
@export var max_mana: int = 50
@export var current_mana: int = 50

@export var stats := {
	"endurance": 1,
	"strength": 1,
	"intelligence": 1,
	"dexterity": 1,
	"perception": 1
}

@export var abilities: Array[Ability] = []
@export var inventory: Dictionary = {} # e.g. {"Health Potion": 5, "Mana Potion": 3}

func _ready() -> void:
	if controller:
		controller.name = "PlayerController"

func _process(delta: float) -> void:
	for ability in abilities:
		ability.process_ability(delta, self)
# --- GETTERS ---
func find_ability(ability_name: String) -> Ability:
	for ability in abilities:
		if ability.name == ability_name:
			return ability
	return null

func get_stat(stat_name: String) -> int:
	return stats.get(stat_name.to_lower(), 0)

func has_item(item_name: String, quantity: int = 1) -> bool:
	return inventory.get(item_name, 0) >= quantity

# --- SETTERS / MODIFIERS ---

func modify_health(amount: int) -> void:
	current_health = clamp(current_health + amount, 0, max_health)
	health_modified.emit(current_health, max_health)

func modify_mana(amount: int) -> void:
	current_mana = clamp(current_mana + amount, 0, max_mana)
	mana_modified.emit(current_mana, max_mana)

func add_ability(ability: Ability) -> void:
	if not find_ability(ability.name):
		abilities.append(ability)
		ability_added.emit(ability)
	else:
		push_warning("Ability '%s' already exists." % ability.name)

func remove_ability(ability_name: String) -> void:
	var ability = find_ability(ability_name)
	if ability:
		abilities.erase(ability)
		ability_removed.emit(ability)
	else:
		push_warning("Ability '%s' not found." % ability_name)