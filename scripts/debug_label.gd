extends Label

var player_node: Player

func _ready() -> void:
	# Find player by group
	var players = get_tree().get_nodes_in_group("players")
	if players.size() > 0:
		player_node = players[0] as Player
	
	if not player_node:
		text = "No player found!"
		push_warning("Debug label couldn't find player in 'player' group")
		print("Nodes in 'player' group: ", get_tree().get_nodes_in_group("player"))

func _process(_delta: float) -> void:
	if player_node and player_node.controller:
		var ctrl = player_node.controller
		
		text = "=== PLAYER INFO ===\n"
		text += "Level: %d | XP: %d\n" % [player_node.level, player_node.xp]
		text += "Job: %s\n" % player_node.job
		text += "Health: %d/%d\n" % [player_node.current_health, player_node.max_health]
		text += "Mana: %d/%d\n" % [player_node.current_mana, player_node.max_mana]
		
		text += "\n=== CONTROLLER ===\n"
		var facing_arrow = "Right" if ctrl.facing_direction > 0 else "Left"
		text += "Facing: %s (%.0f)\n" % [facing_arrow, ctrl.facing_direction]
		text += "Speed: %.1f px/s\n" % ctrl.speed
		text += "Jump Height: %.1f px\n" % ctrl.jump_height
		var floor_status = "Yes" if ctrl.is_on_floor() else "No"
		text += "On Floor: %s\n" % floor_status
		text += "Velocity: (%.1f, %.1f)\n" % [ctrl.velocity.x, ctrl.velocity.y]
		text += "Speed Mult: %.2f\n" % ctrl.speed_multiplier
		text += "Coyote Timer: %.3f\n" % ctrl.coyote_timer
		text += "Jump Buffer: %.3f\n" % ctrl.jump_buffer_timer
		
	elif player_node:
		text = "Player found but no controller!"
	else:
		text = "No player found in 'player' group"
