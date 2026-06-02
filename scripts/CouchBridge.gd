extends Node

signal experience_data_received(data: Dictionary)
signal session_stats_received(data: Dictionary)

var _sdk = null


func _ready():
	await get_tree().process_frame
	_find_sdk()

func _find_sdk():
	if OS.has_feature("web"):
		_sdk = JavaScriptBridge.get_interface("CouchGames")
		
		if _sdk:
			print("SDK CouchGames success!")
		else:
			# try again
			await get_tree().create_timer(1.0).timeout
			_find_sdk()

# --- CALLS ---

func start_gameplay():
	if _sdk:
		_sdk.gameplayStart()

func stop_gameplay():
	if _sdk:
		_sdk.gameplayEnd()

func complete_gameplay():
	if _sdk:
		_sdk.gameplayComplete()

# Called from EndScene to request data
func request_experience_data() -> void:
	if OS.get_name() != "HTML5":
		var dummy = {
			"success": true,
			"payload": {
				"date": null,
				"files": [],
				"type": "regular",
				"experienceIndex": 0,
				"experienceId": "local",
				"experienceUrl": null
			}
		}
		experience_data_received.emit(dummy)
		return
	
	# Create a JavaScript callback that will receive the promise result
	var callback = JavaScriptBridge.create_callback(_on_experience_data_callback)
	# Execute async JS code that calls the callback when done
	JavaScriptBridge.eval("""
        window.CouchGames.getExperienceData().then(result => {
            // Call the Godot callback with the JSON string
            %s(JSON.stringify(result));
        }).catch(err => {
            %s(JSON.stringify({ success: false, message: err.message }));
        });
	""" % [callback.get_js_object(), callback.get_js_object()])

func _on_experience_data_callback(args: Array) -> void:
	var json_str = args[0]
	var data = JSON.parse_string(json_str)
	experience_data_received.emit(data)

func request_session_stats() -> void:
	if OS.get_name() != "HTML5":
		var dummy = {
			"success": true,
			"payload": {
				"cumulativeGameplayTimeMs": 0,
				"gameplayCompleted": false
			}
		}
		session_stats_received.emit(dummy)
		return
	
	var callback = JavaScriptBridge.create_callback(_on_session_stats_callback)
	JavaScriptBridge.eval("""
        window.CouchGames.getSessionStats().then(result => {
            %s(JSON.stringify(result));
        }).catch(err => {
            %s(JSON.stringify({ success: false, message: err.message }));
        });
	""" % [callback.get_js_object(), callback.get_js_object()])

func _on_session_stats_callback(args: Array) -> void:
	var json_str = args[0]
	var data = JSON.parse_string(json_str)
	session_stats_received.emit(data)
