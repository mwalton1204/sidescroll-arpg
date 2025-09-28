extends Resource
class_name AbilityRequirement
@export_category("Ability Requirement")

# --- Requirement Properties ---
enum RequirementType { LEVEL, ABILITY, JOB, STAT, ITEM }

@export var type: RequirementType = RequirementType.LEVEL
@export var value: int = 1
@export var string_value: String = "" ## e.g. ability name, job name, stat name, item name

func is_met(player: Node) -> bool:
    match type:
        RequirementType.LEVEL:
            return player.level >= value
        RequirementType.ABILITY:
            var ability = player.find_ability(string_value)
            if ability == null:
                return false
            return ability.ability_level >= value
        RequirementType.JOB:
            return player.job == string_value
        RequirementType.STAT:
            return player.get_stat(string_value) >= value
        RequirementType.ITEM:
            return player.has_item(string_value, value)
    return false

func get_description() -> String:
    match type:
        RequirementType.LEVEL:
            return "Requires Level %d" % value
        RequirementType.STAT:
            return "Requires %s ≥ %d" % [string_value.capitalize(), value]
        RequirementType.JOB:
            return "Requires Job: %s" % string_value
        RequirementType.ABILITY:
            return "Requires %s Lv. %d" % [string_value, value]
        RequirementType.ITEM:
            return "Requires %d × %s" % [value, string_value]
    return "Unknown requirement"