extends Node

# Signal to start play from READY state
signal start_play

#signal when pause is pressed, whether already paused or not
signal pause(player_id)

# Signal when player scores a point, includes player ID
signal score_updated(player_id)

# Signal to lock or unlock player input
signal lock_player(locked)

# Function to emit the start_play signal
func emit_start_play() -> void:
	emit_signal("start_play")
	
#function to emit the pause signal
func emit_pause(player_id: int) -> void:
	emit_signal("pause", player_id)
	
# Function to emit the score_updated signal
func emit_score_updated(player_id: int) -> void:
	emit_signal("score_updated", player_id)

# Function to emit the lock_player signal
func emit_lock_player(locked: bool) -> void:
	emit_signal("lock_player", locked)
