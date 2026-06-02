extends Control

@onready var share_button = $ShareButton
@onready var time_label = $TimeLabel

func _ready() -> void:
	# Request experience data and stats
	CouchBridge.request_experience_data()
	CouchBridge.request_session_stats()
	
	# Wait for the responses
	var exp_data = await CouchBridge.experience_data_received
	var stats_data = await CouchBridge.session_stats_received
	
	# Process experience data (share URL)
	if exp_data.success and exp_data.payload.experienceUrl != null:
		share_button.visible = true
		share_button.pressed.connect(_on_share_pressed.bind(exp_data.payload.experienceUrl))
	else:
		share_button.visible = false
	
	# Process session stats (play time)
	if stats_data.success:
		var total_ms = stats_data.payload.cumulativeGameplayTimeMs
		var total_sec = total_ms / 1000
		var minutes = floor(total_sec / 60)
		var seconds = floor(total_sec % 60)
		time_label.text = "completed in %02d:%02d" % [minutes, seconds]
	else:
		time_label.text = "completed in --:--"

func _on_share_pressed(url: String) -> void:
	OS.shell_open(url)
